local CASE = "vulcanus-pneumatic-compressor"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local RECIPE = "nullius-compressed-nitrogen"
local NITROGEN = "nullius-nitrogen"
local COMPRESSED_NITROGEN = "nullius-compressed-nitrogen"
local FUEL = "nullius-compressed-volcanic-gas"
local TERMINAL_TICK = 220

local assertions = 0
local failures = {}
local observations = {}

local function check(condition, message)
  assertions = assertions + 1
  if not condition then failures[#failures + 1] = message end
  return condition
end

local function close(actual, expected)
  return math.abs(actual - expected) < 0.001
end

local function finish()
  local result = {
    schema = 1,
    case = CASE,
    status = (#failures == 0) and "pass" or "fail",
    factorio_version = script.active_mods.base,
    tick = game.tick,
    assertions = assertions,
    failure_count = #failures,
    failures = failures,
    observations = observations,
  }
  helpers.write_file(RESULT, helpers.table_to_json(result), false)
  if #failures > 0 then error(helpers.table_to_json(result)) end
end

local function research_closure(technology, visited)
  if visited[technology.name] then return end
  visited[technology.name] = true
  for _, prerequisite in pairs(technology.prerequisites) do
    research_closure(prerequisite, visited)
  end
  technology.researched = true
end

local function entity_at(surface, name, position)
  local entities = surface.find_entities_filtered{
    name = name,
    position = position,
    radius = 0.1,
  }
  return entities[1]
end

local function transition(surface, entity, expected)
  local name = entity.name
  local position = entity.position
  check(remote.interfaces["nullius-test-transitions"] ~= nil,
    "transition test interface is missing")
  if not remote.interfaces["nullius-test-transitions"] then return nil end
  check(remote.call("nullius-test-transitions", "execute", entity),
    name .. " had no registered transition")
  local replacement = entity_at(surface, expected, position)
  check(replacement ~= nil,
    name .. " did not transition to " .. expected)
  return replacement
end

local function fluid_box(machine, name, role)
  if role == "fuel" then
    for index = 1, #machine.fluidbox do
      if not machine.fluidbox.get_filter(index) then return index end
    end
  end
  for index = 1, #machine.fluidbox do
    local filter = machine.fluidbox.get_filter(index)
    local prototype = machine.fluidbox.get_prototype(index)
    local production_type = prototype and prototype.production_type or "none"
    if filter and filter.name == name then
      if role == "input" and production_type ~= "output" then return index end
      if role == "output" and production_type ~= "input" then return index end
    end
  end
  return nil
end

local function set_fluid(machine, name, amount, role)
  local index = fluid_box(machine, name, role)
  check(index ~= nil,
    machine.name .. " has no " .. role .. " box for " .. name)
  if not index then return nil end
  machine.fluidbox[index] = {
    name = name,
    amount = amount,
    temperature = prototypes.fluid[name].default_temperature,
  }
  local stored = machine.fluidbox[index]
  check(stored and close(stored.amount, amount),
    machine.name .. " did not accept " .. amount .. " " .. name)
  return index
end

local function validate_tier(surface, tier, position)
  local priority = "nullius-priority-compressor-" .. tier
  local surge = "nullius-surge-compressor-" .. tier
  local pneumatic_priority = priority .. "-pneumatic"
  local pneumatic_surge = surge .. "-pneumatic"
  for _, name in ipairs({pneumatic_priority, pneumatic_surge}) do
    local prototype = prototypes.entity[name]
    check(prototype ~= nil, name .. " prototype is missing")
    if prototype then
      check(prototype.electric_energy_source_prototype == nil,
        name .. " retained an electric energy source")
      check(prototype.fluid_energy_source_prototype ~= nil,
        name .. " has no fluid energy source")
      check(#prototype.items_to_place_this == 1 and
          prototype.items_to_place_this[1].name == "nullius-compressor-" .. tier,
        name .. " is not placed by the tier's compressor item")
      check(prototype.mineable_properties.products[1].name ==
          "nullius-compressor-" .. tier,
        name .. " mines to the wrong item")
    end
  end
  check(prototypes.entity["nullius-surge-electrolyzer-" .. tier ..
      "-pneumatic"] == nil,
    "pneumatic surge electrolyzer " .. tier .. " still exists")
  check(prototypes.entity["nullius-priority-electrolyzer-" .. tier ..
      "-pneumatic"] == nil,
    "pneumatic priority electrolyzer " .. tier .. " still exists")

  local machine = surface.create_entity{
    name = priority,
    position = position,
    force = game.forces.player,
  }
  check(machine ~= nil, "failed to place " .. priority)
  if not machine then return nil end
  machine = transition(surface, machine, surge)
  if not machine then return nil end
  machine = transition(surface, machine, pneumatic_surge)
  if not machine then return nil end
  machine = transition(surface, machine, pneumatic_priority)
  if not machine then return nil end
  machine = transition(surface, machine, priority)
  return machine
end

local function check_terminal()
  script.on_nth_tick(TERMINAL_TICK, nil)
  local machine = storage.machine
  local output = machine and machine.valid and
      machine.fluidbox[storage.output_box] or nil
  local fuel = machine and machine.valid and
      machine.fluidbox[storage.fuel_box] or nil
  observations.production = {
    products_finished = machine and machine.valid and machine.products_finished or 0,
    output = output and output.amount or 0,
    fuel_remaining = fuel and fuel.amount or 0,
  }
  check(machine and machine.valid, "production compressor disappeared")
  if machine and machine.valid then
    check(machine.products_finished == 1,
      "pneumatic compressor did not complete exactly one batch")
    check(output and output.name == COMPRESSED_NITROGEN and close(output.amount, 52),
      "compressed nitrogen output mismatch")
    check(fuel and fuel.name == FUEL and fuel.amount < 100,
      "pneumatic compressor consumed no volcanic gas")
    check(machine.prototype.electric_energy_source_prototype == nil,
      "production compressor acquired an electric energy source")
  end
  finish()
end

local function setup()
  script.on_nth_tick(1, nil)
  local planet = game.planets["nullius-vulcanus"]
  check(planet ~= nil, "missing nullius-vulcanus planet")
  if not planet then finish() return end
  local surface = planet.surface or planet.create_surface()
  check(surface ~= nil, "failed to create Vulcanus surface")
  if not surface then finish() return end
  surface.request_to_generate_chunks({0, 0}, 2)
  surface.force_generate_chunk_requests()
  local tiles = {}
  for x = -20, 20 do
    for y = -12, 12 do
      tiles[#tiles + 1] = {name = "volcanic-soil-dark", position = {x, y}}
    end
  end
  surface.set_tiles(tiles, true, false, false, false)
  for _, entity in ipairs(surface.find_entities_filtered{
      area = {{-20, -12}, {20, 12}},
      type = {"simple-entity", "tree", "cliff", "resource"},
  }) do
    entity.destroy()
  end

  local force = game.forces.player
  local researched = {}
  for _, name in ipairs({"nullius-pneumatic-technology", "nullius-energy-storage-2"}) do
    local technology = force.technologies[name]
    check(technology ~= nil, "missing technology " .. name)
    if technology then research_closure(technology, researched) end
  end
  check(force.recipes[RECIPE] and force.recipes[RECIPE].enabled,
    RECIPE .. " was not unlocked")

  for tier = 1, 3 do
    local electric = validate_tier(surface, tier, {-12 + tier * 6, -5})
    if electric and electric.valid then electric.destroy() end
  end
  if #failures > 0 then finish() return end

  local position = {0, 5}
  local machine = surface.create_entity{
    name = "nullius-priority-compressor-1",
    position = position,
    force = force,
  }
  machine = transition(surface, machine, "nullius-surge-compressor-1")
  machine = transition(surface, machine,
    "nullius-surge-compressor-1-pneumatic")
  if not machine then finish() return end
  check(machine.set_recipe(RECIPE), "pneumatic compressor rejected " .. RECIPE)
  storage.machine = machine
  set_fluid(machine, NITROGEN, 208, "input")
  storage.output_box = fluid_box(machine, COMPRESSED_NITROGEN, "output")
  check(storage.output_box ~= nil, "compressor has no compressed-nitrogen output")
  storage.fuel_box = set_fluid(machine, FUEL, 100, "fuel")
  if #failures > 0 then finish() return end
  script.on_nth_tick(TERMINAL_TICK, check_terminal)
end

script.on_nth_tick(1, setup)

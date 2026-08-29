local CASE = "vulcanus-hcl-thermal-cracking"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local HEAT_PRODUCER = "nullius-hydro-plant-1-pneumatic"
local HEAT_INTERFACE = "nullius-pneumatic-heat-large"
local HEAT_RECIPE = "nullius-lava-gas-extraction"
local RADIATOR = "nullius-vulcanus-radiator-2"
local CRACKING_RECIPE = "nullius-vulcanus-cracking"
local GAS = "nullius-compressed-volcanic-gas"
local HCL = "nullius-hydrogen-chloride"
local HYDROGEN = "nullius-hydrogen"
local CHLORINE = "nullius-chlorine"
local INITIAL_TECH = "nullius-pneumatic-technology"
local PRODUCER_POSITION = {32, 0}
local RADIATOR_POSITION = {37, 0}
local START_TICK = 80000
local RECIPE_TICKS = 120
local BEFORE_TICK = START_TICK + RECIPE_TICKS
local TERMINAL_TICK = BEFORE_TICK + 2

local assertions = 0
local failures = {}
local observations = {}

local function check(condition, message)
  assertions = assertions + 1
  if not condition then failures[#failures + 1] = message end
end

local function close(actual, expected)
  return math.abs(actual - expected) < 0.000001
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

local function build(surface, name, position)
  local ghost = surface.create_entity{
    name = "entity-ghost",
    inner_name = name,
    position = position,
    direction = defines.direction.north,
    force = game.forces.player,
    expires = false,
  }
  check(ghost ~= nil, "failed to create ghost for " .. name)
  if not ghost then return nil end
  local _, entity = ghost.revive{raise_revive = true}
  check(entity ~= nil, "failed to revive " .. name)
  return entity
end

local function place(surface, name, position)
  local entity = surface.create_entity{
    name = name,
    position = position,
    force = game.forces.player,
  }
  check(entity ~= nil,
    "failed to place " .. name .. " at [" .. position[1] .. "," ..
      position[2] .. "]")
  return entity
end

local function offset(origin, x, y)
  return {origin.x + x, origin.y + y}
end

local function filtered_fluidbox(machine, fluid)
  local found = nil
  for index = 1, #machine.fluidbox do
    local filter = machine.fluidbox.get_filter(index)
    if filter and filter.name == fluid then
      check(found == nil, machine.name .. " has multiple " .. fluid .. " fluidboxes")
      found = index
    end
  end
  check(found ~= nil, machine.name .. " has no " .. fluid .. " fluidbox")
  return found
end

local function fluid_amount(machine, fluid)
  return machine.get_fluid_count(fluid)
end

local function drain_stone()
  local output = storage.producer.get_output_inventory()
  if not output then return end
  local removed = output.remove{name = "stone", count = 1000000}
  if removed > 0 then
    local inserted = storage.stone_sink.insert{name = "stone", count = removed}
    check(inserted == removed, "debug stone sink rejected producer output")
  end
end

local function check_terminal()
  script.on_nth_tick(TERMINAL_TICK, nil)
  local radiator = storage.radiator
  local hydrogen = fluid_amount(radiator, HYDROGEN)
  local chlorine = fluid_amount(radiator, CHLORINE)
  local hcl = fluid_amount(radiator, HCL)
  observations.terminal = {
    radiator_temperature = radiator.temperature,
    interface_temperature = storage.heat_interface.temperature,
    producer_cycles = storage.producer.products_finished,
    cracking_cycles = radiator.products_finished,
    hcl = hcl,
    hydrogen = hydrogen,
    chlorine = chlorine,
    heat_pipe_1_count = #storage.surface.find_entities_filtered{
      name = "nullius-heat-pipe-1"},
    heat_pipe_2_count = #storage.surface.find_entities_filtered{
      name = "nullius-heat-pipe-2"},
  }
  check(radiator.products_finished == 1,
    "radiator did not complete exactly one HCl cracking cycle")
  check(close(hcl, 0), "radiator retained hydrogen chloride")
  check(close(hydrogen, 30), "radiator hydrogen output mismatch")
  check(close(chlorine, 30), "radiator chlorine output mismatch")
  check(radiator.temperature >= 450,
    "radiator fell below 450 C during HCl cracking")
  check(observations.terminal.heat_pipe_1_count == 0,
    "fixture used heat-pipe-1 in the high-temperature path")
  check(observations.terminal.heat_pipe_2_count == 0,
    "fixture used heat-pipe-2 instead of a direct heat connection")
  finish()
end

local function check_before_terminal()
  script.on_nth_tick(BEFORE_TICK, nil)
  observations.before_terminal = {
    cracking_cycles = storage.radiator.products_finished,
    crafting_progress = storage.radiator.crafting_progress,
    radiator_temperature = storage.radiator.temperature,
    hydrogen = fluid_amount(storage.radiator, HYDROGEN),
    chlorine = fluid_amount(storage.radiator, CHLORINE),
  }
  check(storage.radiator.products_finished == 0,
    "HCl cracking completed before its declared duration")
  check(close(observations.before_terminal.hydrogen, 0),
    "hydrogen appeared before the cracking cycle completed")
  check(close(observations.before_terminal.chlorine, 0),
    "chlorine appeared before the cracking cycle completed")
  script.on_nth_tick(TERMINAL_TICK, check_terminal)
end

local function start_cracking()
  script.on_nth_tick(START_TICK, nil)
  local surface = storage.surface
  local radiator = storage.radiator
  local heat_pipes = surface.find_entities_filtered{
    name = {"nullius-heat-pipe-1", "nullius-heat-pipe-2"},
  }
  observations.initial_heat = {
    producer_temperature = storage.heat_interface.temperature,
    radiator_temperature = radiator.temperature,
    producer_cycles = storage.producer.products_finished,
    heat_pipe_count = #heat_pipes,
    producer_status = storage.producer.status,
    producer_stone = storage.producer.get_item_count("stone"),
    stone_sink = storage.stone_sink.get_item_count("stone"),
  }
  check(storage.producer.products_finished > 0,
    "pneumatic heat producer completed no real recipe cycles")
  check(storage.heat_interface.temperature >= 450,
    "pneumatic heat producer did not reach 450 C")
  check(radiator.temperature >= 450,
    "radiator 2 did not receive 450 C through the direct connection")
  check(#heat_pipes == 0,
    "direct heat fixture unexpectedly contains a heat pipe")
  check(close(fluid_amount(radiator, HCL), 60),
    "hydrogen chloride changed before cracking started")
  check(close(fluid_amount(radiator, HYDROGEN), 0),
    "hydrogen output was not empty before cracking")
  check(close(fluid_amount(radiator, CHLORINE), 0),
    "chlorine output was not empty before cracking")
  check(radiator.products_finished == 0,
    "radiator crafted while disabled")
  if #failures > 0 then finish() return end
  radiator.active = true
  script.on_nth_tick(BEFORE_TICK, check_before_terminal)
end

local function setup()
  script.on_nth_tick(1, nil)
  local planet = game.planets["nullius-vulcanus"]
  check(planet ~= nil, "missing nullius-vulcanus planet")
  if not planet then finish() return end
  local surface = planet.surface or planet.create_surface()
  check(surface ~= nil, "failed to create Vulcanus surface")
  if not surface then finish() return end
  storage.surface = surface
  surface.request_to_generate_chunks({32, 0}, 2)
  surface.force_generate_chunk_requests()
  local tiles = {}
  for x = 20, 48 do
    for y = -12, 12 do
      tiles[#tiles + 1] = {name = "volcanic-soil-dark", position = {x, y}}
    end
  end
  surface.set_tiles(tiles, true, false, false, false)
  for _, entity in ipairs(surface.find_entities_filtered{
      area = {{20, -12}, {48, 12}},
      type = {"simple-entity", "tree", "cliff", "resource"},
  }) do
    entity.destroy()
  end

  local force = game.forces.player
  local initial_technology = force.technologies[INITIAL_TECH]
  check(initial_technology ~= nil, "missing initial pneumatic technology")
  if not initial_technology then finish() return end
  research_closure(initial_technology, {})
  check(force.recipes[HEAT_RECIPE] and force.recipes[HEAT_RECIPE].enabled,
    "heat-production recipe is not enabled by the declared research")
  check(force.recipes[CRACKING_RECIPE] and force.recipes[CRACKING_RECIPE].enabled,
    "HCl cracking requires research beyond the declared closure")

  local producer = build(surface, HEAT_PRODUCER, PRODUCER_POSITION)
  local radiator = build(surface, RADIATOR, RADIATOR_POSITION)
  if not producer or not radiator then finish() return end
  storage.producer = producer
  storage.radiator = radiator
  radiator.active = false
  check(producer.set_recipe(HEAT_RECIPE),
    "failed to set pneumatic heat-production recipe")
  check(radiator.set_recipe(CRACKING_RECIPE),
    "failed to set HCl cracking recipe")

  local recipe = radiator.get_recipe()
  check(recipe ~= nil and recipe.name == CRACKING_RECIPE,
    "radiator has the wrong recipe")
  if not recipe then finish() return end
  check(close(recipe.energy * 60, RECIPE_TICKS),
    "runtime cracking duration differs from the scenario contract")
  check(close(recipe.energy * 60 / radiator.crafting_speed, RECIPE_TICKS),
    "runtime radiator crafting speed differs from the scenario contract")

  local interfaces = surface.find_entities_filtered{
    name = HEAT_INTERFACE,
    position = producer.position,
    radius = 0.1,
  }
  check(#interfaces == 1,
    "pneumatic producer does not own exactly one large heat interface")
  if #interfaces ~= 1 then finish() return end
  storage.heat_interface = interfaces[1]
  check(#surface.find_entities_filtered{type = "heat-interface"} == 1,
    "fixture contains a heat interface not owned by the pneumatic producer")
  local radiator_heat = radiator.prototype.heat_energy_source_prototype
  local interface_heat = storage.heat_interface.prototype.heat_buffer_prototype
  local pipe_1_heat = prototypes.entity["nullius-heat-pipe-1"].heat_buffer_prototype
  check(radiator_heat ~= nil, "radiator 2 has no heat energy source")
  check(interface_heat ~= nil, "pneumatic producer has no heat buffer")
  check(pipe_1_heat ~= nil, "heat-pipe-1 has no heat buffer")
  if not radiator_heat or not interface_heat or not pipe_1_heat then
    finish()
    return
  end
  check(close(radiator_heat.min_working_temperature, 450),
    "radiator 2 minimum working temperature is not 450 C")
  check(pipe_1_heat.max_temperature < radiator_heat.min_working_temperature,
    "heat-pipe-1 unexpectedly supports radiator 2 working temperature")
  check(interface_heat.max_temperature >= radiator_heat.min_working_temperature,
    "pneumatic heat interface cannot supply radiator 2 working temperature")
  check(close(storage.heat_interface.temperature, 15),
    "pneumatic heat interface was preheated")
  check(close(radiator.temperature, 15), "radiator was preheated")

  local hcl_box = filtered_fluidbox(radiator, HCL)
  if not hcl_box then finish() return end

  storage.producer_fluid_entities = {}
  for _, pipe_offset in ipairs({
      {-3, 0}, {-4, 0}, {-5, 0},
      {-4, 1}, {-4, 2}, {-4, 3}, {-3, 3}, {-2, 3}, {-1, 3},
  }) do
    local pipe = place(surface, "pipe",
      offset(producer.position, pipe_offset[1], pipe_offset[2]))
    if not pipe then finish() return end
    storage.producer_fluid_entities[#storage.producer_fluid_entities + 1] = pipe
  end
  local gas_sink = place(surface, "infinity-pipe",
    offset(producer.position, -6, 0))
  if not gas_sink then finish() return end
  gas_sink.set_infinity_pipe_filter{
    name = GAS,
    percentage = 0.9,
    mode = "at-most",
    temperature = prototypes.fluid[GAS].default_temperature,
  }
  storage.producer_fluid_entities[#storage.producer_fluid_entities + 1] = gas_sink

  for _, pipe_offset in ipairs({{-1, -3}, {-1, -4}}) do
    local pipe = place(surface, "pipe",
      offset(producer.position, pipe_offset[1], pipe_offset[2]))
    if not pipe then finish() return end
    storage.producer_fluid_entities[#storage.producer_fluid_entities + 1] = pipe
  end
  local lava_source = place(surface, "infinity-pipe",
    offset(producer.position, -1, -5))
  if not lava_source then finish() return end
  lava_source.set_infinity_pipe_filter{
    name = "lava",
    percentage = 1,
    mode = "at-least",
    temperature = prototypes.fluid.lava.default_temperature,
  }
  storage.producer_fluid_entities[#storage.producer_fluid_entities + 1] = lava_source
  producer.fluidbox[1] = {
    name = GAS, amount = 24,
    temperature = prototypes.fluid[GAS].default_temperature,
  }
  local stone_sink = place(surface, "infinity-chest",
    offset(producer.position, 0, 4))
  if not stone_sink then finish() return end
  storage.stone_sink = stone_sink
  radiator.fluidbox[hcl_box] = {
    name = HCL, amount = 60,
    temperature = prototypes.fluid[HCL].default_temperature,
  }

  observations.geometry = {
    producer_position = producer.position,
    heat_interface_position = storage.heat_interface.position,
    radiator_position = radiator.position,
    heat_pipe_count = #surface.find_entities_filtered{
      name = {"nullius-heat-pipe-1", "nullius-heat-pipe-2"}},
  }
  check(observations.geometry.heat_pipe_count == 0,
    "fixture contains a heat pipe before operation")
  if #failures > 0 then finish() return end
  producer.active = true
  script.on_nth_tick(600, drain_stone)
  script.on_nth_tick(START_TICK, start_cracking)
end

script.on_nth_tick(1, setup)

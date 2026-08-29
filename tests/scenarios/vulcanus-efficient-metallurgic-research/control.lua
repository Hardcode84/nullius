local CASE = "vulcanus-efficient-metallurgic-research"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local TECHNOLOGY = "nullius-efficient-metallurgic-science"
local LAB = "nullius-lab-1-pneumatic"
local GAS = "nullius-compressed-volcanic-gas"
local LAB_POSITION = {20, 0}
local SETTLE_TICK = 60
local UNIT_COUNT = 5
local UNIT_TIME = 30
local RESEARCH_TICKS = UNIT_COUNT * UNIT_TIME * 60
local GAS_INPUT = 712.5
local PREREQUISITES = {
  ["nullius-pneumatic-technology"] = true,
}
local UNLOCKS = {
  "nullius-metallurgic-pack-efficient",
  "nullius-chlorine-barrel",
  "nullius-sulfur-dioxide-barrel",
}
local PACKS = {
  ["nullius-metallurgic-pack"] = 10,
  ["nullius-geology-pack"] = 10,
  ["nullius-mechanical-pack"] = 5,
  ["nullius-electrical-pack"] = 5,
}
local UNIT_INGREDIENTS = {
  ["nullius-metallurgic-pack"] = 2,
  ["nullius-geology-pack"] = 2,
  ["nullius-mechanical-pack"] = 1,
  ["nullius-electrical-pack"] = 1,
}

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

local function names_to_set(entries)
  local result = {}
  for _, entry in pairs(entries) do
    result[type(entry) == "string" and entry or entry.name] = true
  end
  return result
end

local function ingredients_to_map(entries)
  local result = {}
  for _, entry in pairs(entries) do
    result[entry.name] = entry.amount
  end
  return result
end

local function check_exact(actual, expected, label)
  for name, value in pairs(expected) do
    check(actual[name] == value,
      label .. " expected " .. tostring(value) .. " for " .. name ..
      ", found " .. tostring(actual[name]))
  end
  for name, value in pairs(actual) do
    check(expected[name] == value,
      label .. " contained unexpected " .. name .. "=" .. tostring(value))
  end
end

local function gas_total()
  local total = storage.lab.get_fluid_count(GAS)
  for _, entity in ipairs(storage.gas_entities) do
    if entity.valid then total = total + entity.get_fluid_count(GAS) end
  end
  return total
end

local function input_counts()
  local result = {}
  for _, stack in pairs(storage.input_inventory.get_contents()) do
    result[stack.name] = (result[stack.name] or 0) + stack.count
  end
  return result
end

local function terminal_check()
  script.on_nth_tick(9180, nil)
  local force = game.forces.player
  local gas = gas_total()
  observations.terminal = {
    elapsed_ticks = game.tick - storage.started_tick,
    research_progress = force.research_progress,
    remaining_inputs = input_counts(),
    gas = gas,
    gas_consumed = GAS_INPUT - gas,
    finished_events = storage.finished_events,
  }
  check(force.technologies[TECHNOLOGY].researched,
    "Efficient metallurgic science was not researched")
  check(storage.finished_events == 1,
    "expected exactly one research-finished event")
  check_exact(input_counts(), {}, "terminal lab input")
  check(close(gas, 0), "terminal retained compressed volcanic gas")
  check(close(GAS_INPUT - gas, GAS_INPUT),
    "terminal compressed-gas consumption mismatch")
  check(storage.finished_tick - storage.started_tick == RESEARCH_TICKS,
    "research duration differed from 9000 ticks")
  check(storage.finished_by_script == false,
    "research-finished event was marked as scripted")
  for _, recipe_name in ipairs(UNLOCKS) do
    check(force.recipes[recipe_name] and force.recipes[recipe_name].enabled,
      recipe_name .. " was not unlocked by completed research")
  end
  finish()
end

local function timeout_check()
  script.on_nth_tick(9180, nil)
  local force = game.forces.player
  observations.timeout = {
    started_tick = storage.started_tick,
    research_progress = force.research_progress,
    current_research = force.current_research and force.current_research.name,
    inputs = storage.input_inventory and input_counts() or {},
    gas = storage.lab and gas_total() or 0,
    lab_active = storage.lab and storage.lab.active,
    lab_status = storage.lab and storage.lab.status,
  }
  check(false, "research did not finish by tick 9180")
  finish()
end

script.on_event(defines.events.on_research_finished, function(event)
  if event.research.name ~= TECHNOLOGY then return end
  storage.finished_events = storage.finished_events + 1
  storage.finished_tick = game.tick
  storage.finished_by_script = event.by_script
  observations.finished_event = {
    tick = game.tick,
    elapsed_ticks = game.tick - storage.started_tick,
    by_script = event.by_script,
  }
  script.on_nth_tick(game.tick + 1, function()
    script.on_nth_tick(game.tick, nil)
    terminal_check()
  end)
end)

local function start_research()
  script.on_nth_tick(SETTLE_TICK, nil)
  local force = game.forces.player
  observations.initial = {
    inputs = input_counts(),
    gas = gas_total(),
    research_progress = force.research_progress,
  }
  check_exact(input_counts(), PACKS, "initial lab input")
  check(close(gas_total(), GAS_INPUT),
    "compressed gas changed while fixture settled")
  check(not force.technologies[TECHNOLOGY].researched,
    "target research completed while fixture settled")
  check(force.current_research == nil,
    "research started while fixture settled")
  if #failures > 0 then finish() return end

  check(force.add_research(force.technologies[TECHNOLOGY]),
    "Factorio refused to start Efficient metallurgic science")
  check(force.current_research == force.technologies[TECHNOLOGY],
    "Efficient metallurgic science is not current research")
  storage.started_tick = game.tick
  storage.lab.active = true
end

local function setup()
  script.on_nth_tick(1, nil)
  local planet = game.planets["nullius-vulcanus"]
  check(planet ~= nil, "missing nullius-vulcanus planet")
  if not planet then finish() return end
  local surface = planet.surface or planet.create_surface()
  check(surface ~= nil, "failed to create Vulcanus surface")
  if not surface then finish() return end
  surface.request_to_generate_chunks(LAB_POSITION, 1)
  surface.force_generate_chunk_requests()
  local tiles = {}
  for x = 4, 36 do
    for y = -16, 16 do
      tiles[#tiles + 1] = {name = "volcanic-soil-dark", position = {x, y}}
    end
  end
  surface.set_tiles(tiles, true, false, false, false)
  for _, entity in ipairs(surface.find_entities_filtered{
      area = {{4, -16}, {36, 16}},
      type = {"simple-entity", "tree", "cliff", "resource"},
  }) do
    entity.destroy()
  end

  local force = game.forces.player
  local technology = force.technologies[TECHNOLOGY]
  check(technology ~= nil, "missing Efficient metallurgic science technology")
  if not technology then finish() return end
  check_exact(names_to_set(technology.prototype.prerequisites), PREREQUISITES,
    "technology prerequisites")
  check(technology.prototype.research_unit_count == UNIT_COUNT,
    "technology unit count differs from progression contract")
  check(close(technology.prototype.research_unit_energy, UNIT_TIME * 60),
    "technology unit time differs from progression contract")
  check_exact(ingredients_to_map(technology.prototype.research_unit_ingredients),
    UNIT_INGREDIENTS, "technology unit ingredients")
  for name in pairs(PREREQUISITES) do
    local prerequisite = force.technologies[name]
    check(prerequisite ~= nil, "missing prerequisite " .. name)
    if prerequisite then prerequisite.researched = true end
  end
  technology.enabled = true
  technology.researched = false
  for _, recipe_name in ipairs(UNLOCKS) do
    check(force.recipes[recipe_name] and not force.recipes[recipe_name].enabled,
      recipe_name .. " was enabled before efficient metallurgy research")
  end

  local ghost = surface.create_entity{
    name = "entity-ghost",
    inner_name = LAB,
    position = LAB_POSITION,
    direction = defines.direction.north,
    force = force,
    expires = false,
  }
  check(ghost ~= nil, "failed to create pneumatic lab ghost")
  if not ghost then finish() return end
  local _, lab = ghost.revive{raise_revive = true}
  check(lab ~= nil, "failed to build pneumatic lab")
  if not lab then finish() return end
  storage.lab = lab
  lab.active = false

  local lab_inputs = names_to_set(lab.prototype.lab_inputs)
  for name in pairs(UNIT_INGREDIENTS) do
    check(lab_inputs[name] == true, "pneumatic lab rejects " .. name)
  end
  local fluid_source = lab.prototype.fluid_energy_source_prototype
  check(fluid_source ~= nil, "pneumatic lab has no fluid energy source")
  check(lab.prototype.electric_energy_source_prototype == nil,
    "pneumatic lab unexpectedly requires electricity")
  check(lab.prototype.heat_energy_source_prototype == nil,
    "pneumatic lab unexpectedly requires heat")
  check(close(lab.prototype.get_researching_speed(), 1),
    "pneumatic lab research speed differs from 1")
  if not fluid_source then finish() return end

  local gas_box = nil
  for index = 1, #lab.fluidbox do
    local filter = lab.fluidbox.get_filter(index)
    if filter and filter.name == GAS then gas_box = index end
  end
  if not gas_box and #lab.fluidbox == 1 then gas_box = 1 end
  check(gas_box ~= nil, "pneumatic lab has no compressed-gas energy box")
  if not gas_box then finish() return end
  local connection = lab.fluidbox.get_pipe_connections(gas_box)[1]
  check(connection ~= nil, "compressed-gas energy box has no connection")
  if not connection then finish() return end

  local dx = connection.target_position.x - lab.position.x
  local dy = connection.target_position.y - lab.position.y
  check(not (close(dx, 0) and close(dy, 0)),
    "compressed-gas connection has no outward direction")
  dx = (dx == 0) and 0 or ((dx > 0) and 1 or -1)
  dy = (dy == 0) and 0 or ((dy > 0) and 1 or -1)
  local pipe = surface.create_entity{
    name = "pipe",
    position = connection.target_position,
    force = force,
  }
  check(pipe ~= nil, "failed to build compressed-gas connection pipe")
  local tank = surface.create_entity{
    name = "storage-tank",
    position = {
      connection.target_position.x + dx * 2 - dy,
      connection.target_position.y + dy * 2 + dx,
    },
    force = force,
  }
  check(tank ~= nil, "failed to build compressed-gas storage tank")
  if not pipe or not tank then finish() return end
  storage.gas_entities = {pipe, tank}
  local inserted = tank.insert_fluid{
    name = GAS,
    amount = GAS_INPUT,
    temperature = prototypes.fluid[GAS].default_temperature,
  }
  check(close(inserted, GAS_INPUT),
    "failed to insert exact compressed-gas budget")
  check(close(gas_total(), GAS_INPUT),
    "gas fixture does not contain exact compressed-gas budget")

  local energy = lab.prototype.get_max_energy_usage() * RESEARCH_TICKS
  local required_gas = energy /
    (prototypes.fluid[GAS].fuel_value * fluid_source.effectivity)
  observations.runtime = {
    unit_count = technology.prototype.research_unit_count,
    unit_ticks = technology.prototype.research_unit_energy,
    research_ticks = RESEARCH_TICKS,
    researching_speed = lab.prototype.get_researching_speed(),
    maximum_energy_usage = lab.prototype.get_max_energy_usage(),
    gas_fuel_value = prototypes.fluid[GAS].fuel_value,
    fuel_effectivity = fluid_source.effectivity,
    required_gas = required_gas,
    gas_buffer_entities = #storage.gas_entities,
  }
  check(close(required_gas, GAS_INPUT),
    "runtime pneumatic fuel demand differs from progression contract")

  local input_inventory = lab.get_inventory(defines.inventory.lab_input)
  check(input_inventory ~= nil, "pneumatic lab has no input inventory")
  if not input_inventory then finish() return end
  storage.input_inventory = input_inventory
  for name, count in pairs(PACKS) do
    check(input_inventory.insert{name = name, count = count} == count,
      "failed to insert exact research input " .. name)
  end
  storage.finished_events = 0
  if #failures > 0 then finish() return end
  script.on_nth_tick(SETTLE_TICK, start_research)
  script.on_nth_tick(9180, timeout_check)
end

script.on_nth_tick(1, setup)


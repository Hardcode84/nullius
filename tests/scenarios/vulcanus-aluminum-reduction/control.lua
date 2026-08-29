local CASE = "vulcanus-aluminum-reduction"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local MACHINE = "nullius-small-furnace-1-pneumatic"
local RECIPE = "nullius-aluminum-ingot"
local HEAT_PIPE = "nullius-heat-pipe-1"
local RECIPE_TICKS = 600
local CRAFT_TICKS = 2400
local TERMINAL_TICKS = 2402
local INITIAL_TECH = "nullius-pneumatic-technology"
local RECIPE_TECH = "nullius-aluminum-production"
local MACHINE_POSITION = {20, 0}
local MIN_AVAILABLE_ENERGY = 2760000
local INPUTS = {
  ["nullius-alumina"] = 9,
  ["nullius-graphite"] = 5,
}
local OUTPUTS = {
  ["nullius-aluminum-ingot"] = 3,
  ["nullius-aluminum-carbide"] = 4,
}
local DIRECTION_OFFSET = {
  [defines.direction.north] = {0, -1},
  [defines.direction.east] = {1, 0},
  [defines.direction.south] = {0, 1},
  [defines.direction.west] = {-1, 0},
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

local function item_amount(entries, name)
  for _, entry in pairs(entries) do
    if entry.name == name then return entry.amount end
  end
  return 0
end

local function research_closure(technology, visited)
  if visited[technology.name] then return end
  visited[technology.name] = true
  for _, prerequisite in pairs(technology.prerequisites) do
    research_closure(prerequisite, visited)
  end
  technology.researched = true
end

local function status_name(status)
  for name, value in pairs(defines.entity_status) do
    if value == status then return name end
  end
  return tostring(status)
end

local function inventory_counts(inventory)
  local result = {}
  for _, stack in pairs(inventory.get_contents()) do
    result[stack.name] = (result[stack.name] or 0) + stack.count
  end
  return result
end

local function output_counts()
  local result = {}
  local inventory = storage.machine.get_output_inventory()
  if not inventory then return result end
  return inventory_counts(inventory)
end

local function check_exact_counts(actual, expected, label)
  for name, count in pairs(expected) do
    check(actual[name] == count,
      label .. " expected " .. count .. " " .. name ..
      ", found " .. tostring(actual[name] or 0))
  end
  for name, count in pairs(actual) do
    check(expected[name] == count,
      label .. " contained unexpected " .. count .. " " .. name)
  end
end

local function check_terminal()
  script.on_nth_tick(storage.terminal_tick, nil)
  local outputs = output_counts()
  observations.terminal = {
    elapsed_ticks = game.tick - storage.started_tick,
    cycles = storage.machine.products_finished,
    crafting_progress = storage.machine.crafting_progress,
    temperature = storage.machine.temperature,
    status = status_name(storage.machine.status),
    active = storage.machine.active,
    outputs = outputs,
  }
  check(storage.machine.products_finished == 1,
    "terminal did not complete exactly one reduction cycle")
  check_exact_counts(outputs, OUTPUTS, "terminal output")
  for name in pairs(INPUTS) do
    check(storage.machine.get_item_count(name) == 0,
      "terminal retained input " .. name)
  end
  finish()
end

local function check_before_terminal()
  script.on_nth_tick(storage.before_tick, nil)
  local outputs = output_counts()
  observations.before_terminal = {
    elapsed_ticks = game.tick - storage.started_tick,
    cycles = storage.machine.products_finished,
    crafting_progress = storage.machine.crafting_progress,
    temperature = storage.machine.temperature,
    status = status_name(storage.machine.status),
    active = storage.machine.active,
    inputs = inventory_counts(storage.input_inventory),
    outputs = outputs,
  }
  check(storage.machine.products_finished == 0,
    "reduction completed before its declared recipe duration")
  check_exact_counts(outputs, {}, "pre-terminal output")
  script.on_nth_tick(storage.terminal_tick, check_terminal)
end

local function start_machine()
  script.on_nth_tick(60, nil)
  local heat_source = storage.machine.prototype.heat_energy_source_prototype
  local pipe_buffer = storage.heat_pipe.prototype.heat_buffer_prototype
  local minimum_temperature = heat_source.min_working_temperature
  local available_energy =
    math.max(0, storage.machine.temperature - minimum_temperature) *
      heat_source.specific_heat +
    math.max(0, storage.heat_pipe.temperature - minimum_temperature) *
      pipe_buffer.specific_heat
  observations.initial_heat = {
    furnace_temperature = storage.machine.temperature,
    pipe_temperature = storage.heat_pipe.temperature,
    minimum_temperature = minimum_temperature,
    available_energy = available_energy,
    status = status_name(storage.machine.status),
    active = storage.machine.active,
  }
  check(storage.machine.temperature >= 100,
    "preheated furnace fell below 100 C before recipe start")
  check(storage.heat_pipe.temperature > storage.initial_pipe_temperature + 1,
    "heat pipe did not connect to the preheated furnace")
  check(available_energy >= MIN_AVAILABLE_ENERGY,
    "connected heat network has less than declared available energy")
  check(storage.machine.products_finished == 0,
    "furnace crafted while heat fixture was settling")
  check_exact_counts(output_counts(), {}, "initial output")

  storage.machine.active = true
  storage.started_tick = game.tick
  storage.before_tick = game.tick + CRAFT_TICKS
  storage.terminal_tick = game.tick + TERMINAL_TICKS
  script.on_nth_tick(storage.before_tick, check_before_terminal)
end

local function setup()
  script.on_nth_tick(1, nil)
  local planet = game.planets["nullius-vulcanus"]
  check(planet ~= nil, "missing nullius-vulcanus planet")
  if not planet then finish() return end
  local surface = planet.surface or planet.create_surface()
  check(surface ~= nil, "failed to create Vulcanus surface")
  if not surface then finish() return end
  surface.request_to_generate_chunks({0, 0}, 1)
  surface.force_generate_chunk_requests()
  local tiles = {}
  for x = -12, 32 do
    for y = -12, 12 do
      tiles[#tiles + 1] = {name = "volcanic-soil-dark", position = {x, y}}
    end
  end
  surface.set_tiles(tiles, true, false, false, false)

  local force = game.forces.player
  local initial_technology = force.technologies[INITIAL_TECH]
  check(initial_technology ~= nil, "missing initial pneumatic technology")
  if not initial_technology then finish() return end
  local researched = {}
  research_closure(initial_technology, researched)
  check(initial_technology.researched,
    "failed to research initial pneumatic technology")
  check(researched[RECIPE_TECH] == true,
    "initial pneumatic prerequisite closure omitted aluminum production")
  check(force.technologies[RECIPE_TECH] and
      force.technologies[RECIPE_TECH].researched,
    "aluminum production prerequisite is not researched")
  check(force.recipes[RECIPE] and force.recipes[RECIPE].enabled,
    "aluminum reduction recipe is not enabled by the declared research")

  local ghost = surface.create_entity{
    name = "entity-ghost",
    inner_name = MACHINE,
    position = MACHINE_POSITION,
    direction = defines.direction.north,
    force = force,
    expires = false,
  }
  check(ghost ~= nil, "failed to create pneumatic furnace ghost")
  if not ghost then finish() return end
  ghost.revive{raise_revive = true}
  local machines = surface.find_entities_filtered{
    name = MACHINE,
    position = MACHINE_POSITION,
    radius = 0.1,
  }
  check(#machines == 1,
    "production build did not create exactly one pneumatic furnace")
  if #machines ~= 1 then finish() return end
  local machine = machines[1]
  storage.machine = machine
  machine.active = false

  local heat_source = machine.prototype.heat_energy_source_prototype
  check(heat_source ~= nil, "pneumatic furnace has no heat energy source")
  check(machine.prototype.fluid_energy_source_prototype == nil,
    "pneumatic furnace unexpectedly requires fluid fuel")
  if not heat_source then finish() return end
  check(#heat_source.connections > 0,
    "pneumatic furnace has no runtime heat connection")
  if #heat_source.connections == 0 then finish() return end
  machine.temperature = heat_source.max_temperature

  local recipe_set = machine.set_recipe(RECIPE)
  check(recipe_set, "failed to set aluminum reduction recipe")
  local recipe = machine.get_recipe()
  check(recipe and recipe.name == RECIPE,
    "pneumatic furnace has the wrong recipe")
  if not recipe_set or not recipe or recipe.name ~= RECIPE then
    finish()
    return
  end
  check(close(recipe.energy * 60, RECIPE_TICKS),
    "runtime aluminum reduction duration differs from the matrix")
  for name, amount in pairs(INPUTS) do
    check(item_amount(recipe.ingredients, name) == amount,
      "runtime recipe input mismatch for " .. name)
  end
  for name, amount in pairs(OUTPUTS) do
    check(item_amount(recipe.products, name) == amount,
      "runtime recipe output mismatch for " .. name)
  end

  local connection = heat_source.connections[1]
  local direction_offset = DIRECTION_OFFSET[connection.direction]
  check(direction_offset ~= nil, "furnace heat connection is not cardinal")
  if not direction_offset then finish() return end
  observations.runtime = {
    entity_type = machine.type,
    crafting_speed = machine.crafting_speed,
    recipe_ticks = recipe.energy * 60,
    heat_connection = {
      position = connection.position,
      direction = connection.direction,
    },
    minimum_temperature = heat_source.min_working_temperature,
    maximum_temperature = heat_source.max_temperature,
    specific_heat = heat_source.specific_heat,
  }
  check(close(recipe.energy * 60 / machine.crafting_speed, CRAFT_TICKS),
    "runtime furnace craft duration differs from the matrix")
  local pipe_position = {
    machine.position.x + connection.position[1] + direction_offset[1],
    machine.position.y + connection.position[2] + direction_offset[2],
  }
  local heat_pipe = surface.create_entity{
    name = HEAT_PIPE,
    position = pipe_position,
    force = force,
  }
  check(heat_pipe ~= nil, "failed to place heat pipe at furnace connection")
  if not heat_pipe then finish() return end
  storage.heat_pipe = heat_pipe
  storage.initial_pipe_temperature = heat_pipe.temperature

  local input_inventory = machine.get_inventory(
    defines.inventory.assembling_machine_input)
  check(input_inventory ~= nil, "pneumatic furnace has no crafter input inventory")
  if not input_inventory then finish() return end
  storage.input_inventory = input_inventory
  for name, amount in pairs(INPUTS) do
    check(input_inventory.insert{name = name, count = amount} == amount,
      "failed to insert exact input " .. name)
    check(input_inventory.get_item_count(name) == amount,
      "furnace input mismatch for " .. name)
  end

  script.on_nth_tick(60, start_machine)
end

script.on_nth_tick(1, setup)

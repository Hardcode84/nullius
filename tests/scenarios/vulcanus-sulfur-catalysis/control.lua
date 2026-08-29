local CASE = "vulcanus-sulfur-catalysis"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local MACHINE = "nullius-vulcanus-radiator-1"
local RECIPE = "nullius-so2-catalytic-decomposition"
local HEAT_PIPE = "nullius-heat-pipe-1"
local SO2 = "nullius-sulfur-dioxide"
local OXYGEN = "nullius-oxygen"
local INITIAL_TECH = "nullius-pneumatic-technology"
local MACHINE_POSITION = {20, 0}
local RECIPE_TICKS = 240
local CRAFT_TICKS = 240
local TERMINAL_TICKS = 242
local MIN_AVAILABLE_ENERGY = 4000000
local INPUT_ITEMS = { ["nullius-rutile"] = 1 }
local OUTPUT_ITEMS = { sulfur = 1, ["nullius-rutile"] = 1 }
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
  local inventory = storage.machine.get_output_inventory()
  if not inventory then return {} end
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

local function fluid_total(fluid, entities)
  local total = storage.machine.get_fluid_count(fluid)
  for _, entity in ipairs(entities) do
    if entity.valid then total = total + entity.get_fluid_count(fluid) end
  end
  return total
end

local function check_terminal()
  script.on_nth_tick(storage.terminal_tick, nil)
  local items = output_counts()
  local so2 = fluid_total(SO2, storage.input_entities)
  local oxygen = fluid_total(OXYGEN, storage.output_entities)
  local output_pipe_oxygen = storage.output_entities[1].get_fluid_count(OXYGEN)
  observations.terminal = {
    elapsed_ticks = game.tick - storage.started_tick,
    cycles = storage.machine.products_finished,
    crafting_progress = storage.machine.crafting_progress,
    temperature = storage.machine.temperature,
    status = status_name(storage.machine.status),
    items = items,
    sulfur_dioxide = so2,
    oxygen = oxygen,
    output_pipe_oxygen = output_pipe_oxygen,
  }
  check(storage.machine.products_finished == 1,
    "terminal did not complete exactly one catalysis cycle")
  check_exact_counts(items, OUTPUT_ITEMS, "terminal item output")
  check(close(so2, 0), "terminal retained sulfur dioxide input")
  check(close(oxygen, 40), "terminal oxygen output mismatch")
  check(output_pipe_oxygen > 0,
    "terminal oxygen did not reach the connected output pipe")
  check(storage.machine.get_item_count("nullius-rutile") == 1,
    "terminal did not return the rutile catalyst")
  finish()
end

local function check_before_terminal()
  script.on_nth_tick(storage.before_tick, nil)
  local items = output_counts()
  local oxygen = fluid_total(OXYGEN, storage.output_entities)
  observations.before_terminal = {
    elapsed_ticks = game.tick - storage.started_tick,
    cycles = storage.machine.products_finished,
    crafting_progress = storage.machine.crafting_progress,
    temperature = storage.machine.temperature,
    status = status_name(storage.machine.status),
    items = items,
    oxygen = oxygen,
  }
  check(storage.machine.products_finished == 0,
    "catalysis completed before its declared duration")
  check_exact_counts(items, {}, "pre-terminal item output")
  check(close(oxygen, 0), "oxygen appeared before terminal")
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
  observations.initial = {
    radiator_temperature = storage.machine.temperature,
    heat_pipe_temperature = storage.heat_pipe.temperature,
    available_energy = available_energy,
    sulfur_dioxide = fluid_total(SO2, storage.input_entities),
    oxygen = fluid_total(OXYGEN, storage.output_entities),
    items = inventory_counts(storage.input_inventory),
  }
  check(storage.machine.temperature >= 200,
    "preheated radiator fell below 200 C before recipe start")
  check(storage.heat_pipe.temperature > storage.initial_pipe_temperature + 1,
    "heat pipe did not connect to the preheated radiator")
  check(available_energy >= MIN_AVAILABLE_ENERGY,
    "connected heat network has less than declared available energy")
  check(close(observations.initial.sulfur_dioxide, 40),
    "sulfur dioxide changed while fixture was settling")
  check(close(observations.initial.oxygen, 0),
    "oxygen fixture was not empty")
  check_exact_counts(observations.initial.items, INPUT_ITEMS, "initial item input")
  check_exact_counts(output_counts(), {}, "initial item output")
  check(storage.machine.products_finished == 0,
    "radiator crafted while fixture was settling")

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
  check(force.recipes[RECIPE] and force.recipes[RECIPE].enabled,
    "catalysis recipe requires research beyond the declared closure")

  local ghost = surface.create_entity{
    name = "entity-ghost",
    inner_name = MACHINE,
    position = MACHINE_POSITION,
    direction = defines.direction.north,
    force = force,
    expires = false,
  }
  check(ghost ~= nil, "failed to create radiator ghost")
  if not ghost then finish() return end
  ghost.revive{raise_revive = true}
  local machines = surface.find_entities_filtered{
    name = MACHINE,
    position = MACHINE_POSITION,
    radius = 3,
  }
  check(#machines == 1,
    "production build did not create exactly one radiator")
  if #machines ~= 1 then finish() return end
  local machine = machines[1]
  storage.machine = machine
  machine.active = false

  local heat_source = machine.prototype.heat_energy_source_prototype
  check(heat_source ~= nil, "radiator has no heat energy source")
  if not heat_source then finish() return end
  check(#heat_source.connections > 0, "radiator has no runtime heat connection")
  if #heat_source.connections == 0 then finish() return end
  machine.temperature = heat_source.max_temperature

  local recipe_set = machine.set_recipe(RECIPE)
  check(recipe_set, "failed to set catalytic decomposition recipe")
  local recipe = machine.get_recipe()
  check(recipe and recipe.name == RECIPE, "radiator has the wrong recipe")
  if not recipe_set or not recipe or recipe.name ~= RECIPE then
    finish()
    return
  end
  check(close(recipe.energy * 60, RECIPE_TICKS),
    "runtime catalysis recipe duration differs from the matrix")
  check(close(recipe.energy * 60 / machine.crafting_speed, CRAFT_TICKS),
    "runtime radiator craft duration differs from the matrix")
  check(item_amount(recipe.ingredients, SO2) == 40,
    "runtime sulfur dioxide input differs from the matrix")
  check(item_amount(recipe.ingredients, "nullius-rutile") == 1,
    "runtime rutile input differs from the matrix")
  check(item_amount(recipe.products, OXYGEN) == 40,
    "runtime oxygen output differs from the matrix")
  check(item_amount(recipe.products, "sulfur") == 1,
    "runtime sulfur output differs from the matrix")
  check(item_amount(recipe.products, "nullius-rutile") == 1,
    "runtime rutile return differs from the matrix")

  local input_fluidbox = nil
  local output_fluidbox = nil
  for index = 1, #machine.fluidbox do
    local filter = machine.fluidbox.get_filter(index)
    if filter and filter.name == SO2 then
      check(input_fluidbox == nil, "radiator has multiple fluid input boxes")
      input_fluidbox = index
    elseif filter and filter.name == OXYGEN then
      check(output_fluidbox == nil, "radiator has multiple fluid output boxes")
      output_fluidbox = index
    end
  end
  check(input_fluidbox ~= nil, "radiator has no fluid input box")
  check(output_fluidbox ~= nil, "radiator has no fluid output box")
  if not input_fluidbox or not output_fluidbox then finish() return end
  storage.input_fluidbox = input_fluidbox
  storage.output_fluidbox = output_fluidbox

  local function fluid_pipe(fluidbox_index, label)
    local connection = machine.fluidbox.get_pipe_connections(fluidbox_index)[1]
    check(connection ~= nil, "radiator has no " .. label .. " pipe connection")
    if not connection then return nil end
    local position = connection.target_position
    local pipe = surface.create_entity{
      name = "pipe",
      position = position,
      force = force,
    }
    check(pipe ~= nil, "failed to place radiator " .. label .. " pipe")
    return pipe
  end

  local input_pipe = fluid_pipe(input_fluidbox, "input")
  local output_pipe = fluid_pipe(output_fluidbox, "output")
  if not input_pipe or not output_pipe then finish() return end
  storage.input_entities = {input_pipe}
  storage.output_entities = {output_pipe}

  local heat_connection = heat_source.connections[1]
  local direction_offset = DIRECTION_OFFSET[heat_connection.direction]
  check(direction_offset ~= nil, "radiator heat connection is not cardinal")
  if not direction_offset then finish() return end
  local heat_position = heat_connection.position
  local heat_pipe = surface.create_entity{
    name = HEAT_PIPE,
    position = {
      machine.position.x + heat_position[1] + direction_offset[1],
      machine.position.y + heat_position[2] + direction_offset[2],
    },
    force = force,
  }
  check(heat_pipe ~= nil, "failed to place heat pipe at radiator connection")
  if not heat_pipe then finish() return end
  storage.heat_pipe = heat_pipe
  heat_pipe.temperature = heat_source.min_working_temperature
  storage.initial_pipe_temperature = heat_pipe.temperature

  local input_inventory = machine.get_inventory(
    defines.inventory.assembling_machine_input)
  check(input_inventory ~= nil, "radiator has no item input inventory")
  if not input_inventory then finish() return end
  storage.input_inventory = input_inventory
  check(input_inventory.insert{name = "nullius-rutile", count = 1} == 1,
    "failed to insert exact rutile catalyst")

  local inserted = input_pipe.insert_fluid{
    name = SO2,
    amount = 40,
    temperature = prototypes.fluid[SO2].default_temperature,
  }
  check(close(inserted, 40), "failed to insert exact sulfur dioxide input")

  observations.runtime = {
    crafting_speed = machine.crafting_speed,
    recipe_ticks = recipe.energy * 60,
    input_fluidbox = input_fluidbox,
    output_fluidbox = output_fluidbox,
    minimum_temperature = heat_source.min_working_temperature,
    maximum_temperature = heat_source.max_temperature,
  }
  script.on_nth_tick(60, start_machine)
end

script.on_nth_tick(1, setup)

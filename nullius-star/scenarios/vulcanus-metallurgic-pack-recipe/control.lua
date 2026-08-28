local CASE = "vulcanus-metallurgic-pack-recipe"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local MACHINE = "nullius-small-assembler-1-pneumatic"
local RECIPE = "nullius-metallurgic-pack"
local GAS = "nullius-compressed-volcanic-gas"
local PACK = "nullius-metallurgic-pack"
local INITIAL_TECH = "nullius-pneumatic-technology"
local MACHINE_POSITION = {20, 0}
local RECIPE_TICKS = 3600
local CRAFT_TICKS = 7200
local TERMINAL_TICKS = 7202
local GAS_INPUT = 354
local INPUTS = {
  ["nullius-iron-ingot"] = 12,
  ["nullius-aluminum-ingot"] = 8,
  ["nullius-crushed-limestone"] = 4,
  ["nullius-silica"] = 4,
  sulfur = 4,
}
local OUTPUTS = {[PACK] = 1}

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

local function gas_total()
  local total = storage.machine.get_fluid_count(GAS)
  for _, entity in ipairs(storage.gas_entities) do
    if entity.valid then total = total + entity.get_fluid_count(GAS) end
  end
  return total
end

local function check_terminal()
  script.on_nth_tick(storage.terminal_tick, nil)
  local outputs = output_counts()
  local gas = gas_total()
  observations.terminal = {
    elapsed_ticks = game.tick - storage.started_tick,
    cycles = storage.machine.products_finished,
    crafting_progress = storage.machine.crafting_progress,
    status = status_name(storage.machine.status),
    outputs = outputs,
    gas = gas,
    gas_consumed = GAS_INPUT - gas,
  }
  check(storage.machine.products_finished == 1,
    "terminal did not complete exactly one metallurgic-pack cycle")
  check_exact_counts(outputs, OUTPUTS, "terminal output")
  check(close(gas, 0), "terminal retained compressed volcanic gas")
  check(close(GAS_INPUT - gas, GAS_INPUT),
    "terminal compressed-gas consumption mismatch")
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
    status = status_name(storage.machine.status),
    outputs = outputs,
    gas = gas_total(),
  }
  check(storage.machine.products_finished == 0,
    "metallurgic pack completed before its declared duration")
  check_exact_counts(outputs, {}, "pre-terminal output")
  script.on_nth_tick(storage.terminal_tick, check_terminal)
end

local function start_machine()
  script.on_nth_tick(60, nil)
  local inputs = inventory_counts(storage.input_inventory)
  local gas = gas_total()
  observations.initial = {
    items = inputs,
    gas = gas,
    cycles = storage.machine.products_finished,
    status = status_name(storage.machine.status),
  }
  check_exact_counts(inputs, INPUTS, "initial input")
  check_exact_counts(output_counts(), {}, "initial output")
  check(close(gas, GAS_INPUT),
    "compressed gas changed while the fixture was settling")
  check(storage.machine.products_finished == 0,
    "assembler crafted while the fixture was settling")

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
  surface.request_to_generate_chunks(MACHINE_POSITION, 1)
  surface.force_generate_chunk_requests()
  local tiles = {}
  for x = 8, 32 do
    for y = -12, 12 do
      tiles[#tiles + 1] = {name = "volcanic-soil-dark", position = {x, y}}
    end
  end
  surface.set_tiles(tiles, true, false, false, false)
  for _, entity in ipairs(surface.find_entities_filtered{
      area = {{8, -12}, {32, 12}},
      type = {"simple-entity", "tree", "cliff", "resource"},
  }) do
    entity.destroy()
  end

  local force = game.forces.player
  local initial_technology = force.technologies[INITIAL_TECH]
  check(initial_technology ~= nil, "missing initial pneumatic technology")
  if not initial_technology then finish() return end
  initial_technology.researched = false
  check(force.recipes[RECIPE] and not force.recipes[RECIPE].enabled,
    "metallurgic-pack recipe was enabled before Pneumatic Technology")
  research_closure(initial_technology, {})
  check(initial_technology.researched,
    "failed to research initial pneumatic technology")
  check(force.recipes[RECIPE] and force.recipes[RECIPE].enabled,
    "metallurgic-pack recipe requires research beyond the declared closure")

  local ghost = surface.create_entity{
    name = "entity-ghost",
    inner_name = MACHINE,
    position = MACHINE_POSITION,
    direction = defines.direction.north,
    force = force,
    expires = false,
  }
  check(ghost ~= nil, "failed to create pneumatic assembler ghost")
  if not ghost then finish() return end
  local _, machine = ghost.revive{raise_revive = true}
  check(machine ~= nil, "failed to build pneumatic assembler")
  if not machine then finish() return end
  storage.machine = machine
  machine.active = false

  local fluid_source = machine.prototype.fluid_energy_source_prototype
  check(fluid_source ~= nil, "pneumatic assembler has no fluid energy source")
  check(machine.prototype.heat_energy_source_prototype == nil,
    "pneumatic assembler unexpectedly requires heat")
  if not fluid_source then finish() return end

  local recipe_set = machine.set_recipe(RECIPE)
  check(recipe_set, "failed to set metallurgic-pack recipe")
  local recipe = machine.get_recipe()
  check(recipe and recipe.name == RECIPE,
    "pneumatic assembler has the wrong recipe")
  if not recipe_set or not recipe or recipe.name ~= RECIPE then finish() return end
  check(close(recipe.energy * 60, RECIPE_TICKS),
    "runtime metallurgic-pack recipe duration differs from the matrix")
  check(close(recipe.energy * 60 / machine.crafting_speed, CRAFT_TICKS),
    "runtime assembler craft duration differs from the matrix")
  for name, amount in pairs(INPUTS) do
    check(item_amount(recipe.ingredients, name) == amount,
      "runtime recipe input mismatch for " .. name)
  end
  check(item_amount(recipe.products, PACK) == 1,
    "runtime metallurgic-pack output differs from the matrix")

  local energy_per_cycle = machine.prototype.get_max_energy_usage() *
    recipe.energy * 60 / machine.crafting_speed
  local required_gas = energy_per_cycle /
    (prototypes.fluid[GAS].fuel_value * fluid_source.effectivity)
  observations.runtime = {
    crafting_speed = machine.crafting_speed,
    recipe_ticks = recipe.energy * 60,
    craft_ticks = recipe.energy * 60 / machine.crafting_speed,
    maximum_energy_usage = machine.prototype.get_max_energy_usage(),
    energy_per_cycle = energy_per_cycle,
    gas_fuel_value = prototypes.fluid[GAS].fuel_value,
    fuel_effectivity = fluid_source.effectivity,
    gas_per_cycle = required_gas,
    fluidbox_count = #machine.fluidbox,
    fluidbox_filters = {},
  }
  check(close(required_gas, GAS_INPUT),
    "runtime pneumatic fuel demand differs from the manifest")

  local gas_box = nil
  for index = 1, #machine.fluidbox do
    local filter = machine.fluidbox.get_filter(index)
    observations.runtime.fluidbox_filters[index] = filter and filter.name or false
    if filter and filter.name == GAS then
      check(gas_box == nil, "pneumatic assembler has multiple gas energy boxes")
      gas_box = index
    end
  end
  if not gas_box and #machine.fluidbox == 1 then
    check(machine.fluidbox.get_filter(1) == nil,
      "unfiltered pneumatic energy box unexpectedly has a recipe filter")
    gas_box = 1
  end
  check(gas_box ~= nil, "pneumatic assembler has no compressed-gas energy box")
  if not gas_box then finish() return end
  local connection = machine.fluidbox.get_pipe_connections(gas_box)[1]
  check(connection ~= nil, "compressed-gas energy box has no pipe connection")
  if not connection then finish() return end
  local delta_x = connection.target_position.x - machine.position.x
  local delta_y = connection.target_position.y - machine.position.y
  local vector
  if math.abs(delta_x) > math.abs(delta_y) then
    vector = {delta_x > 0 and 1 or -1, 0}
  else
    vector = {0, delta_y > 0 and 1 or -1}
  end
  storage.gas_entities = {}
  for distance = 0, 3 do
    local gas_pipe = surface.create_entity{
      name = "pipe",
      position = {
        connection.target_position.x + vector[1] * distance,
        connection.target_position.y + vector[2] * distance,
      },
      force = force,
    }
    check(gas_pipe ~= nil, "failed to build compressed-gas input pipe")
    if not gas_pipe then finish() return end
    storage.gas_entities[#storage.gas_entities + 1] = gas_pipe
  end
  local inserted_gas = storage.gas_entities[#storage.gas_entities].insert_fluid{
    name = GAS,
    amount = GAS_INPUT,
    temperature = prototypes.fluid[GAS].default_temperature,
  }
  check(close(inserted_gas, GAS_INPUT),
    "failed to insert exactly 354 compressed volcanic gas")
  check(close(gas_total(), GAS_INPUT),
    "gas fixture did not contain exactly 354 compressed volcanic gas")

  local input_inventory = machine.get_inventory(
    defines.inventory.assembling_machine_input)
  check(input_inventory ~= nil, "pneumatic assembler has no input inventory")
  if not input_inventory then finish() return end
  storage.input_inventory = input_inventory
  for name, amount in pairs(INPUTS) do
    check(input_inventory.insert{name = name, count = amount} == amount,
      "failed to insert exact input " .. name)
    check(input_inventory.get_item_count(name) == amount,
      "assembler input mismatch for " .. name)
  end

  observations.runtime.gas_fluidbox = gas_box
  if #failures > 0 then finish() return end
  script.on_nth_tick(60, start_machine)
end

script.on_nth_tick(1, setup)

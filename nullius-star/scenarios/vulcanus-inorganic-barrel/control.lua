local CASE = "vulcanus-inorganic-barrel"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local MACHINE = "nullius-small-assembler-1-pneumatic"
local RECIPE = "nullius-vulcanus-barrel"
local GAS = "nullius-compressed-volcanic-gas"
local INITIAL_TECH = "nullius-pneumatic-technology"
local POSITION = {20, 0}
local TERMINAL_TICK = 1250
local INPUTS = {
  ["nullius-steel-sheet"] = 2,
  ["nullius-aluminum-sheet"] = 2,
  ["nullius-glass"] = 1,
  ["nullius-one-way-valve"] = 1,
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

local function research_closure(technology, visited)
  if visited[technology.name] then return end
  visited[technology.name] = true
  for _, prerequisite in pairs(technology.prerequisites) do
    research_closure(prerequisite, visited)
  end
  technology.researched = true
end

local function item_amount(entries, name)
  for _, entry in pairs(entries) do
    if entry.name == name then return entry.amount end
  end
  return 0
end

local function check_terminal()
  script.on_nth_tick(TERMINAL_TICK, nil)
  local output = storage.machine.get_output_inventory()
  local input = storage.machine.get_inventory(
    defines.inventory.assembling_machine_input)
  observations.terminal = {
    cycles = storage.machine.products_finished,
    barrels = output and output.get_item_count("barrel") or 0,
    remaining_inputs = input and input.get_contents() or {},
    gas = storage.machine.get_fluid_count(GAS) +
      storage.pipe.get_fluid_count(GAS),
  }
  check(storage.machine.products_finished == 1,
    "assembler did not complete exactly one inorganic barrel cycle")
  check(output and output.get_item_count("barrel") == 3,
    "inorganic barrel cycle did not produce exactly three barrels")
  check(close(observations.terminal.gas, 0),
    "inorganic barrel cycle did not consume exactly 59 compressed gas")
  for name in pairs(INPUTS) do
    check(input and input.get_item_count(name) == 0,
      "assembler retained input " .. name)
  end
  finish()
end

local function setup()
  script.on_nth_tick(1, nil)
  local planet = game.planets["nullius-vulcanus"]
  check(planet ~= nil, "missing nullius-vulcanus planet")
  if not planet then finish() return end
  local surface = planet.surface or planet.create_surface()
  surface.request_to_generate_chunks(POSITION, 1)
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
  local technology = force.technologies[INITIAL_TECH]
  check(technology ~= nil, "missing Pneumatic Technology")
  if not technology then finish() return end
  technology.researched = false
  check(force.recipes[RECIPE] and not force.recipes[RECIPE].enabled,
    "inorganic barrel recipe was enabled before Pneumatic Technology")
  research_closure(technology, {})
  check(force.recipes[RECIPE] and force.recipes[RECIPE].enabled,
    "Pneumatic Technology did not unlock the inorganic barrel recipe")

  local ghost = surface.create_entity{
    name = "entity-ghost",
    inner_name = MACHINE,
    position = POSITION,
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
  check(machine.set_recipe(RECIPE), "failed to set inorganic barrel recipe")
  local recipe = machine.get_recipe()
  check(recipe and recipe.name == RECIPE, "assembler selected the wrong recipe")
  if not recipe or recipe.name ~= RECIPE then finish() return end
  check(recipe.energy == 10, "inorganic barrel recipe duration is not 10 seconds")
  for name, amount in pairs(INPUTS) do
    check(item_amount(recipe.ingredients, name) == amount,
      "inorganic barrel input mismatch for " .. name)
  end
  check(item_amount(recipe.ingredients, "nullius-plastic") == 0,
    "inorganic barrel recipe consumes plastic")
  check(item_amount(recipe.ingredients, "nullius-rubber") == 0,
    "inorganic barrel recipe consumes rubber")
  check(item_amount(recipe.products, "barrel") == 3,
    "inorganic barrel recipe output is not three barrels")

  local gas_box = nil
  for index = 1, #machine.fluidbox do
    local filter = machine.fluidbox.get_filter(index)
    if filter and filter.name == GAS then gas_box = index end
  end
  if not gas_box and #machine.fluidbox == 1 then gas_box = 1 end
  check(gas_box ~= nil, "pneumatic assembler has no gas energy box")
  if not gas_box then finish() return end
  local connection = machine.fluidbox.get_pipe_connections(gas_box)[1]
  check(connection ~= nil, "gas energy box has no pipe connection")
  if not connection then finish() return end
  local pipe = surface.create_entity{
    name = "pipe",
    position = connection.target_position,
    force = force,
  }
  check(pipe ~= nil, "failed to connect gas input pipe")
  if not pipe then finish() return end
  storage.pipe = pipe
  check(pipe.insert_fluid{name = GAS, amount = 59} == 59,
    "failed to supply compressed volcanic gas")

  local input = machine.get_inventory(defines.inventory.assembling_machine_input)
  check(input ~= nil, "pneumatic assembler has no input inventory")
  if not input then finish() return end
  for name, amount in pairs(INPUTS) do
    check(input.insert{name = name, count = amount} == amount,
      "failed to insert exact input " .. name)
  end
  observations.recipe = {
    ingredients = recipe.ingredients,
    products = recipe.products,
    crafting_speed = machine.crafting_speed,
    recipe_seconds = recipe.energy,
  }
  if #failures > 0 then finish() return end
  machine.active = true
  script.on_nth_tick(TERMINAL_TICK, check_terminal)
end

script.on_nth_tick(1, setup)

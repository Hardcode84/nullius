local CASE = "vulcanus-refractory-production"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local TECHNOLOGY = "nullius-vulcanus-refractory-engineering"
local GAS = "nullius-compressed-volcanic-gas"
local RECIPES = {
  "nullius-refractory-mix-vulcanus",
  "nullius-refractory-brick-vulcanus",
  "nullius-heat-pipe-2-vulcanus",
  "nullius-vulcanus-radiator-2-refractory",
}

local assertions = 0
local failures = {}
local observations = {}

local function close(actual, expected)
  return math.abs(actual - expected) < 0.000001
end

local function check(condition, message)
  assertions = assertions + 1
  if not condition then failures[#failures + 1] = message end
  return condition
end

local function finish()
  script.on_nth_tick(30, nil)
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

local function named_amounts(entries)
  local result = {}
  for _, entry in pairs(entries) do result[entry.name] = entry.amount end
  return result
end

local function names(entries)
  local result = {}
  for _, entry in pairs(entries) do
    result[type(entry) == "string" and entry or entry.name] = true
  end
  return result
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
    force = game.forces.player,
    expires = false,
  }
  if not check(ghost ~= nil, "failed to create ghost for " .. name) then
    return nil
  end
  local _, entity = ghost.revive{raise_revive = true}
  check(entity ~= nil, "failed to build " .. name)
  return entity
end

local function fuel(surface, machine, amount)
  local gas_box = nil
  for index = 1, #machine.fluidbox do
    local filter = machine.fluidbox.get_filter(index)
    if filter and filter.name == GAS then gas_box = index end
    if not filter and not gas_box then gas_box = index end
  end
  if not check(gas_box ~= nil, machine.name .. " has no gas box") then
    return false
  end
  local connection = machine.fluidbox.get_pipe_connections(gas_box)[1]
  if not check(connection ~= nil, machine.name .. " gas box is disconnected") then
    return false
  end
  local pipe = surface.create_entity{
    name = "pipe",
    position = connection.target_position,
    force = game.forces.player,
  }
  if not check(pipe ~= nil, "failed to place gas pipe for " .. machine.name) then
    return false
  end
  check(close(pipe.insert_fluid{name = GAS, amount = amount}, amount),
    "failed to fuel " .. machine.name)
  return true
end

local function inventory(machine, index)
  local result = machine.get_inventory(index)
  check(result ~= nil, machine.name .. " has no required inventory")
  return result
end

local function insert_items(machine, items)
  local input = inventory(machine, defines.inventory.assembling_machine_input)
  if not input then return false end
  for name, amount in pairs(items) do
    check(input.insert{name = name, count = amount} == amount,
      "failed to insert " .. name .. " into " .. machine.name)
  end
  return true
end

local function set_recipe(machine, recipe_name)
  machine.active = false
  check(machine.set_recipe(recipe_name), "failed to set " .. recipe_name)
  local recipe = machine.get_recipe()
  check(recipe and recipe.name == recipe_name,
    machine.name .. " selected the wrong recipe")
  return recipe
end

local function start_infrastructure()
  local brick_output = storage.furnace.get_output_inventory()
  check(brick_output.remove{name = "nullius-refractory-brick", count = 8} == 8,
    "failed to transfer fired refractory bricks")

  insert_items(storage.foundry, {
    ["nullius-heat-pipe-1"] = 1,
    ["nullius-pipe-2"] = 2,
    ["nullius-aluminum-sheet"] = 4,
    ["nullius-refractory-brick"] = 4,
    ["nullius-silicon-insulation"] = 2,
    ["nullius-eutectic-salt"] = 5,
  })
  insert_items(storage.radiator_assembler, {
    ["nullius-vulcanus-radiator-1"] = 1,
    ["nullius-aluminum-sheet"] = 4,
    ["nullius-refractory-brick"] = 4,
    ["nullius-heat-pipe-1"] = 1,
    ["nullius-pipe-2"] = 4,
  })
  storage.foundry.active = true
  storage.radiator_assembler.active = true
  storage.stage = "infrastructure"
  observations.infrastructure_started = game.tick
end

local function terminal_check()
  local brick_output = storage.furnace.get_output_inventory()
  local heat_output = storage.foundry.get_output_inventory()
  local radiator_output = storage.radiator_assembler.get_output_inventory()
  observations.terminal = {
    bricks = brick_output.get_item_count("nullius-refractory-brick"),
    heat_pipes = heat_output.get_item_count("nullius-heat-pipe-2"),
    radiators = radiator_output.get_item_count("nullius-vulcanus-radiator-2"),
    mix_cycles = storage.mixer.products_finished,
    firing_cycles = storage.furnace.products_finished,
    heat_pipe_cycles = storage.foundry.products_finished,
    radiator_cycles = storage.radiator_assembler.products_finished,
  }
  check(observations.terminal.bricks == 22,
    "refractory chain did not retain exactly 22 bricks")
  check(observations.terminal.heat_pipes == 2,
    "refractory heat-pipe recipe did not produce two heat pipes")
  check(observations.terminal.radiators == 1,
    "refractory radiator recipe did not produce one radiator")
  check(storage.mixer.products_finished == 1,
    "refractory mixer completed an unexpected cycle count")
  check(storage.furnace.products_finished == 1,
    "refractory furnace completed an unexpected cycle count")
  check(storage.foundry.products_finished == 1,
    "heat-pipe foundry completed an unexpected cycle count")
  check(storage.radiator_assembler.products_finished == 1,
    "radiator assembler completed an unexpected cycle count")
  finish()
end

local function poll()
  if storage.stage == "mix" and storage.mixer.products_finished == 1 then
    local output = storage.mixer.get_output_inventory()
    check(output.remove{name = "nullius-refractory-mix", count = 10} == 10,
      "failed to transfer refractory mix")
    insert_items(storage.furnace, { ["nullius-refractory-mix"] = 10 })
    storage.furnace.temperature = 500
    storage.furnace.active = true
    storage.stage = "fire"
    observations.firing_started = game.tick
  elseif storage.stage == "fire" and
      storage.furnace.products_finished == 1 then
    start_infrastructure()
  elseif storage.stage == "infrastructure" and
      storage.foundry.products_finished == 1 and
      storage.radiator_assembler.products_finished == 1 then
    terminal_check()
    return
  end

  if game.tick >= 3450 then
    check(false, "refractory production did not finish before tick 3450")
    finish()
  end
end

local function setup()
  script.on_nth_tick(1, nil)
  local planet = game.planets["nullius-vulcanus"]
  if not check(planet ~= nil, "missing nullius-vulcanus planet") then
    finish()
    return
  end
  local surface = planet.surface or planet.create_surface()
  surface.request_to_generate_chunks({20, 0}, 2)
  surface.force_generate_chunk_requests()
  local tiles = {}
  for x = 0, 48 do
    for y = -10, 10 do
      tiles[#tiles + 1] = {name = "volcanic-soil-dark", position = {x, y}}
    end
  end
  surface.set_tiles(tiles, true, false, false, false)
  for _, entity in ipairs(surface.find_entities_filtered{
      area = {{0, -10}, {48, 10}},
      type = {"simple-entity", "tree", "cliff", "resource"},
  }) do
    entity.destroy()
  end

  local force = game.forces.player
  local technology = force.technologies[TECHNOLOGY]
  if not check(technology ~= nil, "missing refractory engineering technology") then
    finish()
    return
  end
  check(technology.research_unit_count == 10,
    "refractory engineering has the wrong unit count")
  check(technology.research_unit_energy == 2700,
    "refractory engineering has the wrong unit time")
  check_exact(named_amounts(technology.prototype.research_unit_ingredients), {
    ["nullius-metallurgic-pack"] = 40,
    ["nullius-geology-pack"] = 4,
    ["nullius-chemical-pack"] = 4,
  }, "research ingredients")
  check_exact(names(technology.prerequisites), {
    ["nullius-hot-metalworking"] = true,
    ["nullius-ceramics"] = true,
    ["nullius-thermal-storage-2"] = true,
  }, "research prerequisites")
  technology.researched = false
  for _, recipe_name in ipairs(RECIPES) do
    check(force.recipes[recipe_name] and not force.recipes[recipe_name].enabled,
      recipe_name .. " was enabled before refractory engineering")
  end
  research_closure(technology, {})
  for _, recipe_name in ipairs(RECIPES) do
    check(force.recipes[recipe_name] and force.recipes[recipe_name].enabled,
      recipe_name .. " was not unlocked by refractory engineering")
  end

  storage.mixer = build(surface, "nullius-medium-assembler-1-pneumatic", {8, 0})
  storage.furnace = build(surface, "nullius-small-furnace-2-pneumatic", {20, 0})
  storage.foundry = build(surface, "nullius-foundry-1-pneumatic", {32, -4})
  storage.radiator_assembler = build(
    surface, "nullius-medium-assembler-1-pneumatic", {32, 4})
  if #failures > 0 then finish() return end

  local mix_recipe = set_recipe(storage.mixer,
    "nullius-refractory-mix-vulcanus")
  local brick_recipe = set_recipe(storage.furnace,
    "nullius-refractory-brick-vulcanus")
  local heat_recipe = set_recipe(storage.foundry,
    "nullius-heat-pipe-2-vulcanus")
  local radiator_recipe = set_recipe(storage.radiator_assembler,
    "nullius-vulcanus-radiator-2-refractory")
  check_exact(named_amounts(mix_recipe.ingredients), {
    ["nullius-alumina"] = 5,
    ["nullius-silica"] = 8,
    ["nullius-mineral-dust"] = 12,
  }, "refractory mix ingredients")
  check_exact(named_amounts(brick_recipe.ingredients), {
    ["nullius-refractory-mix"] = 10,
  }, "refractory firing ingredients")
  check(named_amounts(brick_recipe.products)["nullius-refractory-brick"] == 30,
    "refractory firing output is not 30 bricks")
  check(named_amounts(heat_recipe.ingredients)["nullius-insulation"] == nil,
    "Vulcanus heat pipe still consumes organic insulation")
  check(named_amounts(heat_recipe.ingredients)["nullius-pipe-3"] == nil,
    "Vulcanus heat pipe still consumes epoxy pipe 3")
  check(named_amounts(radiator_recipe.ingredients)["nullius-refractory-brick"] == 4,
    "refractory radiator does not consume four bricks")

  insert_items(storage.mixer, {
    ["nullius-alumina"] = 5,
    ["nullius-silica"] = 8,
    ["nullius-mineral-dust"] = 12,
  })
  fuel(surface, storage.mixer, 86.4)
  fuel(surface, storage.foundry, 45)
  fuel(surface, storage.radiator_assembler, 72)
  if #failures > 0 then finish() return end
  storage.mixer.active = true
  storage.stage = "mix"
  observations.mix_started = game.tick
  script.on_nth_tick(30, poll)
end

script.on_nth_tick(1, setup)

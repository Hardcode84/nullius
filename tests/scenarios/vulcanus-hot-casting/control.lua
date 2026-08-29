local CASE = "vulcanus-hot-casting"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local TECHNOLOGY = "nullius-hot-metalworking"
local MACHINE = "nullius-foundry-1-pneumatic"
local GAS = "nullius-compressed-volcanic-gas"
local CASES = {
  {
    recipe = "nullius-hot-iron-plate",
    input = "nullius-molten-iron-bloom",
    input_count = 4,
    output = "nullius-iron-plate",
    output_count = 3,
    spoil_result = "nullius-iron-ingot",
    spoil_ticks = 1800,
    seconds = 3,
  },
  {
    recipe = "nullius-hot-iron-rod",
    input = "nullius-molten-iron-bloom",
    input_count = 4,
    output = "nullius-iron-rod",
    output_count = 5,
    spoil_result = "nullius-iron-ingot",
    spoil_ticks = 1800,
    seconds = 4,
  },
  {
    recipe = "nullius-hot-aluminum-sheet",
    input = "nullius-molten-aluminum-bloom",
    input_count = 4,
    output = "nullius-aluminum-sheet",
    output_count = 5,
    spoil_result = "nullius-alumina",
    spoil_ticks = 2400,
    seconds = 4,
  },
  {
    recipe = "nullius-hot-aluminum-rod",
    input = "nullius-molten-aluminum-bloom",
    input_count = 4,
    output = "nullius-aluminum-rod",
    output_count = 5,
    spoil_result = "nullius-alumina",
    spoil_ticks = 2400,
    seconds = 4,
  },
}

local assertions = 0
local failures = {}
local observations = {}

local function check(condition, message)
  assertions = assertions + 1
  if not condition then failures[#failures + 1] = message end
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
  check(ghost ~= nil, "failed to create ghost for " .. name)
  if not ghost then return nil end
  local _, entity = ghost.revive{raise_revive = true}
  check(entity ~= nil, "failed to build " .. name)
  return entity
end

local function connect_gas(surface, machine)
  local gas_box = nil
  for index = 1, #machine.fluidbox do
    local filter = machine.fluidbox.get_filter(index)
    if filter and filter.name == GAS then gas_box = index end
    if not filter and not gas_box then gas_box = index end
  end
  check(gas_box ~= nil, machine.name .. " has no volcanic-gas energy box")
  if not gas_box then return nil end
  local connection = machine.fluidbox.get_pipe_connections(gas_box)[1]
  check(connection ~= nil, machine.name .. " gas box has no pipe connection")
  if not connection then return nil end
  local pipe = surface.create_entity{
    name = "pipe",
    position = connection.target_position,
    force = game.forces.player,
  }
  check(pipe ~= nil, "failed to connect gas pipe to " .. machine.name)
  if not pipe then return nil end
  check(pipe.insert_fluid{name = GAS, amount = 100} == 100,
    "failed to fuel " .. machine.name)
  return pipe
end

local function terminal_check()
  script.on_nth_tick(storage.terminal_tick, nil)
  observations.terminal = {}
  for index, expected in ipairs(CASES) do
    local machine = storage.machines[index]
    local input = machine.get_inventory(
      defines.inventory.assembling_machine_input)
    local output = machine.get_output_inventory()
    observations.terminal[expected.recipe] = {
      cycles = machine.products_finished,
      input = input.get_contents(),
      output = output.get_contents(),
    }
    check(machine.products_finished == 1,
      expected.recipe .. " did not complete exactly one cycle")
    check(output.get_item_count(expected.output) == expected.output_count,
      expected.recipe .. " produced the wrong output count")
    check(input.get_item_count(expected.input) == 0,
      expected.recipe .. " retained molten blooms")
    check(input.get_item_count(expected.spoil_result) == 0,
      expected.recipe .. " allowed its input to spoil")
    check(output.get_item_count(expected.spoil_result) == 0,
      expected.recipe .. " emitted its spoil result")
  end
  finish()
end

local function setup()
  script.on_nth_tick(1, nil)
  local planet = game.planets["nullius-vulcanus"]
  check(planet ~= nil, "missing nullius-vulcanus planet")
  if not planet then finish() return end
  local surface = planet.surface or planet.create_surface()
  surface.request_to_generate_chunks({20, 0}, 2)
  surface.force_generate_chunk_requests()
  local tiles = {}
  for x = 0, 48 do
    for y = -8, 8 do
      tiles[#tiles + 1] = {name = "volcanic-soil-dark", position = {x, y}}
    end
  end
  surface.set_tiles(tiles, true, false, false, false)
  for _, entity in ipairs(surface.find_entities_filtered{
      area = {{0, -8}, {48, 8}},
      type = {"simple-entity", "tree", "cliff", "resource"},
  }) do
    entity.destroy()
  end

  local force = game.forces.player
  local technology = force.technologies[TECHNOLOGY]
  check(technology ~= nil, "missing hot metalworking technology")
  if not technology then finish() return end
  check(technology.research_unit_count == 10,
    "hot metalworking has the wrong unit count")
  check(technology.research_unit_energy == 1800,
    "hot metalworking has the wrong unit time")
  check_exact(named_amounts(technology.prototype.research_unit_ingredients), {
    ["nullius-metallurgic-pack"] = 10,
    ["nullius-mechanical-pack"] = 1,
  }, "research ingredients")
  check_exact(names(technology.prerequisites), {
    ["nullius-efficient-metallurgic-science"] = true,
    ["nullius-aluminum-working-1"] = true,
  }, "research prerequisites")

  technology.researched = false
  for _, expected in ipairs(CASES) do
    check(force.recipes[expected.recipe] ~= nil,
      "missing recipe " .. expected.recipe)
    check(not force.recipes[expected.recipe].enabled,
      expected.recipe .. " was enabled before hot metalworking")
  end
  research_closure(technology, {})

  storage.machines = {}
  local max_craft_ticks = 0
  observations.runtime = {}
  for index, expected in ipairs(CASES) do
    local recipe = force.recipes[expected.recipe]
    check(recipe.enabled, expected.recipe .. " was not unlocked")
    check(recipe.category == "machine-casting",
      expected.recipe .. " has the wrong category")
    check(recipe.energy == expected.seconds,
      expected.recipe .. " has the wrong duration")
    check_exact(named_amounts(recipe.ingredients), {
      [expected.input] = expected.input_count,
    }, expected.recipe .. " ingredients")
    check_exact(named_amounts(recipe.products), {
      [expected.output] = expected.output_count,
    }, expected.recipe .. " products")

    local machine = build(surface, MACHINE, {index * 10, 0})
    if not machine then finish() return end
    storage.machines[index] = machine
    machine.active = false
    check(machine.set_recipe(expected.recipe),
      "failed to set " .. expected.recipe)
    local input = machine.get_inventory(
      defines.inventory.assembling_machine_input)
    check(input.insert{name = expected.input, count = expected.input_count} ==
      expected.input_count, "failed to insert inputs for " .. expected.recipe)
    if not connect_gas(surface, machine) then finish() return end
    local craft_ticks = math.ceil(recipe.energy * 60 / machine.crafting_speed)
    local spoil_ticks = expected.spoil_ticks
    check(craft_ticks < spoil_ticks,
      expected.recipe .. " cannot finish before its bloom spoils")
    observations.runtime[expected.recipe] = {
      craft_ticks = craft_ticks,
      spoil_ticks = spoil_ticks,
    }
    max_craft_ticks = math.max(max_craft_ticks, craft_ticks)
    machine.active = true
  end

  storage.terminal_tick = game.tick + max_craft_ticks + 3
  script.on_nth_tick(storage.terminal_tick, terminal_check)
end

script.on_nth_tick(1, setup)

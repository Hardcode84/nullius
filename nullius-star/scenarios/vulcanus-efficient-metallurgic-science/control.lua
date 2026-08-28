local CASE = "vulcanus-efficient-metallurgic-science"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local TECHNOLOGY = "nullius-efficient-metallurgic-science"
local RECIPE = "nullius-metallurgic-pack-efficient"
local CHLORINE_RECIPE = "nullius-chlorine-barrel"
local SO2_RECIPE = "nullius-sulfur-dioxide-barrel"
local MACHINE = "nullius-medium-assembler-1-pneumatic"
local BARREL_PUMP = "nullius-barrel-pump-1-pneumatic"
local GAS = "nullius-compressed-volcanic-gas"
local PACK = "nullius-metallurgic-pack"
local INPUTS = {
  ["nullius-molten-iron-bloom"] = 2,
  ["nullius-molten-aluminum-bloom"] = 2,
  ["nullius-crucible"] = 1,
  ["nullius-chlorine-barrel"] = 1,
  ["nullius-sulfur-dioxide-barrel"] = 1,
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

local function expected_item_amount(entries, name)
  local result = 0
  for _, entry in pairs(entries) do
    if entry.name == name then
      result = result + entry.amount * (entry.probability or 1)
    end
  end
  return result
end

local function expected_ignored_productivity(entries, name)
  local result = 0
  for _, entry in pairs(entries) do
    if entry.name == name then
      result = result + (entry.ignored_by_productivity or 0) *
        (entry.probability or 1)
    end
  end
  return result
end

local function status_name(status)
  for name, value in pairs(defines.entity_status) do
    if value == status then return name end
  end
  return tostring(status)
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

local function inventory(entity, index)
  local result = entity.get_inventory(index)
  check(result ~= nil, entity.name .. " is missing an inventory")
  return result
end

local function check_terminal()
  script.on_nth_tick(storage.terminal_tick, nil)
  local output = storage.assembler.get_output_inventory()
  local input = storage.assembler.get_inventory(
    defines.inventory.assembling_machine_input)
  local gas = storage.assembler.get_fluid_count(GAS) +
    storage.gas_pipe.get_fluid_count(GAS)
  observations.terminal = {
    cycles = storage.assembler.products_finished,
    packs = output and output.get_item_count(PACK) or 0,
    barrels = output and output.get_item_count("barrel") or 0,
    gas = gas,
    input = input and input.get_contents() or {},
  }
  check(storage.assembler.products_finished == 1,
    "efficient assembler did not complete exactly one cycle")
  check(output and output.get_item_count(PACK) == 5,
    "efficient recipe did not produce five metallurgic packs")
  local returned_barrels = output and output.get_item_count("barrel") or 0
  check(returned_barrels == 1 or returned_barrels == 2,
    "efficient recipe returned an invalid number of barrels")
  check(close(gas, 0),
    "efficient recipe did not consume exactly 108 compressed gas")
  for name in pairs(INPUTS) do
    check(input and input.get_item_count(name) == 0,
      "efficient assembler retained " .. name)
  end
  check(input and input.get_item_count("nullius-iron-ingot") == 0,
    "hot iron blooms spoiled before the recipe completed")
  check(input and input.get_item_count("nullius-alumina") == 0,
    "hot aluminum blooms spoiled before the recipe completed")
  finish()
end

local function start_efficient_recipe()
  script.on_nth_tick(20, nil)
  local surface = storage.surface
  local chlorine_output = storage.chlorine_pump.get_output_inventory()
  local so2_output = storage.so2_pump.get_output_inventory()
  observations.barrel_pumps = {}
  for name, pump in pairs{
    chlorine = storage.chlorine_pump,
    sulfur_dioxide = storage.so2_pump,
  } do
    observations.barrel_pumps[name] = {
      status = status_name(pump.status),
      progress = pump.crafting_progress,
      cycles = pump.products_finished,
      fluids = pump.get_fluid_contents(),
      input = pump.get_inventory(
        defines.inventory.assembling_machine_input).get_contents(),
    }
  end
  check(storage.chlorine_pump.products_finished == 1,
    "pneumatic barrel pump did not fill chlorine")
  check(storage.so2_pump.products_finished == 1,
    "pneumatic barrel pump did not fill sulfur dioxide")
  check(chlorine_output and
    chlorine_output.get_item_count("nullius-chlorine-barrel") == 1,
    "chlorine barrel was not produced")
  check(so2_output and
    so2_output.get_item_count("nullius-sulfur-dioxide-barrel") == 1,
    "sulfur dioxide barrel was not produced")
  if #failures > 0 then finish() return end

  local assembler = build(surface, MACHINE, {20, 0})
  if not assembler then finish() return end
  storage.assembler = assembler
  assembler.active = false
  check(assembler.set_recipe(RECIPE), "failed to set efficient recipe")
  local recipe = assembler.get_recipe()
  check(recipe and recipe.name == RECIPE, "efficient assembler has wrong recipe")
  if not recipe then finish() return end
  check(close(recipe.energy, 15), "efficient recipe is not 15 seconds")
  for name, amount in pairs(INPUTS) do
    check(item_amount(recipe.ingredients, name) == amount,
      "efficient recipe input mismatch for " .. name)
  end
  check(item_amount(recipe.products, PACK) == 5,
    "efficient recipe pack output mismatch")
  check(close(expected_item_amount(recipe.products, "barrel"), 1.9),
    "efficient recipe expected barrel return is not 1.9")
  check(close(expected_ignored_productivity(recipe.products, "barrel"), 1.9),
    "efficient recipe allows productivity to duplicate returned barrels")

  local input = inventory(assembler,
    defines.inventory.assembling_machine_input)
  if not input then finish() return end
  check(input.insert{name = "nullius-molten-iron-bloom", count = 2} == 2,
    "failed to insert hot iron blooms")
  check(input.insert{name = "nullius-molten-aluminum-bloom", count = 2} == 2,
    "failed to insert hot aluminum blooms")
  check(input.insert{name = "nullius-crucible", count = 1} == 1,
    "failed to insert crucible")
  check(input.insert{
    name = "nullius-chlorine-barrel", count = 1,
  } == 1, "failed to transfer chlorine barrel")
  check(input.insert{
    name = "nullius-sulfur-dioxide-barrel", count = 1,
  } == 1, "failed to transfer sulfur dioxide barrel")

  local gas_box = nil
  for index = 1, #assembler.fluidbox do
    local filter = assembler.fluidbox.get_filter(index)
    if filter and filter.name == GAS then gas_box = index end
  end
  if not gas_box and #assembler.fluidbox == 1 then gas_box = 1 end
  check(gas_box ~= nil, "efficient assembler has no gas energy box")
  if not gas_box then finish() return end
  local connection = assembler.fluidbox.get_pipe_connections(gas_box)[1]
  local gas_pipe = surface.create_entity{
    name = "pipe",
    position = connection.target_position,
    force = game.forces.player,
  }
  check(gas_pipe ~= nil, "failed to connect efficient assembler gas")
  if not gas_pipe then finish() return end
  storage.gas_pipe = gas_pipe
  check(gas_pipe.insert_fluid{name = GAS, amount = 108} == 108,
    "failed to supply exact efficient-recipe gas")

  observations.runtime = {
    crafting_speed = assembler.crafting_speed,
    craft_ticks = recipe.energy * 60 / assembler.crafting_speed,
    iron_spoil_ticks = 1800,
    aluminum_spoil_ticks = 2400,
  }
  check(observations.runtime.craft_ticks < observations.runtime.iron_spoil_ticks,
    "efficient recipe cannot finish before iron bloom spoils")
  check(observations.runtime.craft_ticks <
    observations.runtime.aluminum_spoil_ticks,
    "efficient recipe cannot finish before aluminum bloom spoils")
  assembler.active = true
  storage.terminal_tick = game.tick + observations.runtime.craft_ticks + 2
  script.on_nth_tick(storage.terminal_tick, check_terminal)
end

local function prepare_barrel_pump(surface, position, recipe_name, fluid_name)
  local pump = build(surface, BARREL_PUMP, position)
  if not pump then return nil end
  pump.active = false
  check(pump.set_recipe(recipe_name), "failed to set " .. recipe_name)
  local input = inventory(pump, defines.inventory.assembling_machine_input)
  if not input then return nil end
  check(input.insert{name = "barrel", count = 1} == 1,
    "failed to insert barrel for " .. fluid_name)
  local ingredient_box = nil
  for index = 1, #pump.fluidbox do
    local filter = pump.fluidbox.get_filter(index)
    if filter and filter.name == fluid_name then
      check(ingredient_box == nil,
        "barrel pump has multiple input boxes for " .. fluid_name)
      ingredient_box = index
    end
  end
  check(ingredient_box ~= nil,
    "barrel pump has no recipe input box for " .. fluid_name)
  if not ingredient_box then return nil end
  pump.fluidbox[ingredient_box] = {
    name = fluid_name,
    amount = 100,
    temperature = prototypes.fluid[fluid_name].default_temperature,
  }
  check(pump.get_fluid_count(fluid_name) == 100,
    "failed to fill recipe input box with " .. fluid_name)
  local gas_pipe = nil
  for index = 1, #pump.fluidbox do
    for _, connection in ipairs(
        pump.fluidbox.get_pipe_connections(index)) do
      local candidate = surface.create_entity{
        name = "pipe",
        position = connection.target_position,
        force = game.forces.player,
      }
      if candidate then
        local inserted = candidate.insert_fluid{name = GAS, amount = 1}
        if inserted == 1 then
          gas_pipe = candidate
          break
        end
        candidate.destroy()
      end
    end
    if gas_pipe then break end
  end
  check(gas_pipe ~= nil, "failed to fuel barrel pump for " .. fluid_name)
  if not gas_pipe then return nil end
  pump.active = true
  return pump
end

local function setup()
  script.on_nth_tick(1, nil)
  local planet = game.planets["nullius-vulcanus"]
  check(planet ~= nil, "missing nullius-vulcanus planet")
  if not planet then finish() return end
  local surface = planet.surface or planet.create_surface()
  storage.surface = surface
  surface.request_to_generate_chunks({20, 0}, 1)
  surface.force_generate_chunk_requests()
  local tiles = {}
  for x = 0, 32 do
    for y = -12, 12 do
      tiles[#tiles + 1] = {name = "volcanic-soil-dark", position = {x, y}}
    end
  end
  surface.set_tiles(tiles, true, false, false, false)
  for _, entity in ipairs(surface.find_entities_filtered{
      area = {{0, -12}, {32, 12}},
      type = {"simple-entity", "tree", "cliff", "resource"},
  }) do
    entity.destroy()
  end

  local force = game.forces.player
  local technology = force.technologies[TECHNOLOGY]
  check(technology ~= nil, "missing efficient metallurgic science technology")
  if not technology then finish() return end
  technology.researched = false
  for _, recipe_name in ipairs({RECIPE, CHLORINE_RECIPE, SO2_RECIPE}) do
    check(force.recipes[recipe_name] and not force.recipes[recipe_name].enabled,
      recipe_name .. " was enabled before efficient metallurgy research")
  end
  research_closure(technology, {})
  for _, recipe_name in ipairs({RECIPE, CHLORINE_RECIPE, SO2_RECIPE}) do
    check(force.recipes[recipe_name] and force.recipes[recipe_name].enabled,
      recipe_name .. " was not unlocked by efficient metallurgy research")
  end

  storage.chlorine_pump = prepare_barrel_pump(
    surface, {10, -4}, CHLORINE_RECIPE, "nullius-chlorine")
  storage.so2_pump = prepare_barrel_pump(
    surface, {10, 4}, SO2_RECIPE, "nullius-sulfur-dioxide")
  if not storage.chlorine_pump or not storage.so2_pump or #failures > 0 then
    finish()
    return
  end
  script.on_nth_tick(20, start_efficient_recipe)
end

script.on_nth_tick(1, setup)

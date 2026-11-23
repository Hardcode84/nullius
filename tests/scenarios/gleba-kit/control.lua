-- given: Nutrient Technology; declared goop, carbon dioxide, wild culture, graphite and
--   locally made iron, glass, silica, stone brick and steel parts on the probe android;
--   gleba-kit.args proves every declared part closes locally.
-- place: chemical plant bioreactors for silica filters and flotation cell bioreactors for
--   bioplastic on cleared Gleba ground; no electricity.
-- act: make the filters and bioplastic, hand-craft the starter kit machines from them, then
--   place each machine and switch it to its Gleba mode.
-- run: until the staged hand crafts finish.
-- expect: Lab 1, chemical plant 1, distillery 1, hydro plant 1, flotation cell 1 and an iron
--   chest come from Gleba substitutes and ordinary recipes, and every machine runs on goop.
local research = require("__nullius-star__/scripts/research")
local fluid_api = require("__nullius-star__/scenarios/fluid-api")
local CASE = "gleba-kit"
local GOOP = "nullius-nutrient-goop"
local FILTERS, BIOPLASTIC_BATCHES = 5, 4

-- Hand-craft stages, each queued when the previous one finishes, as a player crafts the
-- parts of a machine before the machine.
local STAGES = {
  {["nullius-small-furnace-1"] = 2, ["nullius-chimney-1"] = 2, ["nullius-motor-1-gleba"] = 2, ["small-lamp"] = 2},
  {["nullius-iron-chest-gleba"] = 1, ["nullius-lab-1-gleba"] = 1, ["nullius-chemical-plant-1"] = 1,
    ["nullius-pump-1"] = 2},
  {["nullius-distillery-1"] = 2},
  {["nullius-hydro-plant-1-gleba"] = 1},
  {["nullius-flotation-cell-1"] = 1},
}
-- The kit machines, each placed afterwards in its Gleba mode.
local KIT = {
  {item = "iron-chest"},
  {item = "nullius-lab-1", mode = "-nutrient"},
  {item = "nullius-chemical-plant-1", mode = "-bioreactor"},
  {item = "nullius-distillery-1", mode = "-nutrient"},
  {item = "nullius-hydro-plant-1", mode = "-bioreactor"},
  {item = "nullius-flotation-cell-1", mode = "-bioreactor"},
}

-- Local materials the android carries; filters and bioplastic come from the machines.
local STOCK = {
  ["nullius-iron-plate"] = 100, ["nullius-iron-rod"] = 60, ["nullius-iron-gear"] = 40,
  ["nullius-iron-sheet"] = 60, ["nullius-iron-wire"] = 30, ["pipe"] = 40,
  ["nullius-one-way-valve"] = 8, ["storage-tank"] = 3, ["nullius-steel-sheet"] = 8,
  ["nullius-steel-rod"] = 4, ["nullius-glass"] = 40, ["nullius-silica"] = 40, ["nullius-graphite"] = 10,
  ["stone-brick"] = 20, ["inserter"] = 10, ["transport-belt"] = 10, ["nullius-crusher-1"] = 1,
}

local function check(ok, message)
  storage.assertions = storage.assertions + 1
  if not ok then storage.failures[#storage.failures + 1] = message end
end

local function finish(tick)
  local failed = #storage.failures > 0
  helpers.write_file("factorio-tests/" .. CASE .. ".json", helpers.table_to_json{
    schema = 1, case = CASE, status = failed and "fail" or "pass", failure_count = #storage.failures,
    failures = storage.failures, assertions = storage.assertions, tick = tick,
    factorio_version = script.active_mods.base}, false)
  script.on_nth_tick(1, nil)
  script.on_nth_tick(60, nil)
  if failed then error(helpers.table_to_json(storage.failures)) end
end

local function fill(machine, name, amount)
  for index = 1, fluid_api.count(machine) do
    local filter = fluid_api.filter(machine, index)
    if filter and filter.name == name and fluid_api.prototype(machine, index).production_type == "input" then
      fluid_api.set(machine, index, {name = name, amount = amount})
      return
    end
  end
  check(false, machine.name .. " has no " .. name .. " input box")
end

-- Places a machine and switches it to its Gleba mode.
local function gleba_machine(name, mode, x, y)
  local surface = storage.surface
  local entity = assert(surface.create_entity{name = name, position = {x, y}, force = "player"}, name)
  local position = entity.position
  check(remote.call("nullius-test-transitions", "execute", entity), "no Gleba mode for " .. name)
  return assert(surface.find_entity(name .. mode, position), "missing " .. name .. mode)
end

local function batch(name, x, y, recipe, items, fluids)
  local machine = gleba_machine(name, "-bioreactor", x, y)
  machine.set_recipe(recipe)
  check(machine.get_recipe() and machine.get_recipe().name == recipe, name .. " refused " .. recipe)
  machine.get_fuel_inventory().insert{name = GOOP, count = 5}
  for item, count in pairs(items) do check(machine.insert{name = item, count = count} == count, "refused " .. item) end
  for fluid, amount in pairs(fluids) do fill(machine, fluid, amount) end
  return machine
end

local function prepare()
  local surface = game.planets["nullius-gleba"].surface
  storage.surface = surface
  surface.request_to_generate_chunks({40, 40}, 3)
  surface.force_generate_chunk_requests()
  for _, e in pairs(surface.find_entities_filtered{area = {{0, 0}, {120, 80}}}) do
    if e.type ~= "character" then e.destroy() end
  end
  local tiles = {}
  for x = 0, 120 do for y = 0, 80 do tiles[#tiles + 1] = {name = "highland-dark-rock", position = {x, y}} end end
  surface.set_tiles(tiles)
  storage.body = assert(surface.create_entity{name = "character", position = {60, 60}, force = "player"})
  for name, count in pairs(STOCK) do check(storage.body.insert{name = name, count = count} == count, "android refused " .. name) end
  storage.producers = {}
  for i = 1, FILTERS do
    storage.producers[#storage.producers + 1] = batch("nullius-chemical-plant-1", i * 8, 10, "nullius-filter-1-gleba",
      {["nullius-silica"] = 2, ["nullius-graphite"] = 1, ["nullius-iron-sheet"] = 1}, {["nullius-carbon-dioxide"] = 10})
  end
  for i = 1, BIOPLASTIC_BATCHES do
    storage.producers[#storage.producers + 1] = batch("nullius-flotation-cell-1", i * 8, 22, "nullius-gleba-bioplastic",
      {["nullius-wild-culture"] = 1, [GOOP] = 2}, {["nullius-carbon-dioxide"] = 20})
  end
end

-- Collects the machine products and starts the hand crafts once they are all made.
local function craft()
  for _, machine in ipairs(storage.producers) do
    check(machine.products_finished == 1, machine.name .. " finished " .. machine.products_finished .. " batches")
    for _, item in pairs(machine.get_output_inventory().get_contents()) do
      storage.body.insert{name = item.name, count = item.count}
    end
  end
  check(storage.body.get_item_count("nullius-filter-1") == FILTERS, "silica filters missing")
  check(storage.body.get_item_count("nullius-bioplastic") == 2 * BIOPLASTIC_BATCHES, "bioplastic missing")
  storage.stage = 0
end

local function next_stage()
  storage.stage = storage.stage + 1
  for recipe, count in pairs(STAGES[storage.stage]) do
    check(storage.body.begin_crafting{recipe = recipe, count = count} == count, "could not hand-craft " .. recipe)
  end
end

local function place_kit(tick)
  for index, entry in ipairs(KIT) do
    check(storage.body.get_item_count(entry.item) >= 1, "the hand crafts made no " .. entry.item)
    if entry.mode then
      check(storage.body.remove_item{name = entry.item, count = 1} == 1, "android lost " .. entry.item)
      local machine = gleba_machine(entry.item, entry.mode, index * 12, 50)
      check(machine.get_fuel_inventory().insert{name = GOOP, count = 1} == 1, entry.item .. " burns no goop")
    end
  end
  finish(tick)
end

script.on_init(function() storage.assertions, storage.failures = 0, {} end)

script.on_nth_tick(1, function(event)
  if event.tick == 0 then return end
  if event.tick == 1 then
    research.complete_with_prerequisites(game.forces.player.technologies["nullius-nutrient-technology"])
  elseif event.tick == 2 then
    prepare()
  elseif event.tick == 700 then
    craft()
  end
end)

-- Checks once a second whether the hand crafts have finished.
script.on_nth_tick(60, function(event)
  if event.tick == 0 or event.tick <= 700 or not storage.stage then return end
  if storage.body.crafting_queue_size > 0 then return end
  if storage.stage < #STAGES then next_stage() else place_kit(event.tick) end
end)

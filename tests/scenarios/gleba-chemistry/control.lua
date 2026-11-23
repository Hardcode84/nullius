-- given: Nutrient Technology; declared goop, ferric concentrate, crushed ferric rock, wild
--   culture, digestate, gypsum, iron sulfide, iron ingots and the fluids each recipe takes.
-- place: chemical plant and flotation cell bioreactors, a nutrient furnace and a nutrient
--   foundry on cleared Gleba ground; no electricity.
-- act: run one batch of each Gleba chemistry recipe and of ordinary steel.
-- run: 1200 ticks.
-- expect: water, acid liquor, carbon dioxide, gypsum, oxygen, sulfur dioxide, lime, graphite,
--   iron sulfide, iron and steel from rock, culture and goop alone.
local research = require("__nullius-star__/scripts/research")
local fluid_api = require("__nullius-star__/scenarios/fluid-api")
local CASE = "gleba-chemistry"
local GOOP = "nullius-nutrient-goop"

-- Each case: machine, Gleba mode, recipe, item and fluid inputs, expected item and fluid outputs.
local CASES = {
  {machine = "nullius-chemical-plant-1", mode = "-bioreactor", recipe = "nullius-gleba-sulfidation",
    items = {["nullius-ferric-concentrate"] = 2}, fluids = {},
    out_items = {["nullius-iron-sulfide"] = 1}, out_fluids = {["nullius-water"] = 30}},
  {machine = "nullius-flotation-cell-1", mode = "-bioreactor", recipe = "nullius-gleba-acid-liquor",
    items = {["nullius-ferric-concentrate"] = 2, ["nullius-wild-culture"] = 1}, fluids = {["nullius-water"] = 10},
    out_items = {["nullius-iron-sulfide"] = 1}, out_fluids = {["nullius-acid-sulfuric"] = 20}},
  {machine = "nullius-chemical-plant-1", mode = "-bioreactor", recipe = "nullius-gleba-neutralization",
    items = {["nullius-crushed-gleba-rock"] = 4}, fluids = {["nullius-acid-sulfuric"] = 20},
    out_items = {["nullius-gypsum"] = 2, ["nullius-leach-residue"] = 2}, out_fluids = {["nullius-carbon-dioxide"] = 20}},
  {machine = "nullius-chemical-plant-1", mode = "-bioreactor", recipe = "nullius-gleba-gypsum-decomposition",
    items = {["nullius-gypsum"] = 2}, fluids = {},
    out_items = {["nullius-lime"] = 1}, out_fluids = {["nullius-oxygen"] = 10, ["nullius-sulfur-dioxide"] = 10}},
  {machine = "nullius-chemical-plant-1", mode = "-bioreactor", recipe = "nullius-gleba-sulfur-dioxide-reduction",
    items = {["nullius-ferric-concentrate"] = 1}, fluids = {["nullius-sulfur-dioxide"] = 10},
    out_items = {["nullius-iron-sulfide"] = 1}, out_fluids = {["nullius-water"] = 10}},
  {machine = "nullius-chemical-plant-1", mode = "-bioreactor", recipe = "nullius-gleba-digestate-pyrolysis",
    items = {["nullius-digestate"] = 5}, fluids = {},
    out_items = {["nullius-graphite"] = 1}, out_fluids = {["nullius-carbon-dioxide"] = 10}},
  {machine = "nullius-small-furnace-1", mode = "-nutrient", recipe = "nullius-gleba-iron-sulfide-reduction",
    items = {["nullius-iron-sulfide"] = 2, [GOOP] = 1}, fluids = {},
    out_items = {["nullius-iron-ingot"] = 3}, out_fluids = {}},
  {machine = "nullius-foundry-1", mode = "-nutrient", recipe = "nullius-steel-ingot",
    items = {["nullius-iron-ingot"] = 6}, fluids = {["nullius-oxygen"] = 60},
    out_items = {}, out_fluids = {}, steel = true},
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
  if failed then error(helpers.table_to_json(storage.failures)) end
end

local function prepare(surface)
  surface.request_to_generate_chunks({40, 40}, 2)
  surface.force_generate_chunk_requests()
  for _, e in pairs(surface.find_entities_filtered{area = {{0, 0}, {100, 30}}}) do
    if e.type ~= "character" then e.destroy() end
  end
  local tiles = {}
  for x = 0, 100 do for y = 0, 30 do tiles[#tiles + 1] = {name = "highland-dark-rock", position = {x, y}} end end
  surface.set_tiles(tiles)
end

-- Sets one recipe input box to the declared fluid; the recipe filter names the box.
local function fill(machine, name, amount)
  for index = 1, fluid_api.count(machine) do
    local filter = fluid_api.filter(machine, index)
    if filter and filter.name == name and fluid_api.prototype(machine, index).production_type == "input" then
      check(fluid_api.capacity(machine, index) >= amount, machine.name .. " " .. name .. " box too small")
      fluid_api.set(machine, index, {name = name, amount = amount})
      return
    end
  end
  check(false, machine.name .. " has no " .. name .. " input box")
end

local function start(case, x)
  local surface = storage.surface
  local entity = assert(surface.create_entity{name = case.machine, position = {x, 10}, force = "player"})
  local position = entity.position
  check(remote.call("nullius-test-transitions", "execute", entity), "no Gleba mode for " .. case.machine)
  local machine = assert(surface.find_entity(case.machine .. case.mode, position), "missing " .. case.machine .. case.mode)
  machine.set_recipe(case.recipe)
  check(machine.get_recipe() and machine.get_recipe().name == case.recipe, machine.name .. " refused " .. case.recipe)
  machine.get_fuel_inventory().insert{name = GOOP, count = 5}
  for name, count in pairs(case.items) do
    check(machine.insert{name = name, count = count} == count, machine.name .. " refused " .. name)
  end
  for name, amount in pairs(case.fluids) do fill(machine, name, amount) end
  return machine
end

script.on_init(function() storage.assertions, storage.failures = 0, {} end)

script.on_nth_tick(1, function(event)
  if event.tick == 0 then return end
  if event.tick == 1 then
    research.complete_with_prerequisites(game.forces.player.technologies["nullius-nutrient-technology"])
  elseif event.tick == 2 then
    storage.surface = game.planets["nullius-gleba"].surface
    prepare(storage.surface)
    storage.machines = {}
    for index, case in ipairs(CASES) do storage.machines[index] = start(case, index * 10) end
  elseif event.tick == 1200 then
    for index, case in ipairs(CASES) do
      local machine = storage.machines[index]
      check(machine.products_finished == 1, case.recipe .. " finished " .. machine.products_finished .. " batches")
      local output = machine.get_output_inventory()
      for name, count in pairs(case.out_items) do
        check(output.get_item_count(name) == count, case.recipe .. " made " .. output.get_item_count(name) .. " " .. name)
      end
      for name, amount in pairs(case.out_fluids) do
        check(math.abs(machine.get_fluid_count(name) - amount) < 1e-6,
          case.recipe .. " made " .. machine.get_fluid_count(name) .. " " .. name)
      end
      if case.steel then
        check(output.get_item_count("nullius-steel-ingot") > 0, "local oxygen made no steel")
      end
    end
    finish(event.tick)
  end
end)

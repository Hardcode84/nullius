-- given: Nutrient Technology and the ordinary sodium, sulfur, alkali and limestone research;
--   declared goop, ferric concentrate, crushed ferric rock, wild culture, digestate, gypsum,
--   iron sulfide, iron ingots, leach residue, salt, soda ash, lime, crushed limestone and the
--   fluids each recipe takes.
-- place: chemical plant, flotation cell and hydro plant bioreactors, nutrient furnaces, a
--   nutrient distillery and a nutrient foundry on cleared Gleba ground; no electricity.
-- act: run one batch of each Gleba chemistry recipe, of ordinary steel, and of each step of
--   the salt, chlorine and sodium hydroxide chain.
-- run: 2100 ticks.
-- expect: water, acid liquor, carbon dioxide, gypsum, oxygen, sulfur dioxide, lime, graphite,
--   iron sulfide, iron and steel from rock, culture and goop alone; salt and natron, hydrogen
--   chloride, chlorine, sodium hydroxide and burnt lime in Gleba modes.
local research = require("__nullius-star__/scripts/research")
local fluid_api = require("__nullius-star__/scenarios/fluid-api")
local CASE = "gleba-chemistry"
local GOOP = "nullius-nutrient-goop"
local TECHNOLOGIES = {"nullius-nutrient-technology", "nullius-sodium-processing", "nullius-sulfur-processing-2",
  "nullius-alkali-processing", "nullius-limestone-processing-1"}
-- Causticization, the longest batch, takes 30 seconds at crafting speed 1.
local CHECK_TICK = 2100

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
  -- Salt, hydrogen chloride and chlorine.
  {machine = "nullius-hydro-plant-1", mode = "-bioreactor", recipe = "nullius-leach-residue-washing",
    items = {["nullius-leach-residue"] = 4}, fluids = {["nullius-water"] = 40},
    out_items = {["nullius-salt"] = 1, ["nullius-soda-ash"] = 1, ["nullius-sand"] = 2}, out_fluids = {}},
  {machine = "nullius-chemical-plant-1", mode = "-bioreactor", recipe = "nullius-sodium-sulfate",
    items = {["nullius-salt"] = 2}, fluids = {["nullius-acid-sulfuric"] = 15},
    out_items = {["nullius-sodium-sulfate"] = 1}, out_fluids = {["nullius-acid-hydrochloric"] = 10}},
  {machine = "nullius-distillery-1", mode = "-nutrient", recipe = "nullius-hydrochloric-stripping",
    items = {}, fluids = {["nullius-acid-hydrochloric"] = 40},
    out_items = {}, out_fluids = {["nullius-hydrogen-chloride"] = 30, ["nullius-water"] = 35}},
  {machine = "nullius-chemical-plant-1", mode = "-bioreactor", recipe = "nullius-deacon-process",
    items = {}, fluids = {["nullius-hydrogen-chloride"] = 60, ["nullius-oxygen"] = 15},
    out_items = {}, out_fluids = {["nullius-chlorine"] = 30, ["nullius-water"] = 30}},
  -- Sodium hydroxide and lime recovery.
  {machine = "nullius-hydro-plant-1", mode = "-bioreactor", recipe = "nullius-causticization",
    items = {["nullius-soda-ash"] = 1, ["nullius-lime"] = 1}, fluids = {["nullius-water"] = 100},
    out_items = {["nullius-sodium-hydroxide"] = 2, ["nullius-crushed-limestone"] = 1}, out_fluids = {}},
  {machine = "nullius-medium-furnace-1", mode = "-nutrient", recipe = "nullius-lime",
    items = {["nullius-crushed-limestone"] = 3}, fluids = {},
    out_items = {["nullius-lime"] = 2}, out_fluids = {["nullius-carbon-dioxide"] = 40}},
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
  surface.request_to_generate_chunks({85, 15}, 3)
  surface.force_generate_chunk_requests()
  for _, e in pairs(surface.find_entities_filtered{area = {{0, 0}, {170, 30}}}) do
    if e.type ~= "character" then e.destroy() end
  end
  local tiles = {}
  for x = 0, 170 do for y = 0, 30 do tiles[#tiles + 1] = {name = "highland-dark-rock", position = {x, y}} end end
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
    for _, name in ipairs(TECHNOLOGIES) do
      research.complete_with_prerequisites(game.forces.player.technologies[name])
    end
  elseif event.tick == 2 then
    storage.surface = game.planets["nullius-gleba"].surface
    prepare(storage.surface)
    storage.machines = {}
    for index, case in ipairs(CASES) do storage.machines[index] = start(case, index * 10) end
  elseif event.tick == CHECK_TICK then
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

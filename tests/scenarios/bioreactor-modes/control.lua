-- given: Nutrient Technology researched after a locked check, then Bioreactor Engineering 2;
--   Pneumatic Technology for the Vulcanus cycle; declared goop, methane, oxygen, crushed
--   ferric rock and wild culture.
-- place: chemical plants, hydro plants and flotation cells on landfill on Nauvis, Gleba and
--   Vulcanus.
-- act: switch modes, run methanol synthesis in a tier 1 bioreactor and rock leaching in a
--   Gleba flotation bioreactor, leave the mode, and place locked bioreactor ghosts.
-- run: 900 ticks.
-- expect: bioreactors unlock by tier research and construction recipe, add their tier
--   productivity, burn goop at their tier power, release fuel on leaving, run Gleba culture as
--   the Gleba mode of their family, and join the Vulcanus mode cycle.
local research = require("__nullius-star__/scripts/research")
local shared = require("__nullius-star__/shared/bioreactors")
local productivity = require("__nullius-star__/thermal-machine-config").productivity
local fluid_api = require("__nullius-star__/scenarios/fluid-api")
local CASE = "bioreactor-modes"
local GOOP, DIGESTATE = "nullius-nutrient-goop", "nullius-digestate"
local LEACHING = "nullius-gleba-rock-leaching"
-- Batches of crafts that fill the input fluid boxes, fed after the previous batch is used.
local BATCH, FEEDS = 4, {[300] = true, [600] = true}
local CRAFTS = BATCH * 3

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

local function pad(surface)
  surface.request_to_generate_chunks({0, 0}, 2)
  surface.force_generate_chunk_requests()
  for _, e in pairs(surface.find_entities_filtered{area = {{-30, -30}, {30, 30}}}) do
    if e.type ~= "character" then e.destroy() end
  end
  local tiles = {}
  for x = -30, 30 do for y = -30, 30 do tiles[#tiles + 1] = {name = "landfill", position = {x, y}} end end
  surface.set_tiles(tiles)
  return surface
end

local function planet(name)
  local p = game.planets[name]
  return pad(p.surface or p.create_surface())
end

local function place(surface, name, position)
  return assert(surface.create_entity{name = name, position = position, force = "player"}, name)
end

-- Switches a machine once and returns the machine now at its position.
local function switch(entity, expected)
  local surface, position, name = entity.surface, entity.position, entity.name
  check(remote.call("nullius-test-transitions", "execute", entity), "no transition from " .. name)
  local replacement = surface.find_entity(expected, position)
  check(replacement ~= nil, "expected " .. expected .. " after switching")
  return replacement
end

local function spilled(surface, position, name)
  local count = 0
  for _, drop in pairs(surface.find_entities_filtered{name = "item-on-ground", position = position, radius = 5}) do
    if drop.stack.name == name then
      count = count + drop.stack.count
      drop.destroy()
    end
  end
  return count
end

-- Fills each recipe input box with one batch, on top of what it still holds.
local function feed(reactor)
  local batch = {["nullius-methane"] = 16 * BATCH, ["nullius-oxygen"] = 8 * BATCH}
  for index = 1, fluid_api.count(reactor) do
    local filter = fluid_api.filter(reactor, index)
    local amount = filter and batch[filter.name]
    if amount then
      local held = fluid_api.get(reactor, index)
      amount = amount + (held and held.amount or 0)
      check(fluid_api.capacity(reactor, index) >= amount, filter.name .. " box holds " .. fluid_api.capacity(reactor, index) .. " of " .. amount)
      fluid_api.set(reactor, index, {name = filter.name, amount = amount})
      batch[filter.name] = nil
    end
  end
  check(next(batch) == nil, "bioreactor has no input box for " .. tostring(next(batch)))
end

script.on_init(function() storage.assertions, storage.failures = 0, {} end)

script.on_nth_tick(1, function(event)
  if event.tick == 0 then return end
  local force = game.forces.player
  if event.tick == 1 then
    local nauvis = pad(game.surfaces.nauvis)
    -- Before Nutrient Technology no bioreactor mode exists.
    local locked = place(nauvis, "nullius-chemical-plant-1", {-20, -20})
    check(not remote.call("nullius-test-transitions", "execute", locked), "bioreactor before Nutrient Technology")
    locked.destroy()
    for _, name in ipairs({"nullius-nutrient-technology", "nullius-pneumatic-technology"}) do
      research.complete_with_prerequisites(force.technologies[name])
    end
  elseif event.tick == 2 then
    local nauvis = game.surfaces.nauvis
    -- Tier 1 multiplies power and adds its productivity.
    for _, spec in ipairs(shared.specs) do
      local base, variant = prototypes.entity[spec.base], prototypes.entity[spec.base .. "-bioreactor"]
      check(math.abs(variant.energy_usage - base.energy_usage * shared.power[spec.tier]) < 1e-6,
        spec.base .. " bioreactor power")
      check(variant.burner_prototype and variant.burner_prototype.fuel_categories["nullius-nutrient"],
        spec.base .. " bioreactor does not burn goop")
    end
    local plant = place(nauvis, "nullius-chemical-plant-1", {-10, -10})
    local half = math.floor(plant.max_health / 2)
    plant.health = half
    storage.reactor = switch(plant, "nullius-chemical-plant-1-bioreactor")
    check(math.abs(storage.reactor.health - half) < 1, "health changed entering bioreactor mode")
    check(prototypes.recipe["nullius-methanol"].allowed_effects.productivity, "methanol allows no productivity")
    storage.reactor.set_recipe("nullius-methanol")
    storage.reactor.get_fuel_inventory().insert{name = GOOP, count = 10}
    feed(storage.reactor)

    -- Tier 2 needs Bioreactor Engineering 2 and the ordinary construction recipe.
    local tier2 = place(nauvis, "nullius-chemical-plant-2", {10, -10})
    check(not remote.call("nullius-test-transitions", "execute", tier2), "tier 2 bioreactor before its research")
    research.complete_with_prerequisites(force.technologies["nullius-bioreactor-engineering-2"])
    force.recipes["nullius-chemical-plant-2"].enabled = false
    check(not remote.call("nullius-test-transitions", "execute", tier2), "tier 2 bioreactor without its recipe")
    force.recipes["nullius-chemical-plant-2"].enabled = true
    switch(tier2, "nullius-chemical-plant-2-bioreactor")

    -- A blueprinted tier 3 bioreactor stays ordinary until its research.
    nauvis.create_entity{name = "entity-ghost", inner_name = "nullius-hydro-plant-3-bioreactor",
      position = {10, 10}, force = force, raise_built = true}
    local ghost = nauvis.find_entity("entity-ghost", {10, 10})
    check(ghost ~= nil and ghost.ghost_name == "nullius-hydro-plant-3", "locked bioreactor ghost kept its mode")

    -- On Gleba the bioreactor is the only goop mode of these families.
    local gleba = planet("nullius-gleba")
    for _, spec in ipairs(shared.specs) do
      check(prototypes.entity[spec.base .. "-nutrient"] == nil, spec.base .. " also has a nutrient mode")
    end
    local hydro = switch(place(gleba, "nullius-hydro-plant-1", {0, 0}), "nullius-hydro-plant-1-bioreactor")
    hydro.get_fuel_inventory().insert{name = GOOP, count = 3}
    local position = hydro.position
    switch(hydro, "nullius-hydro-plant-1")
    check(spilled(gleba, position, GOOP) == 3, "leaving bioreactor mode on Gleba kept its goop")
    local cell = switch(place(gleba, "nullius-flotation-cell-1", {-10, 10}), "nullius-flotation-cell-1-bioreactor")
    cell.set_recipe(LEACHING)
    check(cell.get_recipe() and cell.get_recipe().name == LEACHING, "flotation bioreactor refused Gleba culture")
    cell.get_fuel_inventory().insert{name = GOOP, count = 5}
    check(cell.insert{name = "nullius-crushed-gleba-rock", count = 2} == 2, "flotation bioreactor refused rock")
    check(cell.insert{name = "nullius-wild-culture", count = 1} == 1, "flotation bioreactor refused wild culture")
    storage.cell = cell
    -- Vulcanus cycles ordinary, pneumatic, bioreactor.
    local vulcanus = planet("nullius-vulcanus")
    local chemical = place(vulcanus, "nullius-chemical-plant-1", {0, 0})
    local pneumatic = switch(chemical, "nullius-chemical-plant-1-pneumatic")
    switch(switch(pneumatic, "nullius-chemical-plant-1-bioreactor"), "nullius-chemical-plant-1")
  elseif FEEDS[event.tick] then
    feed(storage.reactor)
  elseif event.tick == 900 then
    local leached = storage.cell.get_output_inventory()
    check(leached.get_item_count("nullius-leach-residue") == 2 and leached.get_item_count("nullius-ferric-concentrate") == 2,
      "flotation bioreactor did not leach the rock")
    local reactor = storage.reactor
    -- Each full productivity bar adds one craft of two methanol.
    local expected = 2 * (CRAFTS + math.floor(CRAFTS * productivity[1] + 1e-9))
    check(math.abs(reactor.get_fluid_count("nullius-methanol") - expected) < 1e-6,
      "bioreactor made " .. reactor.get_fluid_count("nullius-methanol") .. " methanol, expected " .. expected)
    -- The crafts burned their tier multiple of the ordinary power from one goop.
    local spent = reactor.get_burnt_result_inventory().get_item_count(DIGESTATE)
    local burned = prototypes.item[GOOP].fuel_value * (spent + 1) - reactor.burner.remaining_burning_fuel
    local expected_burn = reactor.prototype.energy_usage * 60 * CRAFTS
    check(math.abs(burned - expected_burn) < expected_burn * 0.02,
      "bioreactor burned " .. burned .. " J, expected " .. expected_burn)
    local fuel = reactor.get_fuel_inventory().get_item_count(GOOP)
    local burning = reactor.burner.currently_burning and 1 or 0
    check(fuel + burning + spent == 10, "goop neither burned into digestate nor stayed in the fuel slot")
    local position, health = reactor.position, reactor.health
    local ordinary = switch(reactor, "nullius-chemical-plant-1")
    check(math.abs(ordinary.health - health) < 1, "health changed leaving bioreactor mode")
    check(spilled(ordinary.surface, position, GOOP) == fuel, "leaving bioreactor mode kept its goop")
    check(spilled(ordinary.surface, position, DIGESTATE) == spent, "leaving bioreactor mode kept its digestate")
    finish(event.tick)
  end
end)

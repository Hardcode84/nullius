-- given: Gleba unlocked, before and after Nutrient Technology.
-- place: test entities on cleared Gleba ground and on Nauvis.
-- act: check forbidden entity placement, forbidden oxidant voids, mat-culture surface conditions,
--   locked nutrient blueprint downgrade, Ctrl+R mode switching, fuel release, and upgrade chains.
-- run: 10 ticks.
-- expect: Gleba blocks electricity generators, water intakes, normal logibots, and O2/SO2 voids;
--   Nauvis blocks mat culture; nutrient modes switch cleanly and preserve upgrade chains.
local research = require("__nullius-star__/scripts/research")
local CASE = "gleba-surface-and-modes"

local function check(ok, message)
  storage.assertions = storage.assertions + 1
  if not ok then storage.failures[#storage.failures + 1] = message end
end

local function allowed(conditions, surface)
  for _, condition in pairs(conditions or {}) do
    local value = surface.get_property(condition.property)
    if value < condition.min or value > condition.max then return false end
  end
  return true
end

local function clear_pad(surface, center)
  surface.request_to_generate_chunks(center, 2)
  surface.force_generate_chunk_requests()
  local area = {{center.x - 20, center.y - 20}, {center.x + 20, center.y + 20}}
  for _, e in pairs(surface.find_entities_filtered{area = area}) do
    if e.type ~= "character" then e.destroy() end
  end
  local tiles = {}
  local tile_name = surface.name == "nullius-gleba" and "highland-dark-rock" or "grass-1"
  for x = center.x - 20, center.x + 20 do
    for y = center.y - 20, center.y + 20 do
      tiles[#tiles + 1] = {name = tile_name, position = {x, y}}
    end
  end
  surface.set_tiles(tiles)
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

script.on_init(function() storage.assertions, storage.failures = 0, {} end)

script.on_nth_tick(1, function(event)
  if event.tick == 0 then return end
  local force = game.forces.player
  if event.tick == 1 then
    research.complete_with_prerequisites(force.technologies["nullius-probe-gleba"])
  elseif event.tick == 2 then
    local gleba = assert(game.planets["nullius-gleba"].surface, "Gleba surface missing")
    local nauvis = game.surfaces.nauvis
    clear_pad(gleba, {x = 80, y = 80})

    -- 1. Forbidden entities on Gleba.
    local forbidden_on_gleba = {
      "nullius-solar-panel-1", "nullius-solar-panel-4",
      "nullius-wind-build-1", "nullius-wind-base-1",
      "nullius-grid-battery-1", "nullius-grid-battery-1-supercapacitor",
      "nullius-stirling-engine-1", "nullius-stirling-engine-3",
      "nullius-turbine-open-standard-1", "nullius-turbine-closed-standard-1",
      "nullius-seawater-intake-1", "nullius-seawater-intake-2",
      "nullius-well-1", "nullius-well-2",
      "nullius-logistic-bot-1", "nullius-logistic-bot-4",
    }
    for _, name in ipairs(forbidden_on_gleba) do
      local proto = assert(prototypes.entity[name], "missing prototype " .. name)
      check(not allowed(proto.surface_conditions, gleba), name .. " allowed on Gleba")
      check(not gleba.can_place_entity{name = name, position = {80, 80}, force = force},
        name .. " placeable on Gleba")
    end

    -- 2. Oxidant voids fail on Gleba and pass on Nauvis.
    for _, name in ipairs({"nullius-void-oxygen", "nullius-void-compressed-oxygen", "nullius-void-sulfur-dioxide"}) do
      local proto = assert(prototypes.recipe[name], "missing recipe " .. name)
      check(not allowed(proto.surface_conditions, gleba), name .. " allowed on Gleba")
      check(allowed(proto.surface_conditions, nauvis), name .. " blocked on Nauvis")
    end

    -- 3. Mat culture fails on Nauvis and passes on Gleba; ordinary biology recipes stay surface-free.
    for _, name in ipairs({"nullius-isolate-wild-culture", "nullius-wild-culture-propagation"}) do
      local proto = assert(prototypes.recipe[name], "missing recipe " .. name)
      check(allowed(proto.surface_conditions, gleba), name .. " blocked on Gleba")
      check(not allowed(proto.surface_conditions, nauvis), name .. " allowed on Nauvis")
    end
    for _, name in ipairs({"nullius-biochemistry-pack", "nullius-algae-1"}) do
      local proto = prototypes.recipe[name]
      if proto then
        check(not proto.surface_conditions or #proto.surface_conditions == 0,
          name .. " unexpectedly has surface conditions")
      end
    end

    -- 4. Locked nutrient ghost placed before Nutrient Technology reverts to ordinary entity.
    gleba.create_entity{
      name = "entity-ghost", inner_name = "inserter-nutrient", position = {75.5, 80.5}, force = force, raise_built = true,
    }
    local reverted = gleba.find_entity("entity-ghost", {75.5, 80.5})
    check(reverted ~= nil and reverted.ghost_name == "inserter", "locked nutrient ghost did not revert to inserter")
    if reverted then reverted.destroy() end

    -- Now unlock Nutrient Technology for mode-switch and upgrade checks.
    research.complete_with_prerequisites(force.technologies["nullius-nutrient-technology"])
  elseif event.tick == 3 then
    local gleba = game.planets["nullius-gleba"].surface

    -- 5. Mode switching across diverse machine families, health preservation, and fuel spill on exit.
    local switch_cases = {
      {name = "inserter", pos = {70, 75}},
      {name = "nullius-small-assembler-1", pos = {74, 75}},
      {name = "nullius-hydro-plant-1", pos = {80, 75}},
      {name = "nullius-pump-1", pos = {86, 75}},
      {name = "nullius-boxer", pos = {70, 82}},
      {name = "nullius-lab-1", pos = {76, 82}},
      {name = "nullius-biology-lab", pos = {82, 82}},
    }
    for _, case in ipairs(switch_cases) do
      local entity = assert(gleba.create_entity{name = case.name, position = case.pos, force = force})
      local pos = entity.position
      local half = math.floor(entity.max_health / 2)
      entity.health = half
      check(remote.call("nullius-test-transitions", "execute", entity), "failed to enter nutrient mode: " .. case.name)
      local nutrient = gleba.find_entity(case.name .. "-nutrient", pos)
      check(nutrient ~= nil, "missing nutrient entity after switch: " .. case.name)
      if nutrient then
        check(math.abs(nutrient.health - half) < 1, "health changed entering nutrient mode: " .. case.name)
        nutrient.get_fuel_inventory().insert{name = "nullius-nutrient-goop", count = 2}
        check(remote.call("nullius-test-transitions", "execute", nutrient), "failed to leave nutrient mode: " .. case.name)
        local back = gleba.find_entity(case.name, pos)
        check(back ~= nil, "missing ordinary entity after return: " .. case.name)
        if back then
          check(math.abs(back.health - half) < 1, "health changed leaving nutrient mode: " .. case.name)
          if back.prototype.electric_energy_source_prototype then
            check(back.energy == 0, "returning to ordinary mode created electric energy: " .. case.name)
          end
          back.destroy()
        end
        local spilled = gleba.find_entities_filtered{name = "item-on-ground", position = pos, radius = 4}
        local goop = 0
        for _, drop in pairs(spilled) do
          if drop.stack.name == "nullius-nutrient-goop" then goop = goop + drop.stack.count end
          drop.destroy()
        end
        check(goop == 2, "leaving nutrient mode did not release fuel for " .. case.name .. " (got " .. goop .. ")")
      end
    end

    -- 6. Upgrade chains stay in nutrient mode.
    local chains = {
      {"inserter-nutrient", "bob-turbo-inserter-nutrient"},
      {"bob-turbo-inserter-nutrient", "bulk-inserter-nutrient"},
      {"bulk-inserter-nutrient", "bob-express-bulk-inserter-nutrient"},
      {"nullius-small-assembler-1-nutrient", "nullius-small-assembler-2-nutrient"},
      {"nullius-small-assembler-2-nutrient", "nullius-small-assembler-3-nutrient"},
      {"nullius-crusher-1-nutrient", "nullius-crusher-2-nutrient"},
      {"nullius-chemical-plant-1-nutrient", "nullius-chemical-plant-2-nutrient"},
      {"nullius-small-furnace-1-nutrient", "nullius-small-furnace-2-nutrient"},
      {"nullius-foundry-1-nutrient", "nullius-foundry-2-nutrient"},
      {"nullius-lab-1-nutrient", "nullius-lab-2-nutrient"},
      {"nullius-pump-1-nutrient", "nullius-pump-2-nutrient"},
      {"nullius-pump-2-nutrient", "pump-nutrient"},
    }
    for _, edge in ipairs(chains) do
      local proto = assert(prototypes.entity[edge[1]], "missing variant " .. edge[1])
      local next_up = proto.next_upgrade
      check(next_up and next_up.name == edge[2],
        edge[1] .. " next_upgrade expected " .. edge[2] .. ", got " .. (next_up and next_up.name or "nil"))
    end

    finish(event.tick)
  end
end)

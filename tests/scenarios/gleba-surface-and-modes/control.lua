-- given: Gleba unlocked, before and after Nutrient Technology; declared goop, gases and hand-craft
--   ingredients.
-- place: test entities on cleared Gleba ground and on Nauvis; one character on each surface.
-- act: check forbidden entity placement, locked nutrient blueprint downgrade, mode switching,
--   fuel release and upgrade chains; then vent gases, filter air and hand-craft Gleba recipes
--   on both surfaces.
-- run: 900 ticks.
-- expect: Gleba blocks electricity generators, water intakes, normal logistic bots, pneumatic
--   machines, oxygen venting and ordinary air; its filters make Gleba air, which separates into
--   nitrogen and vents; Gleba air separation, Gleba hand crafts and
--   nutrient machines fail on Nauvis.
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

local GOOP = "nullius-nutrient-goop"

-- A machine's Gleba mode: chemical plants, hydro plants and flotation cells use bioreactor mode.
local function gleba_mode(name)
  local nutrient, bioreactor = name .. "-nutrient", name .. "-bioreactor"
  assert((prototypes.entity[nutrient] ~= nil) ~= (prototypes.entity[bioreactor] ~= nil), "no single Gleba mode for " .. name)
  return prototypes.entity[nutrient] and nutrient or bioreactor
end

local function nutrient(surface, name, position, force)
  local entity = assert(surface.create_entity{name = name, position = position, force = force})
  position = entity.position
  check(remote.call("nullius-test-transitions", "execute", entity), "failed to enter Gleba mode: " .. name)
  local machine = assert(surface.find_entity(gleba_mode(name), position), "missing Gleba mode of " .. name)
  machine.get_fuel_inventory().insert{name = GOOP, count = 5}
  return machine
end

local function blueprinted(surface, name, position, force)
  local ghost = assert(surface.create_entity{name = "entity-ghost", inner_name = name, position = position,
    force = force, recipe = "nullius-gleba-air-separation"})
  check(ghost.get_recipe() and ghost.get_recipe().name == "nullius-gleba-air-separation", "ghost lost its recipe")
  local _, built = ghost.revive()
  return assert(built, "could not build " .. name)
end

local function hand_craft(character, recipe)
  local ok, started = pcall(character.begin_crafting, {recipe = recipe, count = 1})
  return ok and started or 0
end

local function character(surface, position, force, items)
  local body = assert(surface.create_entity{name = "character", position =
    assert(surface.find_non_colliding_position("character", position, 20, 1)), force = force})
  for _, stack in ipairs(items) do
    check(body.insert(stack) == stack.count, "character refused " .. stack.name)
  end
  return body
end

-- Exactly one wild culture isolation and one silica-insulated motor.
local HAND_INPUTS = {
  {name = "nullius-mat-sample", count = 3}, {name = "nullius-iron-wire", count = 2},
  {name = "nullius-iron-plate", count = 1}, {name = "nullius-silica", count = 2},
  {name = "nullius-iron-rod", count = 1},
}

function start_attempts(force)
  local gleba, nauvis = game.planets["nullius-gleba"].surface, game.surfaces.nauvis
  clear_pad(gleba, {x = 150, y = 80})
  clear_pad(nauvis, {x = 80, y = 80})
  local a = {}
  storage.attempts = a

  -- Gleba air vents on Gleba; oxygen stays in the same kind of chimney.
  a.air_chimney = nutrient(gleba, "nullius-chimney-3", {140, 70}, force)
  a.oxygen_chimney = nutrient(gleba, "nullius-chimney-3", {150, 70}, force)
  check(a.air_chimney.insert_fluid{name = "nullius-gleba-air", amount = 400} > 0, "chimney refused Gleba air")
  check(a.oxygen_chimney.insert_fluid{name = "nullius-oxygen", amount = 400} > 0, "chimney refused oxygen")
  a.air_before = a.air_chimney.get_fluid_count("nullius-gleba-air")
  a.oxygen_before = a.oxygen_chimney.get_fluid_count("nullius-oxygen")

  -- Nutrient filters draw Gleba air, and only on Gleba.
  a.gleba_filter = nutrient(gleba, "nullius-air-filter-1", {140, 85}, force)
  local recipe = a.gleba_filter.get_recipe()
  check(recipe and recipe.name == "nullius-gleba-air", "nutrient filter does not draw Gleba air")

  -- A blueprinted nutrient distillery keeps Gleba air separation on Gleba and separates
  -- declared Gleba air into nitrogen. Script set_recipe skips surface conditions, so the
  -- recipe arrives through the blueprint ghost a player would build.
  a.separator = blueprinted(gleba, "nullius-distillery-1-nutrient", {150, 85}, force)
  a.separator.get_fuel_inventory().insert{name = GOOP, count = 5}
  check(a.separator.get_recipe() and a.separator.get_recipe().name == "nullius-gleba-air-separation",
    "blueprinted Gleba distillery lost Gleba air separation")
  check(a.separator.insert_fluid{name = "nullius-gleba-air", amount = 300} > 0, "distillery refused Gleba air")

  -- The same blueprint built on Nauvis drops the recipe.
  local still = blueprinted(nauvis, "nullius-distillery-1", {90, 75}, force)
  check(still.get_recipe() == nil, "blueprinted Nauvis distillery kept Gleba air separation")
  check(not nauvis.can_place_entity{name = "nullius-air-filter-1-nutrient", position = {80, 75}, force = force},
    "nutrient air filter placeable on Nauvis")

  -- Gleba hand crafts complete on Gleba and fail on Nauvis.
  a.gleba_hands = character(gleba, {150, 95}, force, HAND_INPUTS)
  a.nauvis_hands = character(nauvis, {80, 90}, force, HAND_INPUTS)
  for _, recipe in ipairs({"nullius-isolate-wild-culture", "nullius-gleba-motor-1"}) do
    check(hand_craft(a.gleba_hands, recipe) == 1, "Gleba character could not hand-craft " .. recipe)
    hand_craft(a.nauvis_hands, recipe)
  end
end

function check_attempts()
  local a = storage.attempts
  check(a.air_chimney.get_fluid_count("nullius-gleba-air") < a.air_before, "nutrient chimney did not vent Gleba air")
  check(a.oxygen_chimney.get_fluid_count("nullius-oxygen") == a.oxygen_before, "nutrient chimney vented oxygen on Gleba")
  check(a.gleba_filter.get_fluid_count("nullius-gleba-air") > 0, "Gleba filter made no Gleba air")
  check(a.gleba_filter.get_fluid_count("nullius-air") == 0, "Gleba filter made ordinary air")
  check(a.separator.get_fluid_count("nullius-nitrogen") > 0, "Gleba air separation made no nitrogen")
  for _, product in ipairs({"nullius-wild-culture", "nullius-motor-1"}) do
    check(a.gleba_hands.get_item_count(product) > 0, "Gleba hand craft made no " .. product)
    check(a.nauvis_hands.get_item_count(product) == 0, "Nauvis hand craft made " .. product)
  end
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

    -- Forbidden entities on Gleba.
    local forbidden_on_gleba = {
      "nullius-solar-panel-1", "nullius-solar-panel-4",
      "nullius-wind-build-1", "nullius-wind-base-1",
      "nullius-grid-battery-1", "nullius-grid-battery-1-supercapacitor",
      "nullius-stirling-engine-1", "nullius-stirling-engine-3",
      "nullius-turbine-open-standard-1", "nullius-turbine-closed-standard-1",
      "nullius-seawater-intake-1", "nullius-seawater-intake-2",
      "nullius-well-1", "nullius-well-2",
      "nullius-logistic-bot-1", "nullius-logistic-bot-4",
      "nullius-air-filter-1-pneumatic", "nullius-small-assembler-1-pneumatic",
    }
    for _, name in ipairs(forbidden_on_gleba) do
      local proto = assert(prototypes.entity[name], "missing prototype " .. name)
      check(not allowed(proto.surface_conditions, gleba), name .. " allowed on Gleba")
      check(not gleba.can_place_entity{name = name, position = {80, 80}, force = force},
        name .. " placeable on Gleba")
    end

    -- Compressed oxygen and sulfur dioxide share the oxygen void's rule; venting is run below.
    for _, name in ipairs({"nullius-void-oxygen", "nullius-void-compressed-oxygen", "nullius-void-sulfur-dioxide"}) do
      local proto = assert(prototypes.recipe[name], "missing recipe " .. name)
      check(not allowed(proto.surface_conditions, gleba), name .. " allowed on Gleba")
      check(allowed(proto.surface_conditions, nauvis), name .. " blocked on Nauvis")
    end

    -- Ordinary biology recipes keep no surface condition.
    for _, name in ipairs({"nullius-biochemistry-pack", "nullius-algae"}) do
      local proto = assert(prototypes.recipe[name], "missing recipe " .. name)
      check(#(proto.surface_conditions or {}) == 0, name .. " unexpectedly has surface conditions")
    end

    -- Locked nutrient ghost placed before Nutrient Technology reverts to ordinary entity.
    gleba.create_entity{
      name = "entity-ghost", inner_name = "inserter-nutrient", position = {75.5, 80.5}, force = force, raise_built = true,
    }
    local reverted = gleba.find_entity("entity-ghost", {75.5, 80.5})
    check(reverted ~= nil and reverted.ghost_name == "inserter", "locked nutrient ghost did not revert to inserter")
    if reverted then reverted.destroy() end

    -- Unlock Nutrient Technology for mode-switch and upgrade checks.
    research.complete_with_prerequisites(force.technologies["nullius-nutrient-technology"])
  elseif event.tick == 3 then
    local gleba = game.planets["nullius-gleba"].surface

    -- Mode switching across diverse machine families, health preservation, and fuel spill on exit.
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
      check(remote.call("nullius-test-transitions", "execute", entity), "failed to enter Gleba mode: " .. case.name)
      local nutrient = gleba.find_entity(gleba_mode(case.name), pos)
      check(nutrient ~= nil, "missing nutrient entity after switch: " .. case.name)
      if nutrient then
        check(math.abs(nutrient.health - half) < 1, "health changed entering Gleba mode: " .. case.name)
        nutrient.get_fuel_inventory().insert{name = "nullius-nutrient-goop", count = 2}
        check(remote.call("nullius-test-transitions", "execute", nutrient), "failed to leave Gleba mode: " .. case.name)
        local back = gleba.find_entity(case.name, pos)
        check(back ~= nil, "missing ordinary entity after return: " .. case.name)
        if back then
          check(math.abs(back.health - half) < 1, "health changed leaving Gleba mode: " .. case.name)
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
        check(goop == 2, "leaving Gleba mode did not release fuel for " .. case.name .. " (got " .. goop .. ")")
      end
    end

    -- Upgrade chains stay in their Gleba mode.
    local chains = {
      {"inserter-nutrient", "bob-turbo-inserter-nutrient"},
      {"bob-turbo-inserter-nutrient", "bulk-inserter-nutrient"},
      {"bulk-inserter-nutrient", "bob-express-bulk-inserter-nutrient"},
      {"nullius-small-assembler-1-nutrient", "nullius-small-assembler-2-nutrient"},
      {"nullius-small-assembler-2-nutrient", "nullius-small-assembler-3-nutrient"},
      {"nullius-crusher-1-nutrient", "nullius-crusher-2-nutrient"},
      {"nullius-chemical-plant-1-bioreactor", "nullius-chemical-plant-2-bioreactor"},
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

    start_attempts(force)
  elseif event.tick == 900 then
    check_attempts()
    finish(event.tick)
  end
end)

local CASE = "vulcanus-polymer-free-recipes"
local RESULT = "factorio-tests/" .. CASE .. ".json"

local specs = {
  ["nullius-vulcanus-barrel"] = {energy = 10,
    ingredients = { ["nullius-steel-sheet"] = 2,
      ["nullius-aluminum-sheet"] = 2, ["nullius-glass"] = 1,
      ["nullius-one-way-valve"] = 1 }, products = {barrel = 3}},
  ["nullius-splitter-1-vulcanus"] = {energy = 4,
    ingredients = {["underground-belt"] = 2,
      ["nullius-silicon-insulation"] = 2}, products = {splitter = 1}},
  ["nullius-underground-pipe-1-vulcanus"] = {energy = 8,
    ingredients = {pipe = 5, ["nullius-silica"] = 3},
    products = {["pipe-to-ground"] = 2}},
  ["nullius-heat-pipe-1-vulcanus"] = {energy = 4,
    ingredients = {["nullius-pipe-2"] = 1,
      ["nullius-aluminum-sheet"] = 2, ["nullius-silica"] = 2},
    products = {["nullius-heat-pipe-1"] = 1}},
  ["nullius-insulated-wire-vulcanus"] = {energy = 6,
    ingredients = {["nullius-aluminum-wire"] = 3,
      ["nullius-silicon-insulation"] = 2}, products = {["copper-cable"] = 4}},
  ["nullius-motor-1-vulcanus"] = {energy = 8,
    ingredients = {["nullius-iron-wire"] = 2, ["nullius-iron-plate"] = 1,
      ["nullius-silica"] = 2, ["nullius-iron-rod"] = 1},
    products = {["nullius-motor-1"] = 1}},
  ["nullius-filter-1-vulcanus"] = {energy = 8,
    ingredients = {["nullius-silica"] = 2, ["nullius-graphite"] = 1,
      ["nullius-iron-sheet"] = 1, ["nullius-carbon-dioxide"] = 10},
    products = {["nullius-filter-1"] = 1}},
  ["nullius-motor-2-vulcanus"] = {energy = 10,
    ingredients = {["copper-cable"] = 2, ["nullius-steel-plate"] = 1,
      ["nullius-steel-gear"] = 1, ["nullius-steel-rod"] = 1,
      ["nullius-silica"] = 3}, products = {["nullius-motor-2"] = 1}},
  ["nullius-pump-2-vulcanus"] = {energy = 8,
    ingredients = {["nullius-pump-1"] = 1, ["nullius-motor-2"] = 1,
      ["nullius-pipe-2"] = 2, ["nullius-silicon-insulation"] = 2},
    products = {["nullius-pump-2"] = 1}},
  ["nullius-capacitor-vulcanus"] = {energy = 6,
    ingredients = {["nullius-aluminum-sheet"] = 2, ["nullius-silica"] = 4,
      ["nullius-alumina"] = 1, ["nullius-graphite"] = 1},
    products = {["nullius-capacitor"] = 2}},
  ["nullius-logic-circuit-vulcanus"] = {energy = 5,
    ingredients = {["nullius-silicon-insulation"] = 3,
      ["nullius-aluminum-wire"] = 4,
      ["nullius-polycrystalline-silicon"] = 2, ["nullius-graphite"] = 1},
    products = {["decider-combinator"] = 3}},
  ["nullius-display-panel-vulcanus"] = {energy = 3,
    ingredients = {["decider-combinator"] = 1, ["nullius-glass"] = 1,
      ["nullius-silicon-insulation"] = 1, ["nullius-aluminum-wire"] = 1},
    products = {["display-panel"] = 1}},
  ["nullius-align-identification-card-vulcanus"] = {energy = 8,
    ingredients = {["nullius-steel-sheet"] = 1,
      ["nullius-aluminum-sheet"] = 1},
    products = {["nullius-align-identification-card"] = 1}},
  ["nullius-armor-plate-vulcanus"] = {energy = 12,
    ingredients = {["nullius-steel-plate"] = 3,
      ["nullius-ceramic-powder"] = 6, ["nullius-textile"] = 2,
      ["nullius-silicon-insulation"] = 2},
    products = {["nullius-armor-plate"] = 1}},
  ["nullius-battery-1-vulcanus"] = {energy = 10,
    ingredients = {["nullius-sodium"] = 2, ["nullius-iron-oxide"] = 2,
      ["nullius-carbon-fiber"] = 3, ["nullius-solvent"] = 16,
      ["nullius-aluminum-sheet"] = 3, ["nullius-ceramic-powder"] = 2},
    products = {["nullius-battery-1"] = 1}},
  ["nullius-insulation-vulcanus"] = {energy = 6,
    ingredients = {["nullius-gypsum"] = 3, ["nullius-glass-fiber"] = 2,
      ["nullius-refractory-mix"] = 2, ["nullius-textile"] = 1},
    products = {["nullius-insulation"] = 2}},
  ["nullius-repair-pack-vulcanus"] = {energy = 6,
    ingredients = {["decider-combinator"] = 1,
      ["nullius-fabrication-tool-1"] = 1, ["nullius-steel-gear"] = 2,
      ["nullius-aluminum-sheet"] = 1, ["nullius-aluminum-carbide"] = 1},
    products = {["repair-pack"] = 1}},
  ["nullius-levitation-field-1-vulcanus"] = {energy = 12,
    ingredients = {["copper-cable"] = 6,
      ["nullius-silicon-insulation"] = 4, ["nullius-iron-rod"] = 3,
      ["nullius-sensor-1"] = 1, ["programmable-speaker"] = 2,
      ["nullius-capacitor"] = 3},
    products = {["nullius-levitation-field-1"] = 1}},
  ["nullius-medium-tank-2-vulcanus"] = {energy = 10,
    ingredients = {["storage-tank"] = 1, ["nullius-steel-sheet"] = 2,
      ["nullius-steel-rod"] = 1, ["nullius-glass"] = 2,
      ["nullius-pipe-2"] = 3}, products = {["nullius-medium-tank-2"] = 1}},
  ["nullius-optical-cable-vulcanus"] = {energy = 3,
    ingredients = {["nullius-red-wire"] = 2, ["nullius-glass-fiber"] = 1,
      ["nullius-silicon-insulation"] = 1, ["nullius-epoxy"] = 1,
      ["nullius-argon"] = 1}, products = {["nullius-optical-cable"] = 1}},
  ["nullius-rail-vulcanus"] = {energy = 8,
    ingredients = {["nullius-steel-beam"] = 2,
      ["nullius-refractory-brick"] = 3, ["nullius-steel-rod"] = 1,
      ["nullius-gravel"] = 5}, products = {rail = 3}},
  ["nullius-solar-panel-1-vulcanus"] = {energy = 8,
    ingredients = {["nullius-polycrystalline-silicon"] = 6,
      ["nullius-glass"] = 4, ["nullius-aluminum-sheet"] = 3,
      ["nullius-epoxy"] = 10, ["nullius-aluminum-rod"] = 1},
    products = {["nullius-solar-panel-1"] = 1}},
  ["nullius-transformer-vulcanus"] = {energy = 6,
    ingredients = {["nullius-iron-plate"] = 2,
      ["nullius-heat-pipe-1"] = 1, ["copper-cable"] = 2,
      ["nullius-silicon-insulation"] = 1},
    products = {["nullius-transformer"] = 1}},
  ["nullius-small-electric-pole-vulcanus"] = {energy = 2,
    ingredients = {["nullius-iron-wire"] = 2, ["nullius-iron-rod"] = 1,
      ["nullius-glass"] = 1}, products = {["small-electric-pole"] = 1}},
  ["nullius-bulk-inserter-vulcanus"] = {energy = 7,
    ingredients = {["bob-turbo-inserter"] = 1, ["nullius-motor-2"] = 1,
      ["nullius-bearing"] = 1, ["nullius-silicon-insulation"] = 2,
      ["nullius-sensor-1"] = 1}, products = {["bulk-inserter"] = 1}},
  ["nullius-fast-transport-belt-vulcanus"] = {energy = 8,
    ingredients = {["transport-belt"] = 10, ["nullius-motor-2"] = 1,
      ["nullius-steel-gear"] = 2, ["nullius-silicon-insulation"] = 4,
      ["nullius-lubricant"] = 12}, products = {["fast-transport-belt"] = 8}},
  ["nullius-iron-chest-vulcanus"] = {energy = 3,
    ingredients = {["nullius-iron-sheet"] = 2,
      ["nullius-steel-sheet"] = 4, ["nullius-steel-rod"] = 2,
      ["nullius-silicon-insulation"] = 1},
    products = {["iron-chest"] = 1}},
  ["nullius-car-1-vulcanus"] = {energy = 10,
    ingredients = {["nullius-locomotive-1"] = 1, ["small-lamp"] = 2,
      ["nullius-silicon-insulation"] = 4, ["nullius-steel-rod"] = 4,
      ["nullius-air"] = 20}, products = {["nullius-car-1"] = 1}},
  ["nullius-chassis-2-vulcanus"] = {energy = 30,
    ingredients = {["nullius-steel-plate"] = 12,
      ["nullius-silicon-insulation"] = 8, inserter = 4},
    products = {["nullius-chassis-2"] = 1}},
  ["nullius-gun-vulcanus"] = {energy = 10,
    ingredients = {["nullius-steel-plate"] = 6,
      ["nullius-steel-wire"] = 2, ["nullius-steel-gear"] = 1,
      ["nullius-silicon-insulation"] = 1}, products = {["nullius-gun"] = 1}},
  ["nullius-leg-augmentation-3-vulcanus"] = {energy = 60,
    ingredients = {["nullius-leg-augmentation-2"] = 2,
      ["nullius-pipe-4"] = 4, ["nullius-small-pump-2"] = 2,
      ["nullius-silicon-insulation"] = 8, ["nullius-speed-module-4"] = 1,
      ["nullius-compressed-argon"] = 100, ["nullius-lubricant"] = 40},
    products = {["nullius-leg-augmentation-3"] = 1}},
  ["nullius-refueler-vulcanus"] = {energy = 8,
    ingredients = {["bob-turbo-inserter"] = 1, ["nullius-pump-2"] = 1,
      ["nullius-silicon-insulation"] = 3},
    products = {["nullius-refueler"] = 1}},
  ["nullius-self-repair-pack-vulcanus"] = {energy = 8,
    ingredients = {["nullius-fabrication-tool-2"] = 1,
      ["bob-turbo-inserter"] = 1, ["repair-pack"] = 2,
      ["nullius-steel-plate"] = 2, ["nullius-silicon-insulation"] = 2},
    products = {["nullius-self-repair-pack"] = 10}},
  ["nullius-truck-1-vulcanus"] = {energy = 30,
    ingredients = {["nullius-car-2"] = 2, ["nullius-steel-beam"] = 12,
      ["nullius-steel-plate"] = 25, ["nullius-missile-launcher"] = 3,
      ["nullius-silicon-insulation"] = 8,
      ["nullius-compressed-air"] = 40}, products = {["nullius-truck-1"] = 1}},
  ["nullius-power-switch-vulcanus"] = {energy = 3,
    ingredients = {["copper-cable"] = 2, ["nullius-steel-sheet"] = 1,
      ["nullius-silicon-insulation"] = 1, ["nullius-iron-rod"] = 1},
    products = {["power-switch"] = 1}},
  ["nullius-programmable-speaker-vulcanus"] = {energy = 6,
    ingredients = {["nullius-aluminum-rod"] = 2, ["nullius-red-wire"] = 1,
      ["nullius-silicon-insulation"] = 1, ["nullius-capacitor"] = 1},
    products = {["programmable-speaker"] = 1}},
}

local assertions = 0
local failures = {}

local function check(condition, message)
  assertions = assertions + 1
  if not condition then failures[#failures + 1] = message end
end

local function amounts(entries)
  local result = {}
  for _, entry in pairs(entries) do
    result[entry.name] = (result[entry.name] or 0) + entry.amount
  end
  return result
end

local function check_exact(actual, expected, label)
  for name, amount in pairs(expected) do
    check(actual[name] == amount,
      label .. ": expected " .. amount .. " " .. name .. ", found " ..
        tostring(actual[name] or 0))
  end
  for name, amount in pairs(actual) do
    check(expected[name] == amount,
      label .. ": unexpected " .. amount .. " " .. name)
  end
end

local function run()
  script.on_nth_tick(1, nil)
  local recipes = game.forces.player.recipes
  local identification_card =
    recipes["nullius-align-identification-card-vulcanus"]
  check(identification_card ~= nil,
    "missing Vulcanus identification-card recipe")
  if identification_card then
    check(not identification_card.enabled,
      "Vulcanus identification card is available before Alignment 1")
  end
  local alignment = game.forces.player.technologies["nullius-alignment-1"]
  check(alignment ~= nil, "missing Alignment 1 technology")
  if alignment then
    alignment.enabled = true
    alignment.researched = true
    check(identification_card and identification_card.enabled,
      "Alignment 1 did not unlock the Vulcanus identification card")
  end
  for name, spec in pairs(specs) do
    local recipe = recipes[name]
    check(recipe ~= nil, "missing recipe " .. name)
    if recipe then
      check(recipe.energy == spec.energy,
        name .. ": expected duration " .. spec.energy .. ", found " ..
          tostring(recipe.energy))
      local ingredients = amounts(recipe.ingredients)
      for _, polymer in ipairs({"nullius-plastic", "nullius-rubber",
          "nullius-box-plastic", "nullius-box-rubber"}) do
        check(ingredients[polymer] == nil, name .. " consumes " .. polymer)
      end
      check_exact(ingredients, spec.ingredients, name .. " ingredients")
      check_exact(amounts(recipe.products), spec.products, name .. " products")
    end
  end

  local result = {
    schema = 1,
    case = CASE,
    status = (#failures == 0) and "pass" or "fail",
    factorio_version = script.active_mods.base,
    tick = game.tick,
    assertions = assertions,
    failure_count = #failures,
    failures = failures,
    observations = {recipe_count = 36},
  }
  helpers.write_file(RESULT, helpers.table_to_json(result), false)
  if #failures > 0 then error(helpers.table_to_json(result)) end
end

script.on_nth_tick(1, run)

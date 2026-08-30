local CASE = "vulcanus-boxed-polymer-free"
local RESULT = "factorio-tests/" .. CASE .. ".json"

local specs = {
  ["nullius-boxed-barrel-vulcanus"] = {
    energy = 50,
    ingredients = { ["nullius-box-steel-sheet"] = 2,
      ["nullius-box-aluminum-sheet"] = 2, ["nullius-box-glass"] = 1,
      ["nullius-box-one-way-valve"] = 1 },
    products = { ["nullius-box-barrel"] = 3 },
  },
  ["nullius-boxed-thermite-explosive"] = {
    energy = 150,
    ingredients = { ["nullius-chlorine-barrel"] = 5,
      ["nullius-sulfur-dioxide-barrel"] = 5,
      ["nullius-box-aluminum-powder"] = 4,
      ["nullius-box-red-wire"] = 1, ["nullius-box-green-wire"] = 1,
      ["nullius-small-miner-1"] = 5 },
    products = { ["nullius-box-explosive"] = 1 },
  },
  ["nullius-boxed-logic-circuit-vulcanus"] = {
    energy = 25,
    ingredients = { ["nullius-silicon-insulation"] = 15,
      ["nullius-box-aluminum-wire"] = 4,
      ["nullius-box-polycrystalline-silicon"] = 2,
      ["nullius-box-graphite"] = 1 },
    products = { ["nullius-box-logic-circuit"] = 3 },
  },
  ["nullius-boxed-capacitor-vulcanus"] = {
    energy = 30,
    ingredients = { ["nullius-box-aluminum-sheet"] = 2,
      ["nullius-box-silica"] = 4, ["nullius-box-alumina"] = 1,
      ["nullius-box-graphite"] = 1 },
    products = { ["nullius-box-capacitor"] = 2 },
  },
  ["nullius-boxed-filter-1-vulcanus"] = {
    energy = 40,
    ingredients = { ["nullius-box-silica"] = 2,
      ["nullius-box-graphite"] = 1, ["nullius-box-iron-sheet"] = 1,
      ["nullius-carbon-dioxide"] = 50 },
    products = { ["nullius-box-filter-1"] = 1 },
  },
  ["nullius-boxed-splitter-1-vulcanus"] = {
    energy = 20,
    ingredients = { ["nullius-box-underground-belt-1"] = 2,
      ["nullius-silicon-insulation"] = 10 },
    products = { splitter = 5 },
  },
  ["nullius-boxed-insulated-wire-vulcanus"] = {
    energy = 30,
    ingredients = { ["nullius-box-aluminum-wire"] = 3,
      ["nullius-silicon-insulation"] = 10 },
    products = { ["nullius-box-insulated-wire"] = 4 },
  },
  ["nullius-boxed-one-way-valve-vulcanus"] = {
    energy = 20,
    ingredients = { ["nullius-box-pipe-1"] = 1,
      ["nullius-box-iron-sheet"] = 1 },
    products = { ["nullius-box-one-way-valve"] = 5 },
  },
  ["nullius-boxed-pump-2-vulcanus"] = {
    energy = 40,
    ingredients = { ["nullius-box-pump-1"] = 1,
      ["nullius-box-motor-2"] = 1, ["nullius-box-pipe-2"] = 2,
      ["nullius-silicon-insulation"] = 10 },
    products = { ["nullius-box-pump-2"] = 1 },
  },
  ["nullius-boxed-display-panel-vulcanus"] = {
    energy = 15,
    ingredients = { ["nullius-box-logic-circuit"] = 1,
      ["nullius-box-glass"] = 1, ["nullius-silicon-insulation"] = 5,
      ["nullius-box-aluminum-wire"] = 1 },
    products = { ["nullius-box-display-panel"] = 1 },
  },
  ["nullius-boxed-battery-1-vulcanus"] = {
    energy = 50,
    ingredients = { ["nullius-box-sodium"] = 2,
      ["nullius-box-iron-oxide"] = 2,
      ["nullius-box-carbon-fiber"] = 3, ["nullius-solvent"] = 80,
      ["nullius-box-aluminum-sheet"] = 3,
      ["nullius-box-ceramic-powder"] = 2 },
    products = { ["nullius-box-battery-1"] = 1 },
  },
  ["nullius-boxed-insulation-vulcanus"] = {
    energy = 30,
    ingredients = { ["nullius-box-gypsum"] = 3,
      ["nullius-box-glass-fiber"] = 2,
      ["nullius-refractory-mix"] = 10,
      ["nullius-box-textile"] = 1 },
    products = { ["nullius-box-insulation"] = 2 },
  },
  ["nullius-boxed-repair-pack-vulcanus"] = {
    energy = 30,
    ingredients = { ["nullius-box-logic-circuit"] = 1,
      ["nullius-box-fabrication-tool-1"] = 1,
      ["nullius-box-steel-gear"] = 2,
      ["nullius-box-aluminum-sheet"] = 1,
      ["nullius-box-aluminum-carbide"] = 1 },
    products = { ["nullius-box-repair-pack"] = 1 },
  },
  ["nullius-boxed-levitation-field-1-vulcanus"] = {
    energy = 60,
    ingredients = { ["nullius-box-insulated-wire"] = 6,
      ["nullius-silicon-insulation"] = 20,
      ["nullius-box-iron-rod"] = 3, ["nullius-box-sensor-1"] = 1,
      ["nullius-box-antenna"] = 2, ["nullius-box-capacitor"] = 3 },
    products = { ["nullius-box-levitation-field-1"] = 1 },
  },
  ["nullius-boxed-medium-tank-2-vulcanus"] = {
    energy = 50,
    ingredients = { ["nullius-box-medium-tank-1"] = 1,
      ["nullius-box-steel-sheet"] = 2, ["nullius-box-steel-rod"] = 1,
      ["nullius-box-glass"] = 2, ["nullius-box-pipe-2"] = 3 },
    products = { ["nullius-box-medium-tank-2"] = 1 },
  },
  ["nullius-boxed-optical-cable-vulcanus"] = {
    energy = 15,
    ingredients = { ["nullius-box-red-wire"] = 2,
      ["nullius-box-glass-fiber"] = 1,
      ["nullius-silicon-insulation"] = 5, ["nullius-epoxy"] = 5,
      ["nullius-argon"] = 5 },
    products = { ["nullius-box-optical-cable"] = 1 },
  },
  ["nullius-boxed-rail-vulcanus"] = {
    energy = 40,
    ingredients = { ["nullius-box-steel-beam"] = 2,
      ["nullius-box-refractory-brick"] = 3,
      ["nullius-box-steel-rod"] = 1, ["nullius-box-gravel"] = 5 },
    products = { ["nullius-box-rail"] = 3 },
  },
  ["nullius-boxed-solar-panel-1-vulcanus"] = {
    energy = 40,
    ingredients = { ["nullius-box-polycrystalline-silicon"] = 6,
      ["nullius-box-glass"] = 4, ["nullius-box-aluminum-sheet"] = 3,
      ["nullius-epoxy"] = 50, ["nullius-box-aluminum-rod"] = 1 },
    products = { ["nullius-box-solar-panel-1"] = 1 },
  },
  ["nullius-boxed-transformer-vulcanus"] = {
    energy = 30,
    ingredients = { ["nullius-box-iron-plate"] = 2,
      ["nullius-box-heat-pipe-1"] = 1,
      ["nullius-box-insulated-wire"] = 2,
      ["nullius-silicon-insulation"] = 5 },
    products = { ["nullius-box-transformer"] = 1 },
  },
  ["nullius-boxed-antenna-vulcanus"] = {
    energy = 30,
    ingredients = { ["nullius-box-aluminum-rod"] = 2,
      ["nullius-box-red-wire"] = 1,
      ["nullius-silicon-insulation"] = 5,
      ["nullius-box-capacitor"] = 1 },
    products = { ["nullius-box-antenna"] = 1 },
  },
  ["nullius-boxed-belt-2-vulcanus"] = {
    energy = 40,
    technology = "nullius-mass-production-6",
    ingredients = { ["nullius-box-belt-1"] = 10,
      ["nullius-box-motor-2"] = 1, ["nullius-box-steel-gear"] = 2,
      ["nullius-silicon-insulation"] = 20,
      ["nullius-lubricant"] = 60 },
    products = { ["nullius-box-belt-2"] = 8 },
  },
  ["nullius-boxed-inserter-3-vulcanus"] = {
    energy = 35,
    ingredients = { ["nullius-box-inserter-2"] = 1,
      ["nullius-box-motor-2"] = 1, ["nullius-box-bearing"] = 1,
      ["nullius-silicon-insulation"] = 10,
      ["nullius-box-sensor-1"] = 1 },
    products = { ["nullius-box-inserter-3"] = 1 },
  },
  ["nullius-boxed-power-switch-vulcanus"] = {
    energy = 15,
    ingredients = { ["nullius-box-insulated-wire"] = 2,
      ["nullius-box-steel-sheet"] = 1,
      ["nullius-silicon-insulation"] = 5,
      ["nullius-box-iron-rod"] = 1 },
    products = { ["nullius-box-power-switch"] = 1 },
  },
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

local function research_closure(technology, visited)
  if visited[technology.name] then return end
  visited[technology.name] = true
  for _, prerequisite in pairs(technology.prerequisites) do
    research_closure(prerequisite, visited)
  end
  technology.researched = true
end

local function run()
  script.on_nth_tick(1, nil)
  local force = game.forces.player
  local mass_production_5 = force.technologies["nullius-mass-production-5"]
  local mass_production_6 = force.technologies["nullius-mass-production-6"]
  check(mass_production_5 ~= nil, "missing Mass Production 5")
  check(mass_production_6 ~= nil, "missing Mass Production 6")
  if mass_production_5 and mass_production_6 then
    mass_production_5.researched = false
    mass_production_6.researched = false
    for name in pairs(specs) do
      check(force.recipes[name] and not force.recipes[name].enabled,
        name .. " enabled before its mass production technology")
    end
    research_closure(mass_production_5, {})
    for name, spec in pairs(specs) do
      local expected = spec.technology ~= "nullius-mass-production-6"
      check(force.recipes[name] and force.recipes[name].enabled == expected,
        name .. " has wrong Mass Production 5 unlock state")
    end
    research_closure(mass_production_6, {})
  end
  for name, spec in pairs(specs) do
    local recipe = force.recipes[name]
    check(recipe ~= nil, "missing recipe " .. name)
    if recipe then
      check(recipe.enabled, name .. " not unlocked by mass production")
      check(recipe.energy == spec.energy,
        name .. ": expected duration " .. spec.energy .. ", found " ..
          tostring(recipe.energy))
      local ingredients = amounts(recipe.ingredients)
      check(ingredients["nullius-plastic"] == nil, name .. " consumes plastic")
      check(ingredients["nullius-rubber"] == nil, name .. " consumes rubber")
      check(ingredients["nullius-box-plastic"] == nil,
        name .. " consumes boxed plastic")
      check(ingredients["nullius-box-rubber"] == nil,
        name .. " consumes boxed rubber")
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
    observations = {recipe_count = 23},
  }
  helpers.write_file(RESULT, helpers.table_to_json(result), false)
  if #failures > 0 then error(helpers.table_to_json(result)) end
end

script.on_nth_tick(1, run)

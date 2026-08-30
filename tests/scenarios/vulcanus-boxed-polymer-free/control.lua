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
  local technology = force.technologies["nullius-mass-production-5"]
  check(technology ~= nil, "missing Mass Production 5")
  if technology then
    technology.researched = false
    for name in pairs(specs) do
      check(force.recipes[name] and not force.recipes[name].enabled,
        name .. " enabled before Mass Production 5")
    end
    research_closure(technology, {})
  end
  for name, spec in pairs(specs) do
    local recipe = force.recipes[name]
    check(recipe ~= nil, "missing recipe " .. name)
    if recipe then
      check(recipe.enabled, name .. " not unlocked by Mass Production 5")
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
    observations = {recipe_count = 9},
  }
  helpers.write_file(RESULT, helpers.table_to_json(result), false)
  if #failures > 0 then error(helpers.table_to_json(result)) end
end

script.on_nth_tick(1, run)

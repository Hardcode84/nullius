local CASE = "vulcanus-mining-productivity"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local RECIPES = {
  ["nullius-lava-iron-separation"] = {
    primary = "nullius-molten-iron-bloom",
    ignored = { ["nullius-compressed-volcanic-gas"] = 30, stone = 10 },
  },
  ["nullius-lava-aluminum-separation"] = {
    primary = "nullius-molten-aluminum-bloom",
    ignored = { ["nullius-compressed-volcanic-gas"] = 25, stone = 8 },
  },
  ["nullius-lava-calcite-separation"] = {
    primary = "nullius-crushed-limestone",
    ignored = { ["nullius-compressed-volcanic-gas"] = 20 },
  },
  ["nullius-lava-silica-extraction"] = {
    primary = "nullius-silica",
    ignored = {
      ["nullius-compressed-volcanic-gas"] = 15,
      ["nullius-sulfur-dioxide"] = 10,
      stone = 5,
    },
  },
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

local function product_map(recipe)
  local result = {}
  for _, product in pairs(recipe.products) do result[product.name] = product end
  return result
end

local function check_technology_effects(technology)
  local mining_modifier = nil
  local recipe_changes = {}
  for _, effect in pairs(technology.prototype.effects) do
    if effect.type == "mining-drill-productivity-bonus" then
      check(mining_modifier == nil,
        technology.name .. " has multiple drill productivity effects")
      mining_modifier = effect.modifier
    elseif effect.type == "change-recipe-productivity" then
      recipe_changes[effect.recipe] = effect.change
    end
  end

  check(mining_modifier ~= nil,
    technology.name .. " has no drill productivity effect")
  for recipe_name in pairs(RECIPES) do
    check(close(recipe_changes[recipe_name] or 0, mining_modifier or 0),
      technology.name .. " does not mirror its modifier to " .. recipe_name)
    recipe_changes[recipe_name] = nil
  end
  check(next(recipe_changes) == nil,
    technology.name .. " changes an unexpected recipe")
end

script.on_nth_tick(1, function()
  script.on_nth_tick(1, nil)
  local force = game.forces.player

  local technology_count = 0
  for name, technology in pairs(force.technologies) do
    if string.match(name, "^nullius%-mining%-productivity%-%d+$") then
      technology_count = technology_count + 1
      check_technology_effects(technology)
    end
  end
  check(technology_count == 21,
    "expected 21 mining productivity technologies, found " .. technology_count)

  for recipe_name, expected in pairs(RECIPES) do
    local recipe = prototypes.recipe[recipe_name]
    check(recipe ~= nil, "missing extraction recipe " .. recipe_name)
    if recipe then
      local products = product_map(recipe)
      local primary = products[expected.primary]
      check(primary ~= nil, recipe_name .. " is missing its primary product")
      if primary then
        check((primary.ignored_by_productivity or 0) == 0,
          recipe_name .. " ignores productivity on its primary product")
      end
      for product_name, amount in pairs(expected.ignored) do
        local product = products[product_name]
        check(product ~= nil, recipe_name .. " is missing " .. product_name)
        if product then
          check(product.ignored_by_productivity == amount,
            recipe_name .. " productivity exclusion mismatch for " .. product_name)
        end
      end
    end
  end

  local unrelated = force.recipes["nullius-volcanic-saline"]
  check(unrelated ~= nil, "missing unrelated recipe fixture")
  local unrelated_before = unrelated and unrelated.productivity_bonus or 0

  force.technologies["nullius-mining-productivity-1"].researched = true
  for recipe_name in pairs(RECIPES) do
    check(close(force.recipes[recipe_name].productivity_bonus, 0.02),
      recipe_name .. " did not receive tier 1 mining productivity")
  end
  check(not unrelated or close(unrelated.productivity_bonus, unrelated_before),
    "mining productivity changed an unrelated recipe")

  force.technologies["nullius-mining-productivity-2"].researched = true
  for recipe_name in pairs(RECIPES) do
    check(close(force.recipes[recipe_name].productivity_bonus, 0.03),
      recipe_name .. " did not accumulate tier 2 mining productivity")
  end

  observations.technology_count = technology_count
  observations.tier_2_productivity = 0.03
  finish()
end)

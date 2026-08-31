local CASE = "recipe-surface-conditions"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local AMBIENT_TEMPERATURE = "nullius-ambient-temperature"

local assertions = 0
local failures = {}

local function check(condition, message)
  assertions = assertions + 1
  if not condition then failures[#failures + 1] = message end
end

local function finish(observations)
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

script.on_nth_tick(1, function()
  script.on_nth_tick(1, nil)
  local restricted_recipes = 0
  local conditions = 0
  local cool_recipes = 0
  local hot_recipes = 0

  for name, recipe in pairs(prototypes.recipe) do
    local recipe_conditions = recipe.surface_conditions or {}
    if string.sub(name, 1, 8) == "nullius-" and
        #recipe_conditions > 0 then
      restricted_recipes = restricted_recipes + 1
      local cool = false
      local hot = false
      for _, condition in pairs(recipe_conditions) do
        conditions = conditions + 1
        check(condition.property == AMBIENT_TEMPERATURE,
          name .. " uses non-temperature surface condition " ..
          condition.property)
        if condition.max and condition.max <= 50 then cool = true end
        if condition.min and condition.min >= 100 then hot = true end
      end
      if cool then cool_recipes = cool_recipes + 1 end
      if hot then hot_recipes = hot_recipes + 1 end
    end
  end

  check(restricted_recipes > 0, "no restricted Nullius recipes found")
  check(cool_recipes > 0, "no cool-environment recipes found")
  check(hot_recipes > 0, "no hot-environment recipes found")
  finish({
    restricted_recipe_count = restricted_recipes,
    surface_condition_count = conditions,
    cool_recipe_count = cool_recipes,
    hot_recipe_count = hot_recipes,
  })
end)

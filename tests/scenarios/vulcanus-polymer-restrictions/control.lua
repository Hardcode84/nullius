local CASE = "vulcanus-polymer-restrictions"
local RESULT = "factorio-tests/" .. CASE .. ".json"

local polymer_products = {
  ["nullius-plastic"] = true,
  ["nullius-rubber"] = true,
  ["nullius-box-plastic"] = true,
  ["nullius-box-rubber"] = true,
}

local import_recipes = {
  ["nullius-box-plastic"] = true,
  ["nullius-unbox-plastic"] = true,
  ["nullius-box-rubber"] = true,
  ["nullius-unbox-rubber"] = true,
}

local assertions = 0
local failures = {}

local function check(condition, message)
  assertions = assertions + 1
  if not condition then failures[#failures + 1] = message end
end

local function nauvis_only(recipe)
  for _, condition in pairs(recipe.surface_conditions or {}) do
    if condition.property == "nullius-nauvis-environment" and
        condition.min == 1 and condition.max == 1 then
      return true
    end
  end
  return false
end

local function run()
  script.on_nth_tick(1, nil)
  local restricted_count = 0
  local import_count = 0
  local found_imports = {}
  for name, recipe in pairs(prototypes.recipe) do
    local produces_polymer = false
    for _, product in pairs(recipe.products) do
      if polymer_products[product.name] then produces_polymer = true end
    end
    if produces_polymer then
      if import_recipes[name] then
        import_count = import_count + 1
        found_imports[name] = true
        check(not nauvis_only(recipe), name .. " blocks imported polymers")
      else
        restricted_count = restricted_count + 1
        check(nauvis_only(recipe), name .. " is not Nauvis-only")
      end
    end
  end
  for name in pairs(import_recipes) do
    check(found_imports[name], "missing polymer import recipe " .. name)
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
    observations = {
      restricted_recipe_count = restricted_count,
      import_recipe_count = import_count,
    },
  }
  helpers.write_file(RESULT, helpers.table_to_json(result), false)
  if #failures > 0 then error(helpers.table_to_json(result)) end
end

script.on_nth_tick(1, run)

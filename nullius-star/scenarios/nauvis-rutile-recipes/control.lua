local CASE = "nauvis-rutile-recipes"
local RESULT = "factorio-tests/" .. CASE .. ".json"

local assertions = 0
local failures = {}

local function check(condition, message)
  assertions = assertions + 1
  if not condition then failures[#failures + 1] = message end
end

local function amount(entries, name)
  for _, entry in pairs(entries) do
    if entry.name == name then return entry.amount end
  end
  return 0
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
  }
  helpers.write_file(RESULT, helpers.table_to_json(result), false)
  if #failures > 0 then error(helpers.table_to_json(result)) end
end

local function check_recipe(recipe, expected)
  check(recipe ~= nil, "missing recipe " .. expected.name)
  if not recipe then return end
  check(recipe.energy == expected.energy,
    expected.name .. " has wrong crafting time")
  check(#recipe.ingredients == expected.ingredient_count,
    expected.name .. " has unexpected ingredients")
  check(#recipe.products == expected.product_count,
    expected.name .. " has unexpected products")
  for name, expected_amount in pairs(expected.ingredients) do
    check(amount(recipe.ingredients, name) == expected_amount,
      expected.name .. " has wrong " .. name .. " input")
  end
  for name, expected_amount in pairs(expected.products) do
    check(amount(recipe.products, name) == expected_amount,
      expected.name .. " has wrong " .. name .. " output")
  end
end

local function run()
  script.on_nth_tick(1, nil)
  check(prototypes.recipe["nullius-silica-2"] == nil,
    "dominated silica-2 recipe still exists")
  check(prototypes.recipe["nullius-boxed-silica-2"] == nil,
    "dominated boxed silica-2 recipe still exists")

  check_recipe(prototypes.recipe["nullius-rutile"], {
    name = "nullius-rutile",
    energy = 12,
    ingredient_count = 2,
    product_count = 4,
    ingredients = {
      ["nullius-sand"] = 50,
      ["nullius-acid-sulfuric"] = 150,
    },
    products = {
      ["nullius-rutile"] = 1,
      ["nullius-mineral-dust"] = 5,
      ["nullius-sludge"] = 80,
      ["nullius-carbon-dioxide"] = 25,
    },
  })

  check_recipe(prototypes.recipe["nullius-boxed-rutile"], {
    name = "nullius-boxed-rutile",
    energy = 60,
    ingredient_count = 2,
    product_count = 4,
    ingredients = {
      ["nullius-box-sand"] = 50,
      ["nullius-acid-sulfuric"] = 750,
    },
    products = {
      ["nullius-box-rutile"] = 1,
      ["nullius-box-mineral-dust"] = 5,
      ["nullius-sludge"] = 400,
      ["nullius-carbon-dioxide"] = 125,
    },
  })

  finish()
end

script.on_nth_tick(1, run)

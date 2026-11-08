-- Declare every item weight with one rule, so rocket cargo does not depend on
-- recipe flags. Factorio's own calculation clamps items whose recipe forbids
-- productivity to one stack per launch and floors weights to whole grams,
-- turning zero into an unliftable sentinel. Productivity flags therefore moved
-- weights far down every chain. Declared weights are kept; this pass runs last.
--
-- Rule, in grams:
--   recipe: the recipe named like the item, else the first non-catalyst
--     recipe by name, else the first recipe by name; hidden recipes and
--     recipes that forbid decomposition are skipped
--   weight: (item ingredient weights + 100 per fluid unit)
--     / expected item products * ingredient_to_weight_coefficient (0.5)
--   floor: at least one gram
--   fallback: the default item weight without a recipe, with zero recipe
--     weight or products, and for the item that closes a recipe loop
local DEFAULT = data.raw["utility-constants"].default.default_item_weight
local FLUID_UNIT_WEIGHT = 100
local MINIMUM = 1

local items = {}
for item_type in pairs(assert(defines.prototypes.item, "item prototype types")) do
  for name, item in pairs(data.raw[item_type] or {}) do items[name] = item end
end

local function expected_count(product)
  local amount = product.amount or (product.amount_min + product.amount_max) / 2
  return amount * (product.probability or 1) + (product.extra_count_fraction or 0)
end

local producers = {}
for _, recipe in pairs(data.raw.recipe) do
  if not recipe.hidden and recipe.allow_decomposition ~= false then
    for _, product in pairs(recipe.results or {}) do
      if product.type == "item" and items[product.name] then
        local list = producers[product.name] or {}
        producers[product.name] = list
        list[#list + 1] = recipe
      end
    end
  end
end

local function catalyst(recipe, name)
  for _, ingredient in pairs(recipe.ingredients or {}) do
    if ingredient.name == name then return true end
  end
  return false
end

local function weight_recipe(name)
  local recipes = producers[name]
  if not recipes then return nil end
  table.sort(recipes, function(a, b) return a.name < b.name end)
  for _, recipe in ipairs(recipes) do
    if recipe.name == name then return recipe end
  end
  for _, recipe in ipairs(recipes) do
    if not catalyst(recipe, name) then return recipe end
  end
  return recipes[1]
end

items["nullius-blank-recording-module"].weight = 1000
-- Packing returned media preserves the correlation cargo budget.
items["nullius-box-blank-recording-module"].weight = 5000
for _, planet in ipairs(require("shared.astronomy").planets) do
  items[require("shared.astronomy").recording(planet)].weight = 1000
end

local weights = {}
local visiting = {}

local function weigh(name)
  if weights[name] then return weights[name] end
  local item = items[name]
  if item.weight then
    weights[name] = item.weight
    return item.weight
  end
  if visiting[name] then return nil end
  visiting[name] = true
  local result = DEFAULT
  local recipe = weight_recipe(name)
  if recipe then
    local recipe_weight, products = 0, 0
    for _, ingredient in pairs(recipe.ingredients or {}) do
      if ingredient.type == "fluid" then
        recipe_weight = recipe_weight + ingredient.amount * FLUID_UNIT_WEIGHT
      else
        local ingredient_weight = weigh(ingredient.name)
        if ingredient_weight == nil then
          recipe_weight = nil
          break
        end
        recipe_weight = recipe_weight + ingredient_weight * ingredient.amount
      end
    end
    for _, product in pairs(recipe.results or {}) do
      if product.type == "item" then products = products + expected_count(product) end
    end
    if recipe_weight and recipe_weight > 0 and products > 0 then
      result = math.max(MINIMUM,
        recipe_weight / products * (item.ingredient_to_weight_coefficient or 0.5))
    end
  end
  visiting[name] = nil
  weights[name] = result
  return result
end

local names = {}
for name, item in pairs(items) do
  local flags = {}
  for _, flag in pairs(item.flags or {}) do flags[flag] = true end
  if not (flags["only-in-cursor"] and flags["spawnable"]) then names[#names + 1] = name end
end
table.sort(names)
for _, name in ipairs(names) do
  items[name].weight = weigh(name)
end

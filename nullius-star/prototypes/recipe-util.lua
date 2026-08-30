local recipe_util = {}

local function normalize_ingredient(ingredient, key)
  if type(ingredient) == "number" and type(key) == "string" then
    return {type = "item", name = key, amount = ingredient}
  end
  if type(ingredient) ~= "table" then
    error("Invalid recipe ingredient " .. serpent.line(ingredient))
  end
  local normalized = table.deepcopy(ingredient)
  normalized.name = normalized.name or normalized[1]
  normalized.amount = normalized.amount or normalized[2]
  normalized.type = normalized.type or "item"
  normalized[1] = nil
  normalized[2] = nil
  if not normalized.name or not normalized.amount then
    error("Invalid recipe ingredient " .. serpent.line(ingredient))
  end
  return normalized
end

function recipe_util.merge_ingredient(ingredients, addition)
  local normalized = normalize_ingredient(addition)
  for index, ingredient in ipairs(ingredients) do
    ingredient = normalize_ingredient(ingredient)
    ingredients[index] = ingredient
    if ingredient.type == normalized.type and
        ingredient.name == normalized.name and
        ingredient.temperature == normalized.temperature and
        ingredient.minimum_temperature == normalized.minimum_temperature and
        ingredient.maximum_temperature == normalized.maximum_temperature and
        ingredient.fluidbox_index == normalized.fluidbox_index then
      ingredient.amount = ingredient.amount + normalized.amount
      return
    end
  end
  ingredients[#ingredients + 1] = normalized
end

local function substitute_ingredients(source_name, source, substitutions,
    found)
  local ingredients = {}
  local replaced = {}
  for key, ingredient in pairs(source) do
    local normalized = normalize_ingredient(ingredient, key)
    local replacement = substitutions[normalized.name]
    if replacement then
      if replaced[normalized.name] then
        error("Duplicate substituted ingredient " .. normalized.name ..
          " in " .. source_name)
      end
      replaced[normalized.name] = true
      found[normalized.name] = true
      for _, addition in ipairs(replacement) do
        recipe_util.merge_ingredient(ingredients, addition)
      end
    else
      recipe_util.merge_ingredient(ingredients, normalized)
    end
  end
  return ingredients
end

function recipe_util.substitute_recipe(source_name, name, substitutions,
    overrides)
  local source = data.raw.recipe[source_name]
  if not source then error("Missing source recipe: " .. source_name) end
  local recipe = table.deepcopy(source)
  recipe.name = name
  local found = {}
  local ingredient_tables = 0
  if recipe.ingredients then
    ingredient_tables = ingredient_tables + 1
    recipe.ingredients = substitute_ingredients(
      source_name, recipe.ingredients, substitutions, found)
  end
  for _, difficulty in ipairs({"normal", "expensive"}) do
    if recipe[difficulty] and recipe[difficulty].ingredients then
      ingredient_tables = ingredient_tables + 1
      recipe[difficulty].ingredients = substitute_ingredients(
        source_name, recipe[difficulty].ingredients, substitutions, found)
    end
  end
  if ingredient_tables == 0 then
    error("Recipe has no ingredients: " .. source_name .. " " ..
      serpent.line(source))
  end
  for ingredient_name in pairs(substitutions) do
    if not found[ingredient_name] then
      error("Recipe " .. source_name .. " does not consume " ..
        ingredient_name .. ": " .. serpent.line(source))
    end
  end
  recipe.allow_decomposition = false
  for key, value in pairs(overrides or {}) do
    if key == "ingredients" then
      error("Invalid substitution override: ingredients")
    end
    recipe[key] = table.deepcopy(value)
  end
  return recipe
end

return recipe_util

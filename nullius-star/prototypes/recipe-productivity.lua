local recipe_productivity = {}

local function category_set(categories)
  assert(type(categories) == "table", "recipe categories must be a table")

  local result = {}
  for index, category in ipairs(categories) do
    assert(type(category) == "string" and category ~= "",
      "recipe category " .. index .. " must be a non-empty string")
    result[category] = true
  end
  return result
end

local function matches_category(recipe, categories)
  if categories[recipe.category or "crafting"] then return true end

  for _, category in ipairs(recipe.additional_categories or {}) do
    if categories[category] then return true end
  end
  return false
end

function recipe_productivity.recipe_names(categories)
  local selected = {}
  local categories_by_name = category_set(categories)

  for name, recipe in pairs(data.raw.recipe) do
    if recipe.maximum_productivity ~= 0 and
        matches_category(recipe, categories_by_name) then
      selected[#selected + 1] = name
    end
  end

  table.sort(selected)
  return selected
end

function recipe_productivity.effects(categories, change)
  assert(type(change) == "number" and change > 0,
    "recipe productivity change must be a positive number")

  local effects = {}
  for _, recipe in ipairs(recipe_productivity.recipe_names(categories)) do
    effects[#effects + 1] = {
      type = "change-recipe-productivity",
      recipe = recipe,
      change = change,
    }
  end
  return effects
end

return recipe_productivity

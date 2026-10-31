local recipe_productivity = {}
local organic_assembly = {}
for _, spec in ipairs(require("shared.fulgora-organics")) do
  organic_assembly[spec.name] = true
  organic_assembly[spec.name:gsub("^nullius%-", "nullius-boxed-")] = true
end

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
  local candidates = recipe.categories
  if not candidates then
    if categories[recipe.category or "crafting"] then return true end
    candidates = recipe.additional_categories or {}
  end

  for _, category in ipairs(candidates) do
    if categories[category] then return true end
  end
  return false
end

function recipe_productivity.recipe_names(categories)
  local selected = {}
  local categories_by_name = category_set(categories)

  for name, recipe in pairs(data.raw.recipe) do
    if not organic_assembly[name] and recipe.maximum_productivity ~= 0 and
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

function recipe_productivity.product_effects(products, change)
  local selected = {}
  for _, name in ipairs(products) do
    selected[name] = true
    if BOXED_ITEM_MAPPING[name] then selected[BOXED_ITEM_MAPPING[name]] = true end
    local compressed = name:gsub("^nullius%-", "nullius-compressed-")
    if data.raw.fluid[compressed] then selected[compressed] = true end
  end
  local excluded = {
    packaging=true, recycling=true, ["recycling-or-hand-crafting"]=true,
    ["nullius-barrel"]=true,["nullius-unbarrel"]=true,
    compression=true,decompression=true,["turbine-open"]=true,["turbine-closed"]=true,
    ["nullius-gas-void"]=true,["nullius-liquid-void"]=true,["nullius-reinjection"]=true,
  }
  local names = {}
  for name, recipe in pairs(data.raw.recipe) do
    if recipe.allow_productivity ~= false and recipe.maximum_productivity ~= 0 and
        not organic_assembly[name] and not matches_category(recipe, excluded) and
        not name:match("%-recycling$") then
      for _, result in ipairs(recipe.results or {}) do
        if selected[result.name] then names[#names+1]=name; break end
      end
    end
  end
  table.sort(names)
  local effects = {}
  for _, name in ipairs(names) do
    effects[#effects+1]={type="change-recipe-productivity",recipe=name,change=change}
  end
  return effects
end

return recipe_productivity

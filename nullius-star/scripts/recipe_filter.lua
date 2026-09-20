local recipe_filter = {}
local category_lists = string.match(script.active_mods.base, "^2%.1%.") ~= nil

-- Cold path: force initialization and configuration changes.
local function is_testing_tool(recipe)
  local categories
  if category_lists then
    categories = recipe.categories
  else
    if recipe.category == "ee-testing-tool" then return true end
    categories = recipe.additional_categories or {}
  end
  for _, category in pairs(categories) do
    if category == "ee-testing-tool" then return true end
  end
  return false
end

function recipe_filter.broken_disabled(name)
  if (storage.nullius_broken_status == nil) then return true end
  local count = storage.nullius_broken_status[name]
  if ((count == nil) or (count < 1)) then return true end
  return false
end

function recipe_filter.apply(force)
  for _, recipe in pairs(force.recipes) do
    if (string.sub(recipe.name, 1, 8) == "nullius-") then
      if ((string.sub(recipe.name, 9, 15) == "broken-") and
          recipe_filter.broken_disabled(recipe.name)) then
        recipe.enabled = false
      end
    elseif ((string.sub(recipe.order, 1, 8) ~= "nullius-") and
        (string.sub(recipe.name, 1, 13) ~= "fill-nullius-") and
        (string.sub(recipe.name, 1, 14) ~= "empty-nullius-") and
        (not is_testing_tool(recipe)) and
        (string.sub(recipe.name, 1, 5) ~= "bpsb-")) then
      recipe.enabled = false
    end
  end
end

return recipe_filter

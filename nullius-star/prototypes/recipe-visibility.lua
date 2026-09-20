local visibility = {}

local function is_testing_tool(recipe)
  local categories = recipe.categories
  if not categories then
    if recipe.category == "ee-testing-tool" then return true end
    categories = recipe.additional_categories or {}
  end
  for _, category in pairs(categories) do
    if category == "ee-testing-tool" then return true end
  end
  return false
end

local function is_exempt(recipe)
  return string.sub(recipe.name, 1, 8) == "nullius-" or
    (recipe.order and string.sub(recipe.order, 1, 8) == "nullius-") or
    string.sub(recipe.name, 1, 13) == "fill-nullius-" or
    string.sub(recipe.name, 1, 14) == "empty-nullius-" or
    string.sub(recipe.name, 1, 5) == "bpsb-" or
    is_testing_tool(recipe)
end

function visibility.unmark(item)
  for index, flag in pairs(item.flags or {}) do
    if flag == "temphidden" then
      item.flags[index] = nil
      return true
    end
  end
  return false
end

function visibility.hide(recipe, prototypes)
  if not is_exempt(recipe) then
    recipe.hidden = true
    recipe.enabled = false
    return
  end
  for _, product in pairs(recipe.results or {}) do
    if product.name and product.type ~= "fluid" then
      local item = prototypes[product.type][product.name]
      if item then visibility.unmark(item) end
    end
  end
end

function visibility.restrict(recipe)
  if string.sub(recipe.name, 1, 13) == "fill-nullius-" or
      string.sub(recipe.name, 1, 14) == "empty-nullius-" then
    recipe.GCKI_ignore = true
  elseif not is_exempt(recipe) then
    recipe.enabled = false
    recipe.allow_as_intermediate = false
    recipe.allow_decomposition = false
    if recipe.order == nil then recipe.order = "zzz-hidden" end
  end
end

return visibility

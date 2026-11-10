local ICONPATH = "__nullius-star__/graphics/icons/"
local ENTITYPATH = "__nullius-star__/graphics/entity/"

nullius_non_productivity_categories = {
  ["nullius-electrolysis"] = true,
  ["nullius-centrifuging"] = true,
  ["nullius-gas-void"] = true,
  ["nullius-liquid-void"] = true,
  ["nullius-power-sink"] = true,
  ["nullius-barrel"] = true,
  ["nullius-unbarrel"] = true,
  ["air-filtration-recipe"] = true,
  ["compression"] = true,
  ["decompression"] = true,
  ["water-pumping"] = true,
  ["seawater-pumping"] = true,
  ["combustion"] = true,
  ["boiling"] = true,
  ["pressure-boiling"] = true,
  ["turbine-open"] = true,
  ["turbine-closed"] = true
}

local function non_productivity_category(recipe)
  for _, category in pairs(recipe.categories or {recipe.category}) do
    if nullius_non_productivity_categories[category] then return true end
  end
  return false
end

for _,recipe in pairs(data.raw.recipe) do
  if (string.sub(recipe.name, 1, 8) == "nullius-") or
      (recipe.order and string.sub(recipe.order, 1, 8) == "nullius-") then
    local allowed = recipe.allow_productivity ~= false and
      recipe.no_productivity ~= true and
      not non_productivity_category(recipe)
    recipe.allow_productivity = allowed
    -- Module eligibility alone does not exclude native machine productivity.
    if not allowed then recipe.maximum_productivity = 0 end
  end
  recipe.no_productivity = nil
end

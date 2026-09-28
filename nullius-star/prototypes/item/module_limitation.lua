local ICONPATH = "__nullius-star__/graphics/icons/"
local ENTITYPATH = "__nullius-star__/graphics/entity/"

nullius_non_productivity_categories = {
  ["nullius-electrolysis"] = true,
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

for _,recipe in pairs(data.raw.recipe) do
  if (string.sub(recipe.name, 1, 8) == "nullius-") or
      (recipe.order and string.sub(recipe.order, 1, 8) == "nullius-") then
    local allowed = recipe.allow_productivity ~= false and
      recipe.no_productivity ~= true and
      not nullius_non_productivity_categories[recipe.category]
    recipe.allow_productivity = allowed
    -- Module eligibility alone does not exclude native machine productivity.
    if not allowed then recipe.maximum_productivity = 0 end
  end
  recipe.no_productivity = nil
end

-- The runner supplies actual pre-file dependencies from a fresh full 2.0 load.
local fixture = require("fixture")
local modern = require("factorio-version").is_2_1
local original_recipes = table.deepcopy(data.raw.recipe)
local function icon(prototype)
  prototype.icons = nil
  prototype.icon = "__base__/graphics/icons/iron-plate.png"
  prototype.icon_size = 64
end
local function category(name)
  if not data.raw["recipe-category"][name] then
    data:extend({{type="recipe-category",name=name}})
  end
end
local function group(name)
  if name and not data.raw["item-subgroup"][name] then
    data:extend({{type="item-subgroup",name=name,group="intermediate-products"}})
  end
end
local function item(name, stack)
  if fixture.products[name] then return end
  for kind in pairs(defines.prototypes.item) do
    if data.raw[kind] and data.raw[kind][name] then return end
  end
  data:extend({{type="item",name=name,stack_size=stack or 100,
    icon="__base__/graphics/icons/iron-plate.png",icon_size=64}})
end
for name, stack in pairs(fixture.items) do item(name, stack) end
for name, fluid in pairs(fixture.fluids) do
  icon(fluid)
  group(fluid.subgroup)
  fluid.auto_barrel = false
  data:extend({fluid})
end
for _, recipes in ipairs({fixture.inputs, fixture.recipes}) do
  for name, recipe in pairs(recipes) do
    group(recipe.subgroup)
    for _, cat in ipairs(recipe.categories or {recipe.category or "crafting"}) do category(cat) end
    for _, parts in ipairs({recipe.ingredients or {}, recipe.results or {}}) do
      for _, part in pairs(parts) do
        if part.type == "item" then item(part.name) end
      end
    end
  end
end
for _, product in pairs(fixture.products) do group(product.subgroup) end
data:extend({{type="surface-property",name="nullius-ambient-temperature",default_value=100}})
-- Unused source recipes are removed after the file executes. They are inputs,
-- not substitutes for the recipes under test.
for name, recipe in pairs(fixture.inputs) do
  if modern then
    recipe.categories = recipe.categories or {recipe.category or "crafting"}
    recipe.category = nil
    recipe.show_amount_in_title = nil
    recipe.always_show_products = nil
    for _, product in ipairs(recipe.results or {}) do
      if product.probability then
        product.independent_probability = product.probability
        product.probability = nil
      end
    end
  end
  data.raw.recipe[name] = recipe
end
if alignment_enabled then
  data.raw.technology["nullius-alignment-1"] = table.deepcopy(fixture.alignment)
else
  data.raw.recipe["nullius-align-identification-card"] = nil
end
require("prototypes.planet.vulcanus-recipes")
for name in pairs(fixture.inputs) do
  if not fixture.recipes[name] then data.raw.recipe[name] = original_recipes[name] end
end
for name in pairs(fixture.recipes) do
  local recipe = data.raw.recipe[name]
  if recipe then icon(recipe) end
end
for name, product in pairs(fixture.products) do icon(data.raw[product.type][name]) end
if alignment_enabled then
  data:extend({{type="mod-data",name="vulcanus-alignment-check",
    data={effects=table.deepcopy(data.raw.technology["nullius-alignment-1"].effects)}}})
  data.raw.technology["nullius-alignment-1"] = nil
end

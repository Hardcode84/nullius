-- Capture the inputs and outputs of the complete file before later mod stages.
local before = table.deepcopy(data.raw.recipe)
local fluids = table.deepcopy(data.raw.fluid)
local items = {}
for kind in pairs(defines.prototypes.item) do
  for name, item in pairs(data.raw[kind] or {}) do items[name] = item.stack_size end
end
local alignment = table.deepcopy(data.raw.technology["nullius-alignment-1"])
require("prototypes.planet.vulcanus-recipes")
local recipes = {}
for name, recipe in pairs(data.raw.recipe) do
  if not before[name] or serpent.line(before[name]) ~= serpent.line(recipe) then
    recipes[name] = table.deepcopy(recipe)
  end
end
local products = {}
for _, name in ipairs({"nullius-molten-iron-bloom", "nullius-molten-aluminum-bloom", "nullius-aluminum-chloride", "nullius-iron-chloride", "nullius-refractory-mix", "nullius-metallurgic-pack"}) do
  products[name] = table.deepcopy(data.raw.item[name] or data.raw.tool[name])
end
data:extend({{type="mod-data",name="vulcanus-capture",data={
  inputs=before, fluids=fluids, items=items, alignment=alignment,
  recipes=recipes, products=products,
  alignment_after=table.deepcopy(data.raw.technology["nullius-alignment-1"]),
}}})

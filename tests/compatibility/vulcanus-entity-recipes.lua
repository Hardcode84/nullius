local cases=require("scenarios/vulcanus-entity-recipes/fixture")
data:extend({{type="surface-property",name="nullius-ambient-temperature",default_value=0}})
for _,case in ipairs(cases) do
  if not data.raw["recipe-category"][case.category] then data:extend({{type="recipe-category",name=case.category}}) end
  for _,parts in ipairs({case.ingredients,case.products}) do
    for _,part in ipairs(parts) do
      if part.type=="fluid" and not data.raw.fluid[part.name] then
        local fluid=table.deepcopy(data.raw.fluid.water)
        fluid.name=part.name
        data:extend({fluid})
      elseif part.type=="item" and not data.raw.item[part.name] then
        data:extend({{type="item",name=part.name,stack_size=100,icon="__base__/graphics/icons/iron-plate.png"}})
      end
    end
  end
end
require("vulcanus-entity-source")

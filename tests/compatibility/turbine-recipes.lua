local cases=require("scenarios/turbine-recipes/fixture")
for _,name in ipairs({"large-crafting","huge-assembly","turbine-open","turbine-closed"}) do
  if not data.raw["recipe-category"][name] then data:extend({{type="recipe-category",name=name}}) end
end
for _,name in ipairs({"energy-backup","boxed-fluid-energy","turbine-open","turbine-closed"}) do
  data:extend({{type="item-subgroup",name=name,group="production",order="z"}})
end
for _,case in ipairs(cases) do
  for _,list in ipairs({case.ingredients,case.products}) do for _,part in ipairs(list) do
    if not data.raw[part.type][part.name] then
      if part.type=="fluid" then
        local fluid=table.deepcopy(data.raw.fluid.water)
        fluid.name=part.name
        data:extend({fluid})
      else
        data:extend({{type="item",name=part.name,stack_size=100,
          icon="__base__/graphics/icons/steam-turbine.png"}})
      end
    end
  end end
end
require("turbine-recipes-source")

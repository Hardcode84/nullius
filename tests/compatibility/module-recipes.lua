local cases=require("scenarios/module-recipes/fixture")
local modules=require("scenarios/module-recipes/modules")
local module_names={}
for _,case in ipairs(modules) do
  module_names[case.name]=true
  if not data.raw["module-category"][case.category] then
    data:extend({{type="module-category",name=case.category}})
  end
end
for _,name in ipairs({"tiny-assembly","medium-only-assembly","nanotechnology"}) do
  if not data.raw["recipe-category"][name] then data:extend({{type="recipe-category",name=name}}) end
end
for _,name in ipairs({"module-1","module-2","boxed-module-1","boxed-module-2","coprocessors"}) do
  data:extend({{type="item-subgroup",name=name,group="production",order="z"}})
end
for _,case in ipairs(cases) do
  for _,parts in ipairs({case.ingredients,case.products}) do
    for _,part in ipairs(parts) do
      if not module_names[part.name] and not data.raw.item[part.name] then
        data:extend({{type="item",name=part.name,stack_size=100,icon="__base__/graphics/icons/iron-plate.png"}})
      end
    end
  end
  if case.name:find("^nullius%-coprocessor%-") then
    local equipment=table.deepcopy(data.raw["battery-equipment"]["battery-equipment"])
    equipment.name=case.name:gsub("nullius%-coprocessor", "nullius-upgrade-coprocessor")
    equipment.take_result=case.name
    data:extend({equipment})
  end
end
require("module-recipes-source")
for _,case in ipairs(modules) do
  local module=data.raw.module[case.name]
  assert(module.category==case.category and module.categories==nil,case.name.." scalar module category")
  assert(module.tier==case.tier,case.name.." tier")
  for effect,amount in pairs(case.effect) do assert(module.effect[effect]==amount,case.name.." "..effect) end
  for effect in pairs(module.effect) do assert(case.effect[effect]~=nil,case.name.." extra effect") end
end

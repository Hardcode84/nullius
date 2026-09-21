require("legacyAngels")
require("drone-reskin")
local cases=require("scenarios/intermediate-recipes/fixture")
for _,case in ipairs(cases) do
  if not data.raw["recipe-category"][case.category] then data:extend({{type="recipe-category",name=case.category}}) end
  for _,parts in ipairs({case.ingredients,case.products}) do
    for _,part in ipairs(parts) do
      if part.type=="fluid" and not data.raw.fluid[part.name] then
        local fluid=table.deepcopy(data.raw.fluid.water)
        fluid.name=part.name
        data:extend({fluid})
      end
    end
  end
end
for _,name in ipairs({"alumina","aluminum-ingot","boxed-aluminum-1","boxed-aluminum-2","boxed-calcium","boxed-canister","boxed-concrete","boxed-copper","boxed-electrical","boxed-fluid","boxed-glass","boxed-hangar","boxed-iron","boxed-mechanical","boxed-organic-2","boxed-science","boxed-silicon","boxed-steel","boxed-terrain","boxed-titanium","calcium-product","chlorine-chemistry","copper","iron-product","masonry-material","nuclear","research-pack","research-pack-2","titanium-product"}) do
  if not data.raw["item-subgroup"][name] then data:extend({{type="item-subgroup",name=name,group="production",order="z"}}) end
end
require("intermediate-source")
local function has_item(name)
  for _,kind in ipairs({"item","gun","ammo","selection-tool","capsule","module","tool","repair-tool","item-with-entity-data","rail-planner"}) do
    if data.raw[kind][name] then return true end
  end
  return false
end
local initially_enabled={}
for _,case in ipairs(cases) do
  assert(data.raw.recipe[case.name].enabled==(initially_enabled[case.name] or false),case.name.." research required")
  for _,parts in ipairs({case.ingredients,case.products}) do
    for _,part in ipairs(parts) do
      if part.type=="item" and not has_item(part.name) then
        data:extend({{type="item",name=part.name,stack_size=100,icon="__base__/graphics/icons/iron-plate.png"}})
      end
    end
  end
end

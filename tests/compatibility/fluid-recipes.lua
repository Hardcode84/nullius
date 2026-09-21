require("legacyAngels")
require("drone-reskin")
local cases=require("scenarios/fluid-recipes/fixture")
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
for _,name in ipairs({"acid-chemistry","air-filtration","air-filtration-recipe","alumina","biochemistry","biology-bacteria","boiling","boxed-aluminum-1","boxed-biology","boxed-canister","boxed-fluid","boxed-organic-1","boxed-organic-2","boxed-science","boxed-sodium","canister-emptying","canisters","carbon","chlorine-chemistry","combustion","compressed-air","compression","decompression","hydrocarbon","inorganic-chemistry","nuclear","nullius-electrolysis","nullius-water-treatment","ore-recovery","organic-chemistry","organic-material-1","organic-material-2","pressure-boiling","reforming","research-pack","research-pack-2","sodium-product","waste-management"}) do
  if not data.raw["item-subgroup"][name] then data:extend({{type="item-subgroup",name=name,group="production",order="z"}}) end
end
require("fluid-source")
local function has_item(name)
  for _,kind in ipairs({"item","gun","ammo","selection-tool","capsule","module","tool","repair-tool","item-with-entity-data","rail-planner"}) do
    if data.raw[kind][name] then return true end
  end
  return false
end
local initially_enabled={["nullius-air-filtration"]=true,["nullius-freshwater"]=true,["nullius-seawater"]=true}
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

-- Recipe tints also read these two fluids.
for _,name in ipairs({"nullius-caustic-solution","nullius-copper-solution"}) do
  if not data.raw.fluid[name] then
    local fluid=table.deepcopy(data.raw.fluid.water)
    fluid.name=name
    data:extend({fluid})
  end
end
-- Reprioritization reads the original generator item icon.
local generator=table.deepcopy(data.raw.item["nullius-portable-generator-backup"] or data.raw.item["iron-plate"])
generator.name="nullius-portable-generator-backup"
generator.icon=nil
generator.icons={{icon="__nullius-star__/graphics/icons/equipment/generator-backup.png",icon_size=64}}
data:extend({generator})
local cases=require("scenarios/equipment-recipes/fixture")
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
for _,name in ipairs({"boxed-beacon","boxed-demolition","boxed-electrical","boxed-hangar","boxed-renewable","boxed-robot","solar"}) do
  if not data.raw["item-subgroup"][name] then data:extend({{type="item-subgroup",name=name,group="production",order="z"}}) end
end
require("equipment-source")
local function has_item(name)
  for _,kind in ipairs({"item","gun","ammo","selection-tool","capsule","module","tool","repair-tool","item-with-entity-data","rail-planner"}) do
    if data.raw[kind][name] then return true end
  end
  return false
end
for _,case in ipairs(cases) do
  assert(data.raw.recipe[case.name].enabled==false,case.name.." research required")
  for _,parts in ipairs({case.ingredients,case.products}) do
    for _,part in ipairs(parts) do
      if part.type=="item" and not has_item(part.name) then
        data:extend({{type="item",name=part.name,stack_size=100,icon="__base__/graphics/icons/iron-plate.png"}})
      end
    end
  end
end

local cases=require("scenarios/boxing-recipes/fixture")
if not data.raw["recipe-category"].packaging then data:extend({{type="recipe-category",name="packaging"}}) end
for _,name in ipairs({"boxing-misc","unboxing-misc","research-pack"}) do
  if not data.raw["item-subgroup"][name] then
    data:extend({{type="item-subgroup",name=name,group="production",order="z"}})
  end
end
local bases={item="iron-plate",module="speed-module",ammo="firearm-magazine",
  capsule="cliff-explosives",tool="automation-science-pack",["repair-tool"]="repair-pack"}
local create_boxed_item=require("boxing-generator")
for _,case in ipairs(cases) do
  local kind=case.type or "item"
  local item
  if kind=="tool" then
    item={type="tool",durability=1,icon="__base__/graphics/icons/automation-science-pack.png"}
  else
    item=table.deepcopy(data.raw[kind][bases[kind]])
  end
  item.name="nullius-"..case.name
  item.stack_size=case.size
  if case.science then item.subgroup="research-pack" end
  data:extend({item})
  create_boxed_item(case.name,nil,"z",nil,case.type,case.override)
  local box=data.raw.item["nullius-box-"..case.name]
  -- Production assigns box icons after this generator runs.
  box.icon="__base__/graphics/icons/iron-plate.png"
  assert(box.stack_size==case.boxes,case.name.." box capacity")
  for _,prefix in ipairs({"nullius-box-","nullius-unbox-"}) do
    local recipe=data.raw.recipe[prefix..case.name]
    assert(recipe.enabled==false and recipe.no_productivity==true,case.name.." unlock and productivity")
    assert(recipe.allow_as_intermediate==false,case.name.." intermediate restriction")
  end
  assert(data.raw.recipe["nullius-unbox-"..case.name].allow_decomposition==false,case.name.." decomposition restriction")
end

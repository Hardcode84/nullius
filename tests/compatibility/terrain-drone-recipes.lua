local cases=require("scenarios/terrain-drone-recipes/fixture")
for _,name in ipairs({"huge-crafting","tiny-crafting"}) do
  if not data.raw["recipe-category"][name] then data:extend({{type="recipe-category",name=name}}) end
end
for _,name in ipairs({"drone","drone-remote","paving","paving-remote"}) do
  if not data.raw["item-subgroup"][name] then data:extend({{type="item-subgroup",name=name,group="production",order="z"}}) end
end
local owned={}
for _,case in ipairs(cases) do owned[case.name]=true end
for _,case in ipairs(cases) do
  for _,part in ipairs(case.ingredients) do
    if not owned[part.name] and not data.raw.item[part.name] then
      data:extend({{type="item",name=part.name,stack_size=100,icon="__base__/graphics/icons/iron-plate.png"}})
    end
  end
  data:extend({{type="ammo-category",name=case.name}})
  local projectile=table.deepcopy(data.raw["artillery-projectile"]["artillery-projectile"])
  projectile.name=case.name:gsub("%-drone%-","-drone-projectile-")
  local flare=table.deepcopy(data.raw["artillery-flare"]["artillery-flare"])
  flare.name=case.name:gsub("%-drone%-","-flare-")
  data:extend({projectile,flare})
end
require("terrain-drone-source")
for _,case in ipairs(cases) do
  local ammo=data.raw.ammo[case.name]
  assert(ammo.ammo_category==case.name and ammo.stack_size==5,case.name.." drone ammunition")
  assert(data.raw.recipe[case.name].enabled==false,case.name.." research required")
end

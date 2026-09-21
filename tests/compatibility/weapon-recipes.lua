local cases=require("scenarios/weapon-recipes/fixture")
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
for _,name in ipairs({"vehicle-weapon","demolitions","boxed-demolition","drone-launcher"}) do
  if not data.raw["item-subgroup"][name] then data:extend({{type="item-subgroup",name=name,group="production",order="z"}}) end
end
require("weapon-source")
-- Replace earlier item placeholders with the actual gun, ammo, and tool types.
for _,kind in ipairs({"gun","ammo","selection-tool"}) do
  for name in pairs(data.raw[kind]) do
    if name:find("^nullius%-") then data.raw.item[name]=nil end
  end
end
local function has_item(name)
  for _,kind in ipairs({"item","gun","ammo","selection-tool","capsule","module","tool","repair-tool","item-with-entity-data"}) do
    if data.raw[kind][name] then return true end
  end
  return false
end
for _,case in ipairs(cases) do
  assert(data.raw.recipe[case.name].enabled==false,case.name.." research required")
  for _,part in ipairs(case.ingredients) do
    if part.type=="item" and not has_item(part.name) then
      data:extend({{type="item",name=part.name,stack_size=100,icon="__base__/graphics/icons/iron-plate.png"}})
    end
  end
end
for tier=1,2 do
  local projectile=table.deepcopy(data.raw.projectile.rocket)
  projectile.name="nullius-missile-"..tier
  data:extend({projectile})
end
local turret=table.deepcopy(data.raw["electric-turret"]["laser-turret"])
turret.name="nullius-turret"
turret.minable={mining_time=1,result=turret.name}
data:extend({turret})

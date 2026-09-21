assert(settings.startup["nullius-alignment"].value==require("alignment-setting-expected"),"alignment startup setting")
local cases=require("scenarios/alignment-recipes/fixture")
if not settings.startup["nullius-alignment"].value then
  require("alignment-recipes-source")
  for _,case in ipairs(cases) do
    assert(data.raw.recipe[case.name]==nil,case.name.." disabled recipe")
    for _,kind in ipairs({"item","capsule","gun","ammo"}) do
      assert(data.raw[kind][case.name]==nil,case.name.." disabled item")
    end
  end
  for i=1,7 do assert(data.raw.technology["nullius-alignment-"..i]==nil,"disabled alignment technology") end
  return
end
local owned={}
for _,case in ipairs(cases) do for _,part in ipairs(case.products) do owned[part.name]=true end end
for _,category in ipairs({"tiny-crafting","small-crafting","medium-crafting","large-crafting","huge-crafting","nullius-electrolysis"}) do
  if not data.raw["recipe-category"][category] then data:extend({{type="recipe-category",name=category}}) end
end
data:extend({{type="item-subgroup",name="alignment",group="production",order="z"},
  {type="ammo-category",name="nullius-conscription"}})
for _,case in ipairs(cases) do
  for _,part in ipairs(case.ingredients) do
    if not owned[part.name] and not data.raw.item[part.name] then
      data:extend({{type="item",name=part.name,stack_size=100,icons={{icon="__base__/graphics/icons/iron-plate.png",icon_size=64}}}})
    end
  end
end
-- Supply science tools; earlier recipe fixtures need only item placeholders.
for _,pack in ipairs({"mechanical","electrical","chemical","physics","astronomy"}) do
  local name="nullius-"..pack.."-pack"
  table.insert(data.raw.lab.lab.inputs,name)
  data.raw.item[name]=nil
  data:extend({{type="tool",name=name,durability=1,stack_size=100,icon="__base__/graphics/icons/automation-science-pack.png"}})
end
for _,suffix in ipairs({"identification-card","invitation-card","conscription-charge"}) do
  local projectile=table.deepcopy(data.raw.projectile.grenade)
  projectile.name="nullius-align-"..suffix
  data:extend({projectile})
end
for name,kind in pairs({["conscription-turret"]="ammo-turret",["concordance-transmitter"]="radar"}) do
  local entity=table.deepcopy(data.raw[kind][kind=="radar" and "radar" or "gun-turret"])
  entity.name="nullius-align-"..name
  entity.minable={mining_time=1,result=entity.name}
  data:extend({entity})
end
require("alignment-recipes-source")
for i,case in ipairs(require("scenarios/alignment-recipes/technologies")) do
  local tech=data.raw.technology["nullius-alignment-"..i]
  assert(tech.unit.count==case.count and tech.unit.time==case.time,"research cost")
  assert(#tech.unit.ingredients==1 and tech.unit.ingredients[1][1]=="nullius-"..case.pack.."-pack"
    and tech.unit.ingredients[1][2]==1,"science pack")
  assert(#tech.effects==#case.unlocks,"unlock count")
  for j,name in ipairs(case.unlocks) do assert(tech.effects[j].recipe=="nullius-"..name,"unlock recipe") end
  assert(tech.enabled==false and tech.ignore_tech_cost_multiplier==true,"research restrictions")
  if i==1 then assert(tech.prerequisites==nil,"first alignment research")
  else assert(#tech.prerequisites==1 and tech.prerequisites[1]=="nullius-alignment-"..(i-1),"research chain") end
end
local repair=data.raw.recipe["nullius-broken-align-transponder"]
assert(repair.allow_as_intermediate==false and repair.allow_decomposition==false,"repair restrictions")

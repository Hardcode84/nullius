local modern=require("factorio-version").is_2_1
data:extend({{type="recipe-category",name="small-crafting"},{type="item-subgroup",name="solar",group="other"}})
for _,name in ipairs({"induction-coil","nullius-capacitor","nullius-aluminum-rod"}) do
  data:extend({{type="item",name=name,subgroup="other",order="probe",icon="__base__/graphics/icons/iron-plate.png",stack_size=100}})
end
local recipe=table.deepcopy(data.raw.recipe["iron-gear-wheel"])
recipe.name="induction-coil"
recipe.energy_required=7
recipe.results={{type="item",name="induction-coil",amount=2}}
recipe.enabled=false
if modern then recipe.categories={"crafting","advanced-crafting"} else recipe.category="crafting" end
data:extend({recipe})
for _,name in ipairs({"nullius-geology-pack","nullius-climatology-pack","nullius-mechanical-pack","nullius-electrical-pack","nullius-chemical-pack","nullius-physics-pack"}) do
  local pack=table.deepcopy(data.raw[modern and "item" or "tool"]["automation-science-pack"])
  pack.name=name
  data:extend({pack})
  table.insert(data.raw.lab.lab.inputs,name)
end
for _,name in ipairs({"induction-technology1","induction-technology2","induction-technology3","induction-technology4","induction-technology5","nullius-electronics-1","nullius-energy-distribution-2","nullius-energy-distribution-3","nullius-projection-1","nullius-broadcasting-2","nullius-battery-storage-4"}) do
  local tech=table.deepcopy(data.raw.technology.automation)
  tech.name=name
  tech.effects={}
  tech.prerequisites={}
  data:extend({tech})
end
data.raw.technology["induction-technology1"].effects={{type="unlock-recipe",recipe="induction-coil"}}
require("executor")

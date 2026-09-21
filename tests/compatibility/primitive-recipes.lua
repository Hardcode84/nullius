local cases=require("scenarios/primitive-recipes/fixture")
for _,name in ipairs({"hangar-2","robot","small-logistic-storage"}) do
  if not data.raw["item-subgroup"][name] then data:extend({{type="item-subgroup",name=name,group="production",order="z"}}) end
end
local targets={
  {"roboport","roboport","nullius-clockwork-roboport"},
  {"logistic-robot","logistic-robot","nullius-clockwork-logistic-robot"},
  {"logistic-container","storage-chest","nullius-primitive-storage-chest"},
  {"logistic-container","passive-provider-chest","nullius-primitive-supply-chest"},
  {"logistic-container","requester-chest","nullius-primitive-demand-chest"},
}
for _,target in ipairs(targets) do
  local entity=table.deepcopy(data.raw[target[1]][target[2]])
  entity.name=target[3]
  entity.minable=nil
  entity.next_upgrade=nil
  entity.fast_replaceable_group=nil
  data:extend({entity})
end
-- Isolated template items use a single icon; the production constructor copies layers.
for _,name in ipairs({"nullius-hangar-1","nullius-logistic-bot-1","nullius-small-storage-chest-1","nullius-small-supply-chest-1","nullius-small-demand-chest-1"}) do
  local item=assert(data.raw.item[name],name.." template")
  if not item.icons then
    item.icons={{icon=assert(item.icon,name.." icon"),icon_size=item.icon_size or 64}}
    item.icon=nil
  end
end
require("primitive-source")
for _,case in ipairs(cases) do
  assert(data.raw.recipe[case.name].enabled==false,case.name.." research required")
  for _,part in ipairs(case.ingredients) do assert(data.raw.item[part.name],part.name.." item dependency") end
end

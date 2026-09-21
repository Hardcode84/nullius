local cases=require("scenarios/drone-recipes/fixture")
for _,name in ipairs({"small-crafting","huge-crafting","nanotechnology"}) do
  if not data.raw["recipe-category"][name] then data:extend({{type="recipe-category",name=name}}) end
end
for _,name in ipairs({"drone","drone-remote","paving","paving-remote","asteroid-1","asteroid-2",
  "farming","farming-remote","drone-launcher","space","armor"}) do
  if not data.raw["item-subgroup"][name] then data:extend({{type="item-subgroup",name=name,group="production",order="z"}}) end
end
require("drone-reskin")
require("drone-source")
-- Replace earlier fixtures' item placeholders with the production item types.
for _,kind in ipairs({"ammo","capsule","item-with-entity-data"}) do
  for name in pairs(data.raw[kind]) do
    if name:find("^nullius%-") then data.raw.item[name]=nil end
  end
end
local function has_item(name)
  for _,kind in ipairs({"item","ammo","capsule","item-with-entity-data","module","tool","gun","repair-tool"}) do
    if data.raw[kind][name] then return true end
  end
  return false
end
for _,case in ipairs(cases) do
  local recipe=data.raw.recipe[case.name]
  assert((recipe.hidden or false)==case.hidden,case.name.." visibility")
  if case.restricted then
    assert(recipe.allow_as_intermediate==false and recipe.allow_decomposition==false,case.name.." restrictions")
  end
  assert(recipe.enabled==false,case.name.." research required")
  for _,part in ipairs(case.ingredients) do
    if not has_item(part.name) then
      data:extend({{type="item",name=part.name,stack_size=100,icon="__base__/graphics/icons/iron-plate.png"}})
    end
  end
end
for name,ammo in pairs(data.raw.ammo) do
  if name:find("^nullius%-") and ammo.ammo_type.action and ammo.ammo_type.action.action_delivery
      and ammo.ammo_type.action.action_delivery.type=="artillery" then
    if not data.raw["ammo-category"][ammo.ammo_category] then
      data:extend({{type="ammo-category",name=ammo.ammo_category}})
    end
    local projectile_name=ammo.ammo_type.action.action_delivery.projectile
    if not data.raw["artillery-projectile"][projectile_name] then
      local projectile=table.deepcopy(data.raw["artillery-projectile"]["artillery-projectile"])
      projectile.name=projectile_name
      data:extend({projectile})
    end
  end
end
for name,capsule in pairs(data.raw.capsule) do
  if name:find("^nullius%-") and capsule.capsule_action.type=="artillery-remote" then
    local flare_name=capsule.capsule_action.flare
    if not data.raw["artillery-flare"][flare_name] then
      local flare=table.deepcopy(data.raw["artillery-flare"]["artillery-flare"])
      flare.name=flare_name
      data:extend({flare})
    end
  end
end
for tier=1,2 do
  for _,spec in ipairs({{"drone-launcher","artillery-turret"},{"drone-carrier","artillery-wagon"}}) do
    local name="nullius-"..spec[1].."-"..tier
    local entity=table.deepcopy(data.raw[spec[2]][spec[2]])
    entity.name=name
    entity.minable={mining_time=1,result=name}
    data:extend({entity})
  end
end
local character=table.deepcopy(data.raw.character.character)
character.name="nullius-android-2"
data:extend({character})

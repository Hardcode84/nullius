-- Grounding coils reserve the same space as wind turbines.
local coils={}
local NAMES=require('shared.grounding-coils')
local by_name={}
for _,name in ipairs(NAMES) do by_name[name]=true end
function coils.is_coil(name) return by_name[name]==true end
local PREFIX='nullius-grounding-collision-'
function coils.built(entity)
  if not coils.is_coil(entity.name) then return end
  build_wind_mod_entity(entity,PREFIX)
  storage.nullius_wind_mod_entities[entity.unit_number].grounding=true
end
function coils.cloned(entity)
  if entity.name:find(PREFIX,1,true)==1 then entity.destroy();return true end
  coils.built(entity)
  return false
end
function coils.rebuild()
  for unit,row in pairs(storage.nullius_wind_mod_entities) do
    if row.grounding then destroy_wind_mod_entity(unit) end
  end
  for _,surface in pairs(game.surfaces) do
    for _,field in pairs(surface.find_entities_filtered{
        name={PREFIX..'horizontal',PREFIX..'vertical'}}) do field.destroy() end
    for _,entity in pairs(surface.find_entities_filtered{name=NAMES}) do coils.built(entity) end
  end
end
return coils

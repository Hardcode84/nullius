-- Grounding coils reserve the same space as wind turbines.
local coils={}
local NAME='nullius-grounding-coil'
local PREFIX='nullius-grounding-collision-'
function coils.built(entity)
  if entity.name~=NAME then return end
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
    for _,entity in pairs(surface.find_entities_filtered{name=NAME}) do coils.built(entity) end
  end
end
return coils

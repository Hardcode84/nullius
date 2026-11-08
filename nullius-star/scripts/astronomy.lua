local astronomy = {}
local spec = require("shared.astronomy")
local PROPERTY = "nullius-storm-intensity"

local function planet_name(surface)
  local planet=surface.planet
  if not planet then return nil end
  for _,name in ipairs(spec.planets) do
    if planet.name==(name=="nauvis" and name or "nullius-"..name) then return name end
  end
end

local function interference(surface)
  return planet_name(surface)=="fulgora" and math.min(1,math.max(0,surface.get_property(PROPERTY)/100)) or 0
end

local function select_recording(entity)
  local planet=planet_name(entity.surface)
  local recipe=planet and entity.force.recipes[spec.recording(planet)]
  local name=recipe and recipe.enabled and recipe.name or nil
  local current=entity.get_recipe()
  if (current and current.name or nil)~=name then
    entity.recipe_locked=false
    local removed=entity.set_recipe(name)
    for _,stack in ipairs(removed) do
      entity.surface.spill_item_stack{position=entity.position,stack=stack,force=entity.force,enable_looted=true,allow_belts=false}
    end
  end
  entity.recipe_locked=true
  return name~=nil
end

-- Cold lifecycle path; the storm driver visits only Fulgora groups.
local function refresh(surface_index, force_index)
  local rows={}
  for unit,row in pairs(storage.nullius_dishes) do
    if row.surface==surface_index and row.force==force_index then
      if row.entity.valid then rows[#rows+1]=row else
        destroy_wind_mod_entity(unit)
        storage.nullius_dishes[unit]=nil
      end
    end
  end
  if #rows==0 then return end
  local noise=interference(rows[1].entity.surface)
  local share=(1-noise)/math.sqrt(#rows)
  for _,row in ipairs(rows) do
    local entity=row.entity
    local ready=select_recording(entity)
    if row.share~=share then
      entity.local_effect={speed=share-1,consumption=share-1}
      row.share=share
    end
    local stopped=not ready or share==0
    if entity.disabled_by_script~=stopped then entity.disabled_by_script=stopped end
    local status=ready and string.format("%.2f:%.2f",share*100,noise*100) or "locked"
    if row.status~=status then
      entity.custom_status={diode=stopped and defines.entity_status_diode.red or defines.entity_status_diode.green,
        label=ready and {"nullius-astronomy.array-status",string.format("%.2f",share*100),string.format("%.2f",noise*100)}
          or {"nullius-astronomy.no-recording"}}
      row.status=status
    end
  end
end

function astronomy.remove(unit)
  local row=storage.nullius_dishes[unit]
  if not row then return end
  destroy_wind_mod_entity(unit)
  storage.nullius_dishes[unit]=nil
  refresh(row.surface,row.force)
end

function astronomy.built(entity)
  if not spec.is_dish(entity.name) then return end
  astronomy.remove(entity.unit_number)
  build_wind_mod_entity(entity,spec.field_prefix)
  storage.nullius_wind_mod_entities[entity.unit_number].dish=true
  storage.nullius_dishes[entity.unit_number]={entity=entity,surface=entity.surface.index,force=entity.force.index}
  refresh(entity.surface.index,entity.force.index)
end

function astronomy.cloned(entity)
  if entity.name:find(spec.field_prefix,1,true)==1 then entity.destroy();return true end
  astronomy.built(entity)
  return false
end

function astronomy.refresh_all()
  local groups={}
  for unit,row in pairs(storage.nullius_dishes) do
    if row.entity.valid then
      row.surface=row.entity.surface.index;row.force=row.entity.force.index
      local key=row.surface..":"..row.force
      groups[key]={row.surface,row.force}
    else destroy_wind_mod_entity(unit);storage.nullius_dishes[unit]=nil end
  end
  for _,group in pairs(groups) do refresh(group[1],group[2]) end
end

function astronomy.rebuild()
  storage.nullius_dishes={}
  for unit,row in pairs(storage.nullius_wind_mod_entities) do
    if row.dish then destroy_wind_mod_entity(unit) end
  end
  for _,surface in pairs(game.surfaces) do
    for _,field in pairs(surface.find_entities_filtered{name={spec.field_prefix.."horizontal",spec.field_prefix.."vertical"}}) do field.destroy() end
    for _,entity in pairs(surface.find_entities_filtered{name=spec.dishes}) do astronomy.built(entity) end
  end
  astronomy.update_storms()
end

function astronomy.research_changed(event)
  local name=event.research.name
  if name=="nullius-astronomy" or name=="nullius-vulcanus-radio-astronomy" or name=="nullius-fulgora-radio-astronomy" then
    astronomy.refresh_all()
  end
end

function astronomy.update_storms()
  for _,surface in pairs(game.surfaces) do
    if planet_name(surface)=="fulgora" then
      local t=surface.daytime
      local night
      if t<surface.dusk or t>=surface.dawn then night=0
      elseif t<surface.evening then night=(t-surface.dusk)/(surface.evening-surface.dusk)
      elseif t<surface.morning then night=1
      else night=(surface.dawn-t)/(surface.dawn-surface.morning) end
      local intensity=25+75*night
      if surface.get_property(PROPERTY)~=intensity then
        surface.set_property(PROPERTY,intensity)
        local forces={}
        for _,row in pairs(storage.nullius_dishes) do
          if row.surface==surface.index then forces[row.force]=true end
        end
        for force in pairs(forces) do refresh(surface.index,force) end
      end
    end
  end
end

script.on_event(defines.events.script_raised_teleported,function(event)
  if spec.is_dish(event.entity.name) then astronomy.built(event.entity) end
end)

if script.active_mods["factorio-test-support"] then
  remote.add_interface("nullius-test-astronomy",{rebuild=astronomy.rebuild})
end
return astronomy

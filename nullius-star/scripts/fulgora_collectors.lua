-- Lifecycle path only. Native lightning and electric networks transfer energy.
local collectors = {}
local config = require("shared.fulgora-collectors")
local function eligible(pole)
  return pole.valid and pole.type=="electric-pole" and pole.surface.planet and
    pole.surface.planet.name=="nullius-fulgora"
end

function collectors.remove(unit)
  local row = storage.fulgora_collectors[unit]
  if not row then return end
  storage.fulgora_collectors[unit] = nil
  storage.fulgora_collector_owners[row.registration] = nil
  if row.helper.valid then row.helper.destroy() end
end

function collectors.add(pole)
  if pole.type~="electric-pole" then return end
  if not eligible(pole) then collectors.remove(pole.unit_number); return end
  local row = storage.fulgora_collectors[pole.unit_number]
  local profile = config.by_pole[pole.name] or config.default
  if row and row.helper.valid and row.helper.name == profile.name then
    assert(row.helper.teleport(pole.position), "Cannot move pole collector")
    return
  end
  local offline=row and row.grid_offline or false
  local grace=row and row.grid_grace or 0
  local energy=row and row.helper.valid and row.helper.energy or 0
  if row then collectors.remove(pole.unit_number) end
  -- Fast replacement invalidates the old pole before its destruction event.
  -- Remove its collector now so the replacement never gets a duplicate.
  for _,helper in pairs(pole.surface.find_entities_filtered{name=config.names,position=pole.position,radius=0.1}) do
    local previous=storage.fulgora_collector_helpers[script.register_on_object_destroyed(helper)]
    local owner=previous and storage.fulgora_collectors[previous]
    if owner and not owner.pole.valid then
      offline=offline or owner.grid_offline or false
      grace=math.max(grace,owner.grid_grace or 0)
      energy=energy+helper.energy
      collectors.remove(previous)
    end
  end
  local helper = assert(pole.surface.create_entity{
    name=profile.name, position=pole.position, force="neutral", quality=pole.quality,
  }, "Cannot create pole collector")
  -- Electricity follows native supply areas, including across forces. Neutral
  -- helpers need no polling when a pole changes force or forces are merged.
  helper.energy=math.min(energy,helper.electric_buffer_size)
  helper.destructible=false
  helper.operable=false
  local registration=script.register_on_object_destroyed(pole)
  storage.fulgora_collectors[pole.unit_number]={pole=pole,helper=helper,registration=registration,grid_offline=offline,grid_grace=grace}
  storage.fulgora_collector_owners[registration]=pole.unit_number
  local helper_registration=script.register_on_object_destroyed(helper)
  storage.fulgora_collector_helpers[helper_registration]=pole.unit_number
end

function collectors.destroyed(event)
  local unit=storage.fulgora_collector_owners[event.registration_number]
  if unit then collectors.remove(unit); return true end
  unit=storage.fulgora_collector_helpers[event.registration_number]
  if not unit then return false end
  storage.fulgora_collector_helpers[event.registration_number]=nil
  local row=storage.fulgora_collectors[unit]
  if row and not row.helper.valid then
    if row.pole.valid then collectors.add(row.pole) else collectors.remove(unit) end
  end
  return true
end

function collectors.cloned(entity)
  -- clone_area may copy a helper before or after its pole. Discard that copy;
  -- only the pole's clone event may create the new owned helper.
  if config.by_name[entity.name] then entity.destroy() else collectors.add(entity) end
end

function collectors.rebuild()
  storage.fulgora_collectors=storage.fulgora_collectors or {}
  storage.fulgora_collector_owners=storage.fulgora_collector_owners or {}
  storage.fulgora_collector_helpers=storage.fulgora_collector_helpers or {}
  for unit,row in pairs(storage.fulgora_collectors) do
    if not eligible(row.pole) then collectors.remove(unit) end
  end
  local owned={}
  for _,surface in pairs(game.surfaces) do
    if surface.planet and surface.planet.name=="nullius-fulgora" then
      for _,pole in pairs(surface.find_entities_filtered{type="electric-pole"}) do collectors.add(pole) end
    end
  end
  for _,row in pairs(storage.fulgora_collectors) do owned[row.helper.unit_number]=true end
  for _,surface in pairs(game.surfaces) do
    for _,helper in pairs(surface.find_entities_filtered{name=config.names}) do
      if not owned[helper.unit_number] then helper.destroy() end
    end
  end
end

script.on_event(defines.events.script_raised_teleported,function(event)
  collectors.add(event.entity)
  grounding_coils.built(event.entity)
end)
return collectors

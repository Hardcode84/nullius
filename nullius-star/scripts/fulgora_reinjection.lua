local reinjection={}
local bases={}
local research={reinjection="nullius-primitive-filtration",deep="nullius-copper-production"}
for tier=1,2 do
  for mode in pairs(research) do bases["nullius-extractor-"..tier.."-"..mode]="nullius-extractor-"..tier end
end

local function on_vent(entity)
  local surface=entity.surface
  if not surface.planet or surface.planet.name~="nullius-fulgora" then return false end
  local p=entity.position
  return surface.count_entities_filtered{name="nullius-hydrocarbon-vent",
    area={{p.x-0.99,p.y-0.99},{p.x+0.99,p.y+0.99}}}>0
end
local function unlocked(force,mode)
  return force.technologies[research[mode]].researched
end

-- Switching preserves health, electrical charge, ghost tags and circuit wires.
-- Installed modules return to the ground. Fluid contents are discarded.
function reinjection.replace(entity,name,force)
  local ghost=entity.type=="entity-ghost"
  local health=not ghost and entity.health
  local energy=not ghost and entity.energy
  local tags=ghost and entity.tags
  local modules={}
  if not ghost then
    local inventory=entity.get_module_inventory()
    if inventory then modules=inventory.get_contents() end
  end
  local wires={}
  for id,connector in pairs(entity.get_wire_connectors(false)) do
    for _,connection in pairs(connector.connections) do
      wires[#wires+1]={id=id,target=connection.target,origin=connection.origin}
    end
  end
  local replacement=assert(replace_pump_valve(entity,name,force),"Cannot switch extractor mode")
  if ghost then replacement.tags=tags else
    replacement.health=health
    replacement.energy=math.min(energy,replacement.electric_buffer_size)
  end
  for _,wire in ipairs(wires) do
    assert(replacement.get_wire_connector(wire.id,true).connect_to(wire.target,false,wire.origin),
      "Cannot restore extractor circuit wire")
  end
  for _,stack in ipairs(modules) do
    replacement.surface.spill_item_stack{position=replacement.position,stack=stack,
      enable_looted=true,allow_belts=false,use_start_position_on_failure=true}
  end
  return replacement
end

-- Deep drilling and reinjection require a Fulgora vent. Locked placements become extractors;
-- invalid real placements return their item, while invalid ghosts are removed.
function reinjection.built(entity)
  local ghost=entity.type=="entity-ghost"
  local name=ghost and entity.ghost_name or entity.name
  local base=bases[name]
  if not base then return entity end
  if not on_vent(entity) then
    local surface,position,quality=entity.surface,entity.position,entity.quality
    entity.destroy()
    if not ghost then
      surface.spill_item_stack{position=position,stack={name=base,count=1,quality=quality},
        enable_looted=true,allow_belts=false,use_start_position_on_failure=true}
    end
    return nil
  end
  if not unlocked(entity.force,name:match("%-(%a+)$")) then return reinjection.replace(entity,base,entity.force) end
  return entity
end

function reinjection.register()
  local transitions=require("scripts.transitions")
  for tier=1,2 do
    local base="nullius-extractor-"..tier
    local inject,deep=base.."-reinjection",base.."-deep"
    local function edge(from,to,mode)
      transitions.register(from,to,{
        condition=mode and function(entity,force) return unlocked(force,mode) and on_vent(entity) end or nil,
        replace_fn=reinjection.replace,
      })
    end
    edge(base,inject,"reinjection")
    edge(base,deep,"deep")
    edge(inject,deep,"deep")
    edge(inject,base)
    edge(deep,base)
  end
end
return reinjection

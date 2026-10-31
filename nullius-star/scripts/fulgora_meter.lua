local meter={}
local OUTPUT="nullius-grid-meter-output"
local PANEL="nullius_grid_meter"
local TAG="nullius_grid_meter"
local keys={"offered","demand"}
local names={}
for _,name in ipairs(require("shared.supercapacitors").machines) do
  names[name]=true;names[name.."-supercapacitor"]=true
end
local function eligible(entity)
  return entity and entity.valid and entity.surface.planet and
    entity.surface.planet.name=="nullius-fulgora" and
    names[entity.type=="entity-ghost" and entity.ghost_name or entity.name]
end
local function selected(settings)
  return settings and (settings.offered or settings.demand)
end
local function signal(value)
  if not value then return nil end
  local kind=value.type or "item"
  local catalogs={item=prototypes.item,fluid=prototypes.fluid,virtual=prototypes.virtual_signal,
    entity=prototypes.entity,recipe=prototypes.recipe,["space-location"]=prototypes.space_location,
    ["asteroid-chunk"]=prototypes.asteroid_chunk,quality=prototypes.quality}
  assert(catalogs[kind] and catalogs[kind][value.name],"Invalid grid meter signal")
  assert(not value.quality or prototypes.quality[value.quality],"Invalid grid meter signal quality")
  return {type=kind,name=value.name,quality=value.quality or "normal"}
end
local function normalize(settings)
  local result={}
  for _,key in ipairs(keys) do result[key]=signal(settings and settings[key]) end
  return result
end
function meter.settings(entity)
  if not eligible(entity) then return {} end
  if entity.type=="entity-ghost" then return table.deepcopy((entity.tags or {})[TAG] or {}) end
  local row=storage.nullius_grid_meters[entity.unit_number]
  return row and table.deepcopy(row.settings) or {}
end
local function connect(row)
  for _,id in ipairs({defines.wire_connector_id.circuit_red,defines.wire_connector_id.circuit_green}) do
    local host=row.entity.get_wire_connector(id,true)
    local output=row.output.get_wire_connector(id,true)
    if not host.is_connected_to(output,defines.wire_origin.script) then
      assert(host.connect_to(output,false,defines.wire_origin.script),"Cannot connect grid meter output")
    end
  end
end
local function create_output(row)
  row.output=assert(row.entity.surface.create_entity{name=OUTPUT,position=row.entity.position,force=row.entity.force})
  row.output.destructible=false
  row.output.operable=false
  connect(row)
end
local function write(row)
  local behavior=row.output.get_or_create_control_behavior()
  local section=behavior.sections_count>0 and behavior.get_section(1) or behavior.add_section()
  for i,key in ipairs(keys) do
    if row.settings[key] then section.set_slot(i,{value=row.settings[key],min=row.values[key]})
    else section.clear_slot(i) end
  end
end
function meter.remove(entity)
  local id=entity.unit_number
  local row=id and storage.nullius_grid_meters[id]
  if not row then return end
  if row.output.valid then row.output.destroy() end
  storage.nullius_grid_meters[id]=nil
end
-- Empty settings remove the meter. Ghost settings are kept in blueprint tags.
function meter.set(entity,settings)
  if not eligible(entity) then return end
  settings=normalize(settings)
  if entity.type=="entity-ghost" then
    local tags=entity.tags or {}
    tags[TAG]=selected(settings) and settings or nil
    entity.tags=tags
    return
  end
  if not selected(settings) then meter.remove(entity);return end
  local row=storage.nullius_grid_meters[entity.unit_number]
  if not row then
    row={entity=entity,settings=settings,values={offered=0,demand=0}}
    storage.nullius_grid_meters[entity.unit_number]=row
    script.register_on_object_destroyed(entity,entity.unit_number)
    create_output(row)
  end
  row.settings=settings
  write(row)
end
function meter.built(entity,tags)
  if eligible(entity) and tags and tags[TAG] then meter.set(entity,tags[TAG]) end
end
function meter.cloned(event)
  if event.destination.name==OUTPUT then event.destination.destroy();return true end
  if eligible(event.destination) then meter.set(event.destination,meter.settings(event.source)) end
  return false
end
function meter.destroyed(event)
  local row=storage.nullius_grid_meters[event.useful_id]
  if row and not row.entity.valid then
    if row.output.valid then row.output.destroy() end
    storage.nullius_grid_meters[event.useful_id]=nil
    return true
  end
  return false
end
local function network_key(network)
  local id=math.huge
  for _,sub in pairs(network.sub_networks) do id=math.min(id,sub.id) end
  return id
end
-- Each online network is sampled once; offline meters keep their last values.
function meter.update(nodes,samples)
  for id,row in pairs(storage.nullius_grid_meters) do
    if not eligible(row.entity) then
      if row.output.valid then row.output.destroy() end
      storage.nullius_grid_meters[id]=nil
    else
      if not row.output.valid then create_output(row) end
      if row.output.surface~=row.entity.surface then
        row.output.destroy();create_output(row)
      elseif row.output.position.x~=row.entity.position.x or
          row.output.position.y~=row.entity.position.y then
        assert(row.output.teleport(row.entity.position),"Cannot move grid meter output")
        connect(row)
      end
      row.output.force=row.entity.force
      local sub=row.entity.electric_network
      local key=sub and network_key(sub.parent_network)
      if not (key and nodes[key] and nodes[key].group.offline) then
        local flow=key and samples[key]
        if not flow and sub then flow=sub.parent_network.flow_last_tick;samples[key]=flow end
        local offered=flow and (flow.primary_output+flow.secondary_output+flow.solar_output) or 0
        local demand=flow and (flow.primary_demand+flow.secondary_demand+flow.tertiary_demand) or 0
        row.values={offered=math.floor(offered*60/1000+0.5),demand=math.floor(demand*60/1000+0.5)}
        write(row)
      end
    end
  end
end
local function opened(player)
  local entity=player.opened
  return entity and entity.object_name=="LuaEntity" and eligible(entity) and entity or nil
end
function meter.open(event)
  local player=game.get_player(event.player_index)
  local frame=player.gui.relative[PANEL]
  local entity=opened(player)
  if not entity then if frame then frame.destroy() end;return end
  if not frame then
    frame=player.gui.relative.add{type="frame",name=PANEL,direction="vertical",caption={"grid-meter.title"},
      anchor={gui=defines.relative_gui_type.accumulator_gui,position=defines.relative_gui_position.right}}
    for _,key in ipairs(keys) do
      local line=frame.add{type="flow",name=key,direction="horizontal"}
      line.add{type="label",caption={"grid-meter."..key}}
      line.add{type="choose-elem-button",name="nullius_grid_meter_"..key,elem_type="signal",
        tooltip={"grid-meter."..key.."-hint"}}
    end
  end
  local settings=meter.settings(entity)
  for _,key in ipairs(keys) do
    local button=frame[key]["nullius_grid_meter_"..key]
    button.elem_value=settings[key]
    button.enabled=entity.force==player.force
  end
end
function meter.close(event)
  local frame=game.get_player(event.player_index).gui.relative[PANEL]
  if frame then frame.destroy() end
end
local function refresh(entity)
  for _,player in pairs(game.connected_players) do
    if opened(player)==entity then meter.open{player_index=player.index} end
  end
end
function meter.changed(event)
  local element=event.element
  if not element or not element.valid then return end
  local key=element.name:match("^nullius_grid_meter_(offered)$") or element.name:match("^nullius_grid_meter_(demand)$")
  if not key then return end
  local player=game.get_player(event.player_index)
  local entity=opened(player)
  if not entity or entity.force~=player.force then return end
  local settings=meter.settings(entity)
  settings[key]=element.elem_value
  meter.set(entity,settings)
  refresh(entity)
end
function meter.pasted(event)
  if eligible(event.destination) and eligible(event.source) then
    meter.set(event.destination,meter.settings(event.source));refresh(event.destination)
  end
end
-- Preserve all other blueprint tags while recording selected meter signals.
function meter.blueprint(stack,mapping)
  for index,entity in pairs(mapping) do
    if eligible(entity) then
      local tags=stack.get_blueprint_entity_tags(index) or {}
      local settings=meter.settings(entity)
      tags[TAG]=selected(settings) and settings or nil
      stack.set_blueprint_entity_tags(index,tags)
    end
  end
end
function meter.setup_blueprint(event)
  local player=game.get_player(event.player_index)
  local stack=player.blueprint_to_setup
  if not stack or not stack.valid_for_read then stack=player.cursor_stack end
  assert(stack and stack.valid_for_read and stack.is_blueprint,"Missing blueprint during meter setup")
  meter.blueprint(stack,event.mapping.get())
end
function meter.rebuild()
  local previous=storage.nullius_grid_meters or {}
  storage.nullius_grid_meters={}
  for _,surface in pairs(game.surfaces) do
    for _,entity in pairs(surface.find_entities_filtered{name=OUTPUT}) do entity.destroy() end
  end
  for _,row in pairs(previous) do
    if eligible(row.entity) then
      meter.set(row.entity,row.settings)
      local restored=storage.nullius_grid_meters[row.entity.unit_number]
      restored.values=row.values;write(restored)
    end
  end
  for _,player in pairs(game.connected_players) do meter.open{player_index=player.index} end
end
script.on_event(defines.events.on_gui_elem_changed,meter.changed)
script.on_event(defines.events.on_player_setup_blueprint,meter.setup_blueprint)
if script.active_mods["factorio-test-support"] then
  remote.add_interface("nullius-test-grid-meter",{
    set=meter.set,settings=meter.settings,blueprint=meter.blueprint,rebuild=meter.rebuild,
    changed=meter.changed,
    output=function(entity)
      local row=storage.nullius_grid_meters[entity.unit_number]
      return row and row.output
    end,
  })
end
return meter

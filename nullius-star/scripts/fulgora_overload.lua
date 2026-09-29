local overload={}
local config=require("shared.fulgora-overload")
local PANEL="nullius_fulgora_grid"
local BUTTON="nullius_fulgora_grid_reset"
local ALERT={"fulgora-overload.alert"}
local ICON={type="virtual",name="signal-alert"}

local function network_key(network)
  local id=math.huge
  for _,sub in pairs(network.sub_networks) do id=math.min(id,sub.id) end
  return id
end
local function eligible(pole)
  return pole and pole.valid and pole.type=="electric-pole" and pole.surface.planet and
    pole.surface.planet.name=="nullius-fulgora"
end
local function topology()
  local nodes,owners={},{}
  local function node(network)
    local id=network_key(network)
    if not nodes[id] then nodes[id]={id=id,network=network,rows={}};owners[id]=id end
    return nodes[id]
  end
  local function root(id)
    while owners[id]~=id do owners[id]=owners[owners[id]];id=owners[id] end
    return id
  end
  for _,row in pairs(storage.fulgora_collectors) do
    if eligible(row.pole) then
      local n=node(row.pole.electric_network.parent_network)
      n.rows[#n.rows+1]=row
    end
  end
  for _,n in pairs(nodes) do
    for _,row in ipairs(n.rows) do
      if row.helper.valid then
        for _,sub in pairs(row.helper.electric_networks) do
          local adjacent=node(sub.parent_network)
          local left,right=root(n.id),root(adjacent.id)
          if left~=right then owners[math.max(left,right)]=math.min(left,right) end
        end
      end
    end
  end
  local groups={}
  for id,n in pairs(nodes) do
    local r=root(id)
    local group=groups[r] or {nodes={},offline=false,grace=0,forces={}}
    groups[r]=group;n.group=group;group.nodes[#group.nodes+1]=n
    table.sort(n.rows,function(a,b) return a.pole.unit_number<b.pole.unit_number end)
    for _,row in ipairs(n.rows) do
      group.offline=group.offline or row.grid_offline or false
      group.grace=math.max(group.grace,row.grid_grace or 0)
      group.forces[row.pole.force.index]=true
    end
  end
  return nodes,groups
end
local function alerts(nodes)
  for _,player in pairs(game.players) do
    player.remove_alert{type=defines.alert_type.custom,prototype=config.sink,message=ALERT}
    for id,row in pairs(storage.fulgora_overload_sinks) do
      if nodes[id].group.forces[player.force.index] then
        player.add_custom_alert(row.entity,ICON,ALERT,true)
      end
    end
  end
end
local function apply(nodes,groups)
  for _,group in pairs(groups) do
    for _,n in ipairs(group.nodes) do
      for _,row in ipairs(n.rows) do row.grid_offline=group.offline;row.grid_grace=group.grace end
    end
  end
  local sinks=storage.fulgora_overload_sinks
  for id,row in pairs(sinks) do
    local n=nodes[id]
    if not n or not n.group.offline or not row.entity.valid or not row.pole.valid or
        network_key(row.pole.electric_network.parent_network)~=id then
      if row.entity.valid then row.entity.destroy() end
      sinks[id]=nil
    end
  end
  for id,n in pairs(nodes) do
    if n.group.offline then
      assert(#n.rows>0,"Fulgora shutdown network has no registered pole")
      local row=sinks[id]
      if row then
        if row.entity.position.x~=row.pole.position.x or row.entity.position.y~=row.pole.position.y then
          assert(row.entity.teleport(row.pole.position),"Cannot move grid shutdown consumer")
        end
      else
        local pole=n.rows[1].pole
        local entity=assert(pole.surface.create_entity{name=config.sink,position=pole.position,force="neutral"})
        entity.destructible=false;entity.operable=false
        sinks[id]={entity=entity,pole=pole}
      end
    end
  end
  alerts(nodes)
end
local function panel(player,pole,nodes)
  local old=player.gui.relative[PANEL]
  if not eligible(pole) then if old then old.destroy() end;return end
  local n=nodes[network_key(pole.electric_network.parent_network)]
  if not n then if old then old.destroy() end;return end
  local frame=old or player.gui.relative.add{type="frame",name=PANEL,direction="vertical",
    caption={"fulgora-overload.panel"},anchor={gui=defines.relative_gui_type.electric_network_gui,
    position=defines.relative_gui_position.right}}
  if not frame.status then
    frame.add{type="label",name="status"}
    local hint=frame.add{type="label",caption={"fulgora-overload.hint"}}
    hint.style.single_line=false;hint.style.maximal_width=280
    frame.add{type="button",name=BUTTON,caption={"fulgora-overload.reset"}}
  end
  frame.status.caption={n.group.offline and "fulgora-overload.offline" or "fulgora-overload.online"}
  frame[BUTTON].enabled=n.group.offline and pole.force==player.force
end
local function refresh_panels(nodes)
  for _,player in pairs(game.connected_players) do
    local opened=player.opened
    local pole=opened and opened.object_name=="LuaEntity" and opened or nil
    if player.gui.relative[PANEL] or eligible(pole) then panel(player,pole,nodes) end
  end
end
function overload.update()
  local nodes,groups=topology()
  for _,n in pairs(nodes) do
    local group=n.group
    if not group.offline and game.tick>=group.grace then
      local flow=n.network.flow_last_tick
      local offered=flow.primary_output+flow.secondary_output+flow.solar_output
      local demand=flow.primary_demand+flow.secondary_demand+flow.tertiary_demand
      if offered>config.demand_ratio*demand and offered-demand>config.minimum_excess_watts/60 then
        group.offline=true
      end
    end
  end
  apply(nodes,groups);refresh_panels(nodes)
end
-- Reset the current shared shutdown group; stored energy is not restored.
function overload.reset(pole,force)
  if not eligible(pole) or pole.force~=force then return false end
  local nodes,groups=topology()
  local n=nodes[network_key(pole.electric_network.parent_network)]
  if not n or not n.group.offline then return false end
  n.group.offline=false;n.group.grace=game.tick+config.reset_grace_ticks
  apply(nodes,groups);refresh_panels(nodes)
  return true
end
function overload.open(event)
  local player=game.get_player(event.player_index)
  local nodes=topology()
  panel(player,event.entity,nodes)
end
function overload.close(event)
  local frame=game.get_player(event.player_index).gui.relative[PANEL]
  if frame then frame.destroy() end
end
function overload.click(event)
  if not event.element.valid or event.element.name~=BUTTON then return false end
  local player=game.get_player(event.player_index)
  local opened=player.opened
  if opened and opened.object_name=="LuaEntity" then overload.reset(opened,player.force) end
  return true
end
function overload.cloned(entity)
  if entity.name~=config.sink then return false end
  entity.destroy();return true
end
function overload.rebuild()
  storage.fulgora_overload_sinks=storage.fulgora_overload_sinks or {}
  local owned={}
  for _,row in pairs(storage.fulgora_overload_sinks) do
    if row.entity.valid then owned[row.entity.unit_number]=true end
  end
  for _,surface in pairs(game.surfaces) do
    for _,sink in pairs(surface.find_entities_filtered{name=config.sink}) do
      if not owned[sink.unit_number] then sink.destroy() end
    end
  end
  local nodes,groups=topology();apply(nodes,groups)
end
script.on_event(defines.events.on_gui_opened,overload.open)
script.on_event(defines.events.on_gui_closed,overload.close)
if script.active_mods["factorio-test-support"] then
  remote.add_interface("nullius-test-overload",{
    reset=overload.reset,
    open=overload.open,click=overload.click,
    offline=function(pole)
      local nodes=topology();local n=nodes[network_key(pole.electric_network.parent_network)]
      return n and n.group.offline or false
    end,
  })
end
return overload

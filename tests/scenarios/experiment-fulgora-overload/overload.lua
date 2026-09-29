-- Test-only prototype: faults follow registered poles across network changes.
local overload={}
local MINIMUM_EXCESS_WATTS=1000000
local SINK="factorio-test-trip-sink"
local MESSAGE="Electrical grid overloaded"
local ICON={type="virtual",name="signal-alert"}
local PANEL="fulgora_overload_experiment"
local function state() return storage.overload end
function overload.init()
  storage.overload={poles={},sinks={},groups={},reads=0,trips=0}
end
function overload.add(pole)
  state().poles[pole.unit_number]={pole=pole,offline=false,grace=0}
end
local function key(pole)
  local sub=pole.electric_network
  if not sub then return nil end
  local network=sub.parent_network
  local id=math.huge
  for _,sub in pairs(network.sub_networks) do id=math.min(id,sub.id) end
  return id,network
end
-- Alerts follow current grid ownership and mark the hidden consumer on the map.
local function refresh_alerts()
  for _,player in pairs(game.players) do
    player.remove_alert{type=defines.alert_type.custom,prototype=SINK,message=MESSAGE}
    for id,sink in pairs(state().sinks) do
      local group=state().groups[id]
      local affected=false
      for _,row in ipairs(group.rows) do
        if row.pole.force==player.force then affected=true;break end
      end
      if affected then player.add_custom_alert(sink,ICON,MESSAGE,true) end
    end
  end
end

function overload.reconcile()
  local groups={}
  for id,row in pairs(state().poles) do
    if not row.pole.valid then state().poles[id]=nil
    else
      local k,network=key(row.pole)
      local group=groups[k] or {network=network,rows={},offline=false,grace=0}
      groups[k]=group;group.rows[#group.rows+1]=row
      group.offline=group.offline or row.offline
      group.grace=math.max(group.grace,row.grace)
    end
  end
  for _,group in pairs(groups) do
    table.sort(group.rows,function(a,b) return a.pole.unit_number<b.pole.unit_number end)
    for _,row in ipairs(group.rows) do row.offline=group.offline;row.grace=group.grace end
  end
  for id,sink in pairs(state().sinks) do
    local group=groups[id]
    if not group or not group.offline or not sink.valid or
        key(sink)~=id then
      if sink.valid then sink.destroy() end
      state().sinks[id]=nil
    end
  end
  for id,group in pairs(groups) do
    if group.offline and not state().sinks[id] then
      local pole=group.rows[1].pole
      local sink=assert(pole.surface.create_entity{name=SINK,position=pole.position,force="neutral"})
      sink.destructible=false;sink.operable=false
      state().sinks[id]=sink
    end
  end
  state().groups=groups
  refresh_alerts()
end
function overload.sample()
  overload.reconcile()
  for _,group in pairs(state().groups) do
    if not group.offline and game.tick>=group.grace then
      local flow=group.network.flow_last_tick
      state().reads=state().reads+1
      local offered=flow.primary_output+flow.secondary_output+flow.solar_output
      local demand=flow.primary_demand+flow.secondary_demand+flow.tertiary_demand
      group.offered=offered;group.demand=demand
      if offered>2*demand and offered-demand>MINIMUM_EXCESS_WATTS/60 then
        for _,row in ipairs(group.rows) do row.offline=true end
        state().trips=state().trips+1
      end
    end
  end
  overload.reconcile()
end
function overload.offline(pole)
  overload.reconcile()
  return state().groups[key(pole)].offline
end
-- Reset resolves the pole's current component, including intervening splits.
function overload.reset(pole)
  if not pole.valid or not state().poles[pole.unit_number] then return false end
  overload.reconcile()
  local group=state().groups[key(pole)]
  for _,row in ipairs(group.rows) do row.offline=false;row.grace=game.tick+120 end
  overload.reconcile()
  return true
end
function overload.open(event)
  local player=game.get_player(event.player_index)
  if player.gui.relative[PANEL] then player.gui.relative[PANEL].destroy() end
  local pole=event.entity
  if not pole or not pole.valid or not state().poles[pole.unit_number] then return end
  local frame=player.gui.relative.add{type="frame",name=PANEL,direction="vertical",
    caption="Grid overload prototype",anchor={gui=defines.relative_gui_type.electric_network_gui,
    position=defines.relative_gui_position.right}}
  frame.add{type="label",caption=overload.offline(pole) and "Offline — overload" or "Online"}
  frame.add{type="button",name="fulgora_overload_reset",caption="Reset grid"}
end
function overload.click(event)
  if not event.element.valid or event.element.name~="fulgora_overload_reset" then return end
  local player=game.get_player(event.player_index)
  local pole=player.opened
  if not pole or not pole.valid or pole.object_name~="LuaEntity" then return end
  if pole.force~=player.force then return end
  if overload.reset(pole) then overload.open{player_index=player.index,entity=pole} end
end
return overload

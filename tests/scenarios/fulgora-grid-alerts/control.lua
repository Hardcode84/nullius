-- given: two real clients, separate forces, a 2 MW source and 100 kW load.
-- place/connect: two wired poles and one hidden consumer in the test storm surface.
-- act: trip, wait, remove the anchor, change player force, reload and reset.
-- expect: one current custom alert per affected player, targeted at the sink;
-- preserve other alerts and remove the overload alert when the grid is reset.
local overload={
  offline=function(pole) return remote.call("nullius-test-overload","offline",pole) end,
  open=function(event) return remote.call("nullius-test-overload","open",event) end,
  click=function(event) return remote.call("nullius-test-overload","click",event) end,
}
local CASE="fulgora-grid-alerts"
local MESSAGE={"fulgora-overload.alert"}
local SINK="nullius-fulgora-overload-sink"
local function check(ok,message) storage.assertions=storage.assertions+1;assert(ok,message) end
local function alerts(player,message)
  local result={}
  for _,surface in pairs(player.get_alerts{type=defines.alert_type.custom,message=message}) do
    for _,list in pairs(surface) do for _,alert in pairs(list) do result[#result+1]=alert end end
  end
  return result
end
local function own_alert(player,x)
  local list=alerts(player,MESSAGE)
  check(#list==1,"expected one overload alert, got "..#list)
  local alert=list[1]
  check(alert.target and alert.target.valid and alert.target.name==SINK,"alert anchor")
  check(alert.target.position.x==x,"alert did not follow sink")
  check(alert.icon.name=="signal-alert" and alert.message[1]==MESSAGE[1],"alert presentation")
  check(alert.tick>=game.tick-30,"alert was not refreshed")
end
script.on_init(function() storage.stage="setup";storage.assertions=0;storage.joins=0 end)
script.on_event(defines.events.on_player_joined_game,function(event)
  if game.get_player(event.player_index).name=="nullius-test-a" then storage.joins=storage.joins+1 end
end)
script.on_nth_tick(30,function()
  local player=game.get_player("nullius-test-a")
  if not player or not player.connected then return end
  if storage.stage=="setup" then
    local surface=game.planets["nullius-fulgora"].create_surface()
    surface.request_to_generate_chunks({0,0},2);surface.force_generate_chunk_requests()
    for _,entity in pairs(surface.find_entities()) do entity.destroy() end
    local tiles={};for x=-10,20 do for y=-10,10 do tiles[#tiles+1]={name="grass-1",position={x,y}} end end
    surface.set_tiles(tiles,true)
    storage.surface=surface;storage.force=player.force
    storage.foreign=game.create_force("unaffected-grid")
    player.set_controller{type=defines.controllers.god};player.teleport({0,5},surface)
    local function place(name,x,y)
      return assert(surface.create_entity{name="factorio-test-trip-"..name,position={x,y},force=player.force,raise_built=true})
    end
    storage.pole=place("pole",0,0);storage.other=place("pole",9,0)
    storage.source=place("source-2000000",1,0);storage.load=place("load",1,1)
    storage.stage="peer"
    helpers.write_file("factorio-tests/multiplayer-action.json",helpers.table_to_json{
      id=1,action="join",player="nullius-test-b"},false)
    return
  end
  local peer=game.get_player("nullius-test-b")
  if not peer or not peer.connected then return end
  if storage.stage=="peer" then
    peer.force=storage.foreign
    storage.stage="refresh";storage.start=game.tick
  elseif storage.stage=="refresh" then
    if game.tick<storage.start+660 then return end
    own_alert(player,0)
    check(#alerts(peer,MESSAGE)==0,"alert leaked to another force")
    storage.pole.destroy();storage.stage="relocate"
  elseif storage.stage=="relocate" then
    own_alert(player,9)
    player.force=storage.foreign
    storage.stage="changed-force"
  elseif storage.stage=="changed-force" then
    check(#alerts(player,MESSAGE)==0,"old force alert remained")
    player.force=storage.force
    storage.stage="returned-force"
  elseif storage.stage=="returned-force" then
    own_alert(player,9)
    storage.stage="reload"
    helpers.write_file("factorio-tests/multiplayer-action.json",helpers.table_to_json{id=2,action="reload"},false)
  elseif storage.stage=="reload" and storage.joins>=2 then
    own_alert(player,9)
    check(#alerts(peer,MESSAGE)==0,"reload notified wrong force")
    player.add_custom_alert(storage.other,{type="virtual",name="signal-alert"},"Other alert",true)
    -- Use the actual reset panel and its click handler with a native GUI element.
    player.opened=storage.other
    overload.open{player_index=player.index,entity=storage.other}
    local button=player.gui.relative.nullius_fulgora_grid.nullius_fulgora_grid_reset
    check(button and button.valid,"reset button missing")
    overload.click{player_index=player.index,element=button}
    check(not overload.offline(storage.other),"GUI reset failed")
    check(#alerts(player,MESSAGE)==0,"reset left an overload alert")
    check(#alerts(player,"Other alert")==1,"reset removed another alert")
    storage.stage="overlap-start"
  elseif storage.stage=="overlap-start" then
    storage.foreign_pole=assert(storage.surface.create_entity{name="factorio-test-trip-pole",
      position={11,0},force=peer.force,raise_built=true})
    local connector=storage.foreign_pole.get_wire_connector(defines.wire_connector_id.pole_copper,true)
    connector.disconnect_all()
    assert(storage.surface.create_entity{name="factorio-test-trip-source-2000000",
      position={10,0},force=player.force})
    check(storage.foreign_pole.electric_network_id~=storage.other.electric_network_id,"overlap fixture has a wire")
    storage.start=game.tick;storage.stage="overlap-wait"
  elseif storage.stage=="overlap-wait" then
    if game.tick<storage.start+180 then return end
    check(overload.offline(storage.other) and overload.offline(storage.foreign_pole),"overlap did not latch both grids")
    check(#alerts(player,MESSAGE)==2 and #alerts(peer,MESSAGE)==2,"shared group alerts did not reach both forces")
    peer.opened=storage.other
    overload.open{player_index=peer.index,entity=storage.other}
    local button=peer.gui.relative.nullius_fulgora_grid.nullius_fulgora_grid_reset
    check(not button.enabled,"foreign reset button enabled")
    overload.click{player_index=peer.index,element=button}
    check(overload.offline(storage.other),"foreign pole permitted reset")
    peer.opened=storage.foreign_pole
    overload.open{player_index=peer.index,entity=storage.foreign_pole}
    button=peer.gui.relative.nullius_fulgora_grid.nullius_fulgora_grid_reset
    check(button.enabled,"own reset button disabled")
    overload.click{player_index=peer.index,element=button}
    check(not overload.offline(storage.other) and not overload.offline(storage.foreign_pole),"reset did not clear shared group")
    check(#alerts(player,MESSAGE)==0 and #alerts(peer,MESSAGE)==0,"shared reset retained alerts")
    storage.stage="finish"
  elseif storage.stage=="finish" then
    helpers.write_file("factorio-tests/"..CASE..".json",helpers.table_to_json{
      schema=1,case=CASE,status="pass",failure_count=0,assertions=storage.assertions,
      tick=game.tick,factorio_version=script.active_mods.base},false)
    script.on_nth_tick(30,nil)
  end
end)

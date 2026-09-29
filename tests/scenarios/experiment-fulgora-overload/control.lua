-- given: native 2 MW sources (1.2 MW with storage), 100 kW loads, 600 kW battery charge limits;
-- the original 100 MW pole collector fixture and one declared 1 MJ lightning strike.
-- place/connect: isolated networks, a splittable pair, and overlapping unwired poles.
-- act: sample every 30 ticks; split/merge, remove anchors/helpers, reset, and pulse power.
-- expect: latch overloads, retain storage headroom, expose overlap and sampling bounds.
local overload=require("__nullius-star__/scenarios/experiment-fulgora-overload/overload")
local P="factorio-test-trip-"
local function check(ok,message) storage.assertions=storage.assertions+1;assert(ok,message) end
local function build(name,x,y)
  return assert(storage.surface.create_entity{name=name,position={x,y},force="player"})
end
local function wire(a,b,connect)
  local left=a.get_wire_connector(defines.wire_connector_id.pole_copper,true)
  local right=b.get_wire_connector(defines.wire_connector_id.pole_copper,true)
  local connected=false
  for _,edge in pairs(left.connections) do if edge.target==right then connected=true end end
  if connect and not connected then assert(left.connect_to(right)) end
  if not connect then assert(connected,"wire missing");assert(left.disconnect_from(right)) end
end
local function generation(source,watts)
  local position=source.position
  source.destroy()
  return build(P.."source"..(watts==1000000 and "" or "-"..watts),position.x,position.y)
end
local function row(x,battery)
  local r={pole=build(P.."pole",x,0),source=build(P.."source-2000000",x+1,0),load=build(P.."load",x+1,1)}
  overload.add(r.pole)
  if battery then r.battery=build(P.."battery",x-1,1) end
  return r
end
script.on_nth_tick(1,function()
  if game.tick==0 then return end
  script.on_nth_tick(1,nil)
  if storage.overload then storage.observations.reload_tick=game.tick;return end
  overload.init();storage.assertions=0;storage.observations={}
  storage.surface=game.planets["factorio-test-lightning-planet"].create_surface()
  local s=storage.surface
  s.request_to_generate_chunks({300,0},13);s.force_generate_chunk_requests()
  for _,e in pairs(s.find_entities()) do e.destroy() end
  local tiles={};for x=-10,650 do for y=-10,15 do tiles[#tiles+1]={name="grass-1",position={x,y}} end end
  s.set_tiles(tiles,true)
  storage.hot=row(0,false)
  storage.protected=row(100,true)
  storage.protected.source=generation(storage.protected.source,1200000)
  storage.edge=row(200,false);storage.edge.source=generation(storage.edge.source,200000)
  storage.dark=row(300,false);storage.dark.source=generation(storage.dark.source,0)
  storage.dark.battery=build(P.."battery",299,1);storage.dark.battery.energy=10000000
  storage.branch=row(400,false)
  storage.far=build(P.."pole",409,0);overload.add(storage.far)
  storage.far_load=build(P.."load",410,1);wire(storage.branch.pole,storage.far,true)
  storage.lightning={pole=build(P.."pole",500,0),load=build(P.."load",501,1)}
  overload.add(storage.lightning.pole)
  storage.lightning.collector=build("factorio-test-power-collector-100000",500,0)
  storage.overlap=row(600,false)
  storage.neighbour=row(602,false)
  wire(storage.overlap.pole,storage.neighbour.pole,false)
  storage.neighbour.source=generation(storage.neighbour.source,100000)
  -- No ambient storms: the production collector gets one explicit native strike.
end)
script.on_nth_tick(30,function()
  if game.tick>0 then overload.sample() end
end)
script.on_event(defines.events.on_gui_opened,overload.open)
script.on_event(defines.events.on_gui_click,overload.click)
local actions={
 [31]=function() check(storage.overload.reads==8,"must read once per network, not per pole") end,
 [29]=function()
  storage.surface.execute_lightning{name="factorio-test-lightning",position={500,0}}
 end,
 [61]=function()
  check(overload.offline(storage.hot.pole),"excess supply did not trip")
  check(not overload.offline(storage.protected.pole),"battery charge demand ignored")
  check(not overload.offline(storage.edge.pole),"exact 2x boundary tripped")
  check(not overload.offline(storage.dark.pole),"accumulator discharge counted as generation")
  check(overload.offline(storage.lightning.pole),"native lightning did not trip")
  check(overload.offline(storage.far),"fault missing on remote pole")
  check(storage.hot.load.energy==0,"load not starved")
  local networks=0
  for _,sink in pairs(storage.overload.sinks) do
    if sink.position.x>590 then networks=math.max(networks,#sink.electric_networks) end
  end
  storage.observations.overlap_networks=networks
  check(networks>1,"overlap witness did not span separate networks")
  check(storage.neighbour.load.energy==0,"expected neighbouring-grid starvation witness")
  wire(storage.branch.pole,storage.far,false)
 end,
 [91]=function()
  check(overload.offline(storage.branch.pole) and overload.offline(storage.far),"split lost fault")
  local count=0;for _,sink in pairs(storage.overload.sinks) do if sink.position.x>=400 and sink.position.x<420 then count=count+1 end end
  check(count==2,"split must create one sink per component")
  check(overload.reset(storage.far),"reset failed")
  check(not overload.offline(storage.far) and overload.offline(storage.branch.pole),"reset crossed split")
  wire(storage.branch.pole,storage.far,true)
 end,
 [121]=function()
  check(overload.offline(storage.far),"merge failed to propagate fault")
  storage.branch.pole.destroy()
 end,
 [151]=function()
  check(overload.offline(storage.far),"anchor removal lost fault")
  local found=false
  for _,sink in pairs(storage.overload.sinks) do
    if sink.position.x==409 then sink.destroy();found=true end
  end
  check(found,"sink did not relocate after anchor removal")
 end,
 [181]=function()
  local found=false
  for _,sink in pairs(storage.overload.sinks) do if sink.position.x==409 then found=true end end
  check(found,"deleted sink was not restored")
  overload.reset(storage.hot.pole)
 end,
 [211]=function()
  check(not overload.offline(storage.hot.pole),"reset grace missing")
  check(storage.hot.load.energy>0,"manual reset did not restore power")
 end,
 [331]=function()
  check(overload.offline(storage.hot.pole),"persistent excess did not retrip")
  storage.hot.source=generation(storage.hot.source,100000)
  overload.reset(storage.hot.pole)
 end,
 [481]=function()
  check(not overload.offline(storage.hot.pole),"rebalanced grid retripped")
  check(storage.hot.load.energy>0,"rebalanced grid unpowered")
  storage.edge.source=generation(storage.edge.source,2000000)
 end,
 [489]=function() storage.edge.source=generation(storage.edge.source,200000) end,
 [541]=function()
  check(not overload.offline(storage.edge.pole),"between-sample pulse unexpectedly latched")
  storage.observations.short_pulse="8 tick pulse between samples is missed"
  storage.protected.battery.energy=storage.protected.battery.electric_buffer_size
 end,
 [601]=function()
  check(overload.offline(storage.protected.pole),"full storage still protects grid")
 end,
 [1051]=function()
  storage.observations.aggregate_reads=storage.overload.reads
  storage.observations.trips=storage.overload.trips
  helpers.write_file("factorio-tests/experiment-fulgora-overload.json",helpers.table_to_json{
    schema=1,case="experiment-fulgora-overload",status="pass",failure_count=0,
    assertions=storage.assertions,observations=storage.observations,tick=game.tick,
    factorio_version=script.active_mods.base},false)
 end,
}
for tick,action in pairs(actions) do
  script.on_nth_tick(tick,function(event)
    if event.tick==tick then action() end
    if event.tick>=tick then script.on_nth_tick(tick,nil) end
  end)
end

commands.add_command("overload-demo","Open the overload experiment grid",function(event)
  if not event.player_index then return end
  local player=game.get_player(event.player_index)
  player.teleport({0,5},storage.surface)
  player.opened=storage.hot.pole
  overload.open{player_index=player.index,entity=storage.hot.pole}
end)

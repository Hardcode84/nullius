-- given: native 2 MW sources (1.2 MW with storage), 100 kW loads, 600 kW battery charge limits;
-- a production pole collector and one declared 1 MJ lightning strike.
-- place/connect: isolated networks, a splittable pair, and overlapping unwired poles.
-- act: sample every 30 ticks; split/merge, remove anchors/helpers, reset, and pulse power.
-- expect: latch overloads, retain storage headroom, expose overlap and sampling bounds.
local overload={
  offline=function(pole) return remote.call("nullius-test-overload","offline",pole) end,
  reset=function(pole) return remote.call("nullius-test-overload","reset",pole,pole.force) end,
}
local SINK="nullius-fulgora-overload-sink"
local function sinks() return storage.surface.find_entities_filtered{name=SINK} end
local P="factorio-test-trip-"
local function check(ok,message) storage.assertions=storage.assertions+1;assert(ok,message) end
local function build(name,x,y)
  return assert(storage.surface.create_entity{name=name,position={x,y},force="player",raise_built=true})
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
  if battery then r.battery=build(P.."battery",x-1,1) end
  return r
end
script.on_nth_tick(1,function()
  if game.tick==0 then return end
  script.on_nth_tick(1,nil)
  if storage.surface then storage.observations.reload_tick=game.tick;return end
  storage.assertions=0;storage.observations={}
  storage.surface=game.planets["nullius-fulgora"].create_surface()
  local s=storage.surface
  s.request_to_generate_chunks({300,0},13);s.force_generate_chunk_requests()
  for _,e in pairs(s.find_entities()) do e.destroy() end
  local tiles={};for x=-10,750 do for y=-10,15 do tiles[#tiles+1]={name="grass-1",position={x,y}} end end
  s.set_tiles(tiles,true)
  storage.replacement=build("small-electric-pole",700,0)
  build(P.."source-2000000",701,0)
  storage.hot=row(0,false)
  local nauvis=game.surfaces.nauvis
  nauvis.request_to_generate_chunks({0,0},1);nauvis.force_generate_chunk_requests()
  storage.nauvis=assert(nauvis.create_entity{name=P.."pole",position={0,0},force="player",raise_built=true})
  storage.protected=row(100,true)
  storage.protected.source=generation(storage.protected.source,1200000)
  storage.edge=row(200,false);storage.edge.source=generation(storage.edge.source,200000)
  storage.dark=row(300,false);storage.dark.source=generation(storage.dark.source,0)
  storage.dark.battery=build(P.."battery",299,1);storage.dark.battery.energy=10000000
  storage.branch=row(400,false)
  storage.far=build(P.."pole",409,0)
  storage.far_load=build(P.."load",410,1);wire(storage.branch.pole,storage.far,true)
  storage.lightning={pole=build(P.."pole",500,0),load=build(P.."load",501,1)}
  storage.lightning.collector=storage.surface.find_entities_filtered{name="nullius-pole-lightning-collector",position={500,0}}[1]
  storage.overlap=row(600,false)
  storage.neighbour=row(602,false)
  storage.neighbour.pole.force=game.create_force("overlap-neighbour")
  wire(storage.overlap.pole,storage.neighbour.pole,false)
  storage.neighbour.source=generation(storage.neighbour.source,100000)
  -- No ambient storms: the production collector gets one explicit native strike.
end)
local actions={
 [61]=function() check(not overload.offline(storage.hot.pole),"tripped before third check") end,
 [91]=function() check(overload.offline(storage.hot.pole),"pending trip did not survive") end,
 [481]=function() check(not overload.offline(storage.hot.pole),"reset retained pending checks") end,

 [29]=function()
  storage.surface.execute_lightning{name="factorio-test-lightning",position={500,0}}
 end,
 [181]=function()
  check(overload.offline(storage.replacement),"replacement fixture did not trip")
  storage.replacement=assert(storage.surface.create_entity{name="medium-electric-pole",
    position={700,0},force="player",fast_replace=true,spill=false,raise_built=true})
  check(overload.offline(storage.replacement),"fast replacement lost fault")
  for _,sink in pairs(sinks()) do
    if sink.position.x==0 then sink.clone{position={0,0},surface=game.surfaces.nauvis,force="neutral"} end
  end
  check(game.surfaces.nauvis.count_entities_filtered{name=SINK}==0,"cloned shutdown consumer survived")
  check(overload.offline(storage.hot.pole),"excess supply did not trip")
  check(not overload.offline(storage.nauvis),"overload outside Fulgora")
  check(not overload.offline(storage.protected.pole),"battery charge demand ignored")
  check(not overload.offline(storage.edge.pole),"exact 2x boundary tripped")
  check(not overload.offline(storage.dark.pole),"accumulator discharge counted as generation")
  check(overload.offline(storage.lightning.pole),"sustained collector excess did not trip")
  check(overload.offline(storage.far),"fault missing on remote pole")
  check(storage.hot.load.energy==0,"load not starved")
  local networks=0
  for _,sink in pairs(sinks()) do
    if sink.position.x>590 then networks=math.max(networks,#sink.electric_networks) end
  end
  storage.observations.overlap_networks=networks
  check(networks>1,"overlap witness did not span separate networks")
  check(storage.neighbour.load.energy==0,"shared shutdown did not starve neighbour")
  check(overload.offline(storage.neighbour.pole),"overlapping neighbour was not marked offline")
  check(not remote.call("nullius-test-overload","reset",storage.neighbour.pole,game.forces.player),
    "foreign pole permitted shared reset")
  check(overload.offline(storage.overlap.pole),"rejected reset cleared shared fault")
  check(overload.reset(storage.neighbour.pole),"shared group reset failed")
  check(not overload.offline(storage.overlap.pole),"shared reset left neighbour offline")
  wire(storage.branch.pole,storage.far,false)
 end,
 [211]=function()
  check(overload.offline(storage.replacement),"replacement fault did not survive reconciliation")
  check(overload.offline(storage.branch.pole) and overload.offline(storage.far),"split lost fault")
  local count=0;for _,sink in pairs(sinks()) do if sink.position.x>=400 and sink.position.x<420 then count=count+1 end end
  check(count==2,"split must create one sink per component")
  check(overload.reset(storage.far),"reset failed")
  check(not overload.offline(storage.far) and overload.offline(storage.branch.pole),"reset crossed split")
  wire(storage.branch.pole,storage.far,true)
 end,
 [241]=function()
  check(overload.offline(storage.far),"merge failed to propagate fault")
  storage.branch.pole.destroy()
 end,
 [271]=function()
  check(overload.offline(storage.far),"anchor removal lost fault")
  local found=false
  for _,sink in pairs(sinks()) do
    if sink.position.x==409 then sink.destroy();found=true end
  end
  check(found,"sink did not relocate after anchor removal")
 end,
 [301]=function()
  local found=false
  for _,sink in pairs(sinks()) do if sink.position.x==409 then found=true end end
  check(found,"deleted sink was not restored")
  overload.reset(storage.hot.pole)
 end,
 [331]=function()
  check(not overload.offline(storage.hot.pole),"reset grace missing")
  check(storage.hot.load.energy>0,"manual reset did not restore power")
 end,
 [511]=function()
  check(overload.offline(storage.hot.pole),"persistent excess did not retrip")
  storage.hot.source=generation(storage.hot.source,100000)
  overload.reset(storage.hot.pole)
 end,
 [661]=function()
  check(not overload.offline(storage.hot.pole),"rebalanced grid retripped")
  check(storage.hot.load.energy>0,"rebalanced grid unpowered")
  storage.edge.source=generation(storage.edge.source,2000000)
 end,
 [669]=function() storage.edge.source=generation(storage.edge.source,200000) end,
 [721]=function()
  check(not overload.offline(storage.edge.pole),"between-sample pulse unexpectedly latched")
  storage.observations.short_pulse="8 tick pulse between samples is missed"
  storage.protected.battery.energy=storage.protected.battery.electric_buffer_size
 end,
 [811]=function()
  check(overload.offline(storage.protected.pole),"full storage still protects grid")
 end,
 [1051]=function()
  helpers.write_file("factorio-tests/fulgora-grid-overload.json",helpers.table_to_json{
    schema=1,case="fulgora-grid-overload",status="pass",failure_count=0,
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

-- given: fixed 1 MJ lightning, 50% collection efficiency, empty 10 MJ receivers.
-- place: bare pole, colocated hidden collector, and a three-pole split network.
-- connect: native copper wires; no generators or scripted energy injection.
-- act: execute native lightning, split/rejoin a network, destroy and replace a pole.
-- run: scheduled checks through tick 240.
-- expect: bare pole collects nothing; helper supplies exactly 500 kJ per strike.
local CASE = "experiment-lightning-poles"
local POLE = "factorio-test-lightning-pole"
local COLLECTOR = "factorio-test-pole-collector"
local RECEIVER = "factorio-test-lightning-receiver"
local function check(ok, message)
  storage.assertions = storage.assertions + 1
  if not ok then storage.failures[#storage.failures+1] = message end
end
local function equal(actual, expected, message)
  check(math.abs(actual-expected)<0.01, message..": "..actual.." expected "..expected)
end
local function build(name,x,y,force)
  return assert(storage.surface.create_entity{name=name,position={x,y},force=force or game.forces.player})
end
local function attach(pole)
  local helper=build(COLLECTOR,pole.position.x,pole.position.y,pole.force)
  local registration=script.register_on_object_destroyed(pole)
  storage.owners[registration]=helper
  check(helper.position.x==pole.position.x and helper.position.y==pole.position.y,"helper colocated")
  return helper
end
script.on_event(defines.events.on_object_destroyed,function(event)
  local helper=storage.owners[event.registration_number]
  if helper then
    if helper.valid then helper.destroy() end
    storage.owners[event.registration_number]=nil
    storage.cleaned=storage.cleaned+1
  end
end)
script.on_event(defines.events.on_script_trigger_effect,function(event)
  if event.effect_id=="experiment-pole-strike" or event.effect_id=="experiment-attractor-strike" then
    storage.hits[#storage.hits+1]={effect=event.effect_id,tick=game.tick,
      target=event.target_entity and event.target_entity.name or "none"}
  end
end)
local function strike(x)
  storage.surface.execute_lightning{name="factorio-test-lightning",position={x+2,2}}
end
script.on_init(function()
  storage.assertions=0;storage.failures={};storage.owners={};storage.hits={};storage.cleaned=0
  storage.surface=game.planets["factorio-test-lightning-planet"].create_surface()
  local surface=storage.surface
  for _,x in ipairs({0,100,200}) do
    surface.request_to_generate_chunks({x,0},2)
  end
  surface.force_generate_chunk_requests()
  for _,entity in pairs(surface.find_entities()) do entity.destroy() end
  local tiles={}
  for x=-10,230 do for y=-10,10 do tiles[#tiles+1]={name="grass-1",position={x,y}} end end
  surface.set_tiles(tiles,true,false,false,false)
  storage.bare=build(POLE,0,0);storage.initial_health=storage.bare.health;storage.bare_sink=build(RECEIVER,1,1)
  storage.paired=build(POLE,100,0);storage.collector=attach(storage.paired)
  storage.paired_sink=build(RECEIVER,101,1)
  local other=game.create_force("lightning-isolation")
  storage.other_pole=build(POLE,101,0,other);storage.other_sink=build(RECEIVER,102,1,other)
  storage.split=build(POLE,200,0);storage.split_collector=attach(storage.split)
  storage.bridge=build(POLE,208,0);storage.end_pole=build(POLE,216,0)
  storage.remote_sink=build(RECEIVER,217,1)
  check(prototypes.entity[POLE].electric_energy_source_prototype==nil,"pole has no electric energy source")
  check(not prototypes.entity[COLLECTOR].selectable_in_game,"helper is not selectable")
end)
script.on_nth_tick(10,function()
  local tick=game.tick
  if tick==10 then
    equal(storage.bare_sink.energy,0,"bare baseline")
    equal(storage.paired_sink.energy,0,"paired baseline")
    check(storage.split.electric_network_id==storage.end_pole.electric_network_id,"initial network connected")
    strike(0)
  elseif tick==40 then
    equal(storage.bare_sink.energy,0,"bare pole cannot collect lightning")
    check(#storage.hits==1 and storage.hits[1].target==POLE and storage.hits[1].effect=="experiment-pole-strike","native strike targets bare pole")
    strike(100)
  elseif tick==70 then
    equal(storage.paired_sink.energy+storage.other_sink.energy,500000,"native collector supplies exactly 500 kJ")
    equal(storage.collector.energy,0,"collected energy leaves helper")
    check(storage.paired.electric_network_id==storage.other_pole.electric_network_id,"nearby different-force poles share native copper network")
    equal(storage.other_sink.energy,250000,"connected other-force receiver shares energy")
    check(#storage.hits==2 and storage.hits[2].target==COLLECTOR and storage.hits[2].effect=="experiment-attractor-strike","attractor uses distinct hit callback")
    storage.other_pole.get_wire_connector(defines.wire_connector_id.pole_copper, false).disconnect_all()
    storage.paired_sink.energy=0;storage.other_sink.energy=0
    storage.bridge.destroy()
  elseif tick==80 then
    check(storage.split.electric_network_id~=storage.end_pole.electric_network_id,"bridge removal splits network")
    strike(100)
    strike(200)
  elseif tick==110 then
    check(storage.paired.electric_network_id~=storage.other_pole.electric_network_id,"different-force poles disconnected")
    equal(storage.paired_sink.energy,250000,"overlapping owner coverage shares energy")
    equal(storage.other_sink.energy,250000,"disconnected but overlapping other-force coverage shares energy")
    storage.other_pole.destroy();storage.other_sink.destroy()
    storage.other_pole=build(POLE,150,0,game.forces["lightning-isolation"])
    storage.other_sink=build(RECEIVER,151,1,game.forces["lightning-isolation"])
    storage.paired_sink.energy=0
    strike(100)
    equal(storage.split_collector.energy,500000,"disconnected collector retains energy")
    equal(storage.remote_sink.energy,0,"disconnected receiver gets no energy")
    storage.bridge=build(POLE,208,0)
  elseif tick==140 then
    equal(storage.paired_sink.energy,500000,"separate coverage keeps owner energy")
    equal(storage.other_sink.energy,0,"separate other-force coverage receives nothing")
    check(storage.split.electric_network_id==storage.end_pole.electric_network_id,"rebuilt bridge joins network")
    equal(storage.remote_sink.energy,500000,"reconnected receiver gets buffered energy")
    storage.split.destroy()
  elseif tick==160 then
    check(not storage.split_collector.valid and storage.cleaned==1,"owner removal cleans hidden helper")
    storage.split=build(POLE,200,0);storage.split_collector=attach(storage.split)
    strike(200)
  elseif tick==200 then
    equal(storage.remote_sink.energy,1000000,"replacement collects exactly one strike")
    check(storage.surface.count_entities_filtered{name=COLLECTOR}==2,"no duplicate or orphan collectors")
    check(storage.paired.health==storage.initial_health,"lightning preserves pole health")
    check(storage.bare.health==storage.initial_health,"uncollected lightning preserves pole health")
    storage.split.die()
  elseif tick==240 then
    check(not storage.split_collector.valid and storage.cleaned==2,"pole death cleans helper")
    local result={schema=1,case=CASE,status=#storage.failures==0 and "pass" or "fail",tick=tick,
      factorio_version=script.active_mods.base,assertions=storage.assertions,
      failure_count=#storage.failures,failures=storage.failures,
      observations={strike_energy=1000000,efficiency=0.5,hits=storage.hits,
        bare_energy=storage.bare_sink.energy,paired_energy=storage.paired_sink.energy,
        other_force_energy=storage.other_sink.energy,remote_energy=storage.remote_sink.energy}}
    helpers.write_file("factorio-tests/"..CASE..".json",helpers.table_to_json(result),false)
    script.on_nth_tick(10,nil)
    if #storage.failures>0 then error(helpers.table_to_json(result)) end
  end
end)

-- given: 1 MW sources, 100 kW loads, optional 600 kW charging; fixed 1 MJ strikes.
-- place: independent ordinary, charging, lightning, and switched-pole grids.
-- Lightning grids compare primary-output and tertiary collector buffers.
-- connect: native copper networks, with no global network.
-- act: sample 30-tick flows; disable poles/collectors; replace poles with zero-area variants.
-- run: 450 ticks; clear consumer buffers once on entering offline mode.
-- expect: demand-limited statistics; cutoff/reset outside the pole centre only.
local CASE="experiment-network-trip"
local POLE="factorio-test-trip-pole"
local OFF="factorio-test-trip-pole-offline"
local SOURCE="factorio-test-trip-source"
local LOAD="factorio-test-trip-load"
local BATTERY="factorio-test-trip-battery"
local COLLECTOR="factorio-test-pole-collector"
local function check(ok,message)
  storage.assertions=storage.assertions+1
  if not ok then storage.failures[#storage.failures+1]=message end
end
local function build(name,x,y)
  return assert(storage.surface.create_entity{name=name,position={x,y},force=game.forces.player})
end
local function counts(pole)
  local stats=pole.electric_network_statistics
  local input,output=0,0
  for _,n in pairs(stats.input_counts) do input=input+n end
  for _,n in pairs(stats.output_counts) do output=output+n end
  return {input=input,output=output,storage=stats.storage_counts}
end
local function window(pole,old)
  local now=counts(pole)
  return {produced=now.output-old.output,consumed=now.input-old.input,storage=now.storage}
end
local function replace(old,name)
  local position=old.position
  local replacement=storage.surface.create_entity{name=name,position=position,force=old.force,
    fast_replace=true,spill=false}
  check(replacement~=nil,"pole replacement succeeds: "..name)
  return replacement
end
script.on_init(function()
  storage.assertions=0;storage.failures={};storage.observations={}
  storage.surface=game.planets["factorio-test-lightning-planet"].create_surface()
  local s=storage.surface
  for _,x in ipairs({0,100,200,300,400}) do s.request_to_generate_chunks({x,0},2) end
  s.force_generate_chunk_requests()
  for _,e in pairs(s.find_entities()) do e.destroy() end
  local tiles={}
  for x=-10,410 do for y=-8,8 do tiles[#tiles+1]={name="grass-1",position={x,y}} end end
  s.set_tiles(tiles,true,false,false,false)
  storage.rows={}
  for _,x in ipairs({0,100}) do
    local row={pole=build(POLE,x,0),source=build(SOURCE,x+1,0),load=build(LOAD,x+1,1)}
    if x==100 then row.battery=build(BATTERY,x+1,2) end
    storage.rows[#storage.rows+1]=row
  end
  storage.lightning={pole=build(POLE,200,0),collector=build(COLLECTOR,200,0),load=build(LOAD,201,1)}
  storage.tertiary={pole=build(POLE,400,0),collector=build(COLLECTOR.."-tertiary",400,0),load=build(LOAD,401,1)}
  storage.cut={pole=build(POLE,300,0),remote=build(POLE,308,0),source=build(SOURCE,301,0),load=build(LOAD,309,1)}
end)
script.on_nth_tick(30,function()
  local tick=game.tick
  local rows,lightning,cut=storage.rows,storage.lightning,storage.cut
  if tick==60 then
    for _,row in ipairs(rows) do row.before=counts(row.pole) end
    lightning.before=counts(lightning.pole)
    storage.surface.execute_lightning{name="factorio-test-lightning",position={202,2}}
    storage.surface.execute_lightning{name="factorio-test-lightning",position={402,2}}
  elseif tick==90 then
    for i,row in ipairs(rows) do storage.observations["window_"..i]=window(row.pole,row.before) end
    storage.observations.lightning=window(lightning.pole,lightning.before)
    storage.observations.collector_buffer=lightning.collector.energy
    storage.observations.collector_storage={}
    for _,row in ipairs({lightning,storage.tertiary}) do
      local stats=row.pole.electric_network_statistics
      storage.observations.collector_storage[row.collector.name]={
        energy=row.collector.energy,
        total=stats.get_storage_count(row.collector.name),
        latest=stats.get_flow_count{name=row.collector.name,category="storage",
          precision_index=defines.flow_precision_index.five_seconds,sample_index=1},
      }
      local sample=storage.observations.collector_storage[row.collector.name]
      check(sample.energy>450000,"collector retains strike energy: "..row.collector.name)
      check(sample.total==0,"collector buffer absent from storage totals: "..row.collector.name)
      check(sample.latest==0,"collector buffer absent from latest storage sample: "..row.collector.name)
    end
    check(storage.observations.window_1.produced>0 and storage.observations.window_1.consumed>0,"live network statistics")
    for i=1,2 do
      local sample=storage.observations["window_"..i]
      check(math.abs(sample.produced-sample.consumed)<1,"delivered production matches consumption, case "..i)
    end
    cut.pole.active=false;cut.remote.active=false
    cut.load.energy=0
    lightning.collector.active=false
    lightning.load.energy=0
  elseif tick==120 then
    storage.observations.inactive_pole_load_energy=cut.load.energy
    storage.observations.inactive_collector_load_energy=lightning.load.energy
    check(cut.load.energy>0,"inactive poles still transmit electricity")
    check(lightning.load.energy>0,"inactive collector still supplies electricity")
    cut.pole=replace(cut.pole,OFF);cut.remote=replace(cut.remote,OFF)
    cut.load.energy=0
    storage.new_load=build(LOAD,309,2)
    storage.center_source=build(SOURCE,308,0)
    storage.center_load=build(LOAD,308,0)
  elseif tick==180 then
    storage.observations.offline_load_energy=cut.load.energy
    storage.observations.offline_new_load_energy=storage.new_load.energy
    storage.observations.offline_center_load_energy=storage.center_load.energy
    check(storage.center_load.energy>0,"zero-area poles still power overlapping helpers")
    check(cut.load.energy==0,"zero-area poles cut existing load")
    check(storage.new_load.energy==0,"new load remains unpowered")
    check(cut.pole.electric_network_id==cut.remote.electric_network_id,"offline poles retain shared wire network")
  elseif tick==240 then
    check(cut.load.energy==0 and storage.new_load.energy==0,"offline remains latched without repeated drains")
    -- A reset from the remote pole identifies the same retained network.
    cut.pole=replace(cut.pole,POLE);cut.remote=replace(cut.remote,POLE)
  elseif tick==300 then
    check(cut.load.energy>0 and storage.new_load.energy>0,"scripted reset restores existing and new consumers")
    check(cut.pole.electric_network_id==cut.remote.electric_network_id,"reset retains connection")
    storage.observations.reset_load_energy=cut.load.energy
  elseif tick==450 then
    local result={schema=1,case=CASE,status=#storage.failures==0 and "pass" or "fail",tick=tick,
      factorio_version=script.active_mods.base,assertions=storage.assertions,
      failure_count=#storage.failures,failures=storage.failures,observations=storage.observations}
    helpers.write_file("factorio-tests/"..CASE..".json",helpers.table_to_json(result),false)
    log(helpers.table_to_json(result))
    script.on_nth_tick(30,nil)
    if #storage.failures>0 then error(helpers.table_to_json(result)) end
  end
end)

-- given: each isolated network has a 1 MW source, two 100 kW loads
-- (primary and secondary), and optionally two 10 MJ batteries charged to 5 MJ each.
-- place: one hidden 1 TW primary-input sink at the pole when tripped.
-- connect: native copper networks and normal pole supply areas.
-- act: spawn the sink at tick 60; remove it at tick 240 to reset.
-- run: 450 ticks; no scripted energy writes after initial battery charge.
-- expect: measure residual consumption, battery discharge, and recovery.
local CASE="experiment-network-sink"
local PREFIX="factorio-test-trip-"
local function check(ok,message)
  storage.assertions=storage.assertions+1
  if not ok then storage.failures[#storage.failures+1]=message end
end
local function build(kind,x,y)
  return assert(storage.surface.create_entity{name=PREFIX..kind,position={x,y},force=game.forces.player})
end
local function consumed(row,kind)
  -- Electrical statistics use input for consumption, output for production.
  return row.pole.electric_network_statistics.get_input_count(PREFIX..kind)
end
script.on_init(function()
  storage.assertions=0;storage.failures={};storage.observations={}
  storage.surface=game.planets["factorio-test-lightning-planet"].create_surface()
  local s=storage.surface
  for _,x in ipairs({0,100}) do s.request_to_generate_chunks({x,0},2) end
  s.force_generate_chunk_requests()
  for _,e in pairs(s.find_entities()) do e.destroy() end
  local tiles={}
  for x=-10,110 do for y=-8,8 do tiles[#tiles+1]={name="grass-1",position={x,y}} end end
  s.set_tiles(tiles,true,false,false,false)
  storage.rows={}
  for i,x in ipairs({0,100}) do
    local row={x=x,pole=build("pole",x,0),source=build("source",x+1,0),
      load=build("load",x+1,1),primary=build("primary-load",x-1,1)}
    if i==2 then
      row.battery=build("battery",x+1,2);row.battery.energy=5000000
      row.second_battery=build("battery",x-1,2);row.second_battery.energy=5000000
    end
    storage.rows[i]=row
    storage.observations[i]={}
  end
end)
script.on_nth_tick(30,function()
  local tick=game.tick
  for i,row in ipairs(storage.rows) do
    local o=storage.observations[i]
    if tick==60 then
      check(row.load.energy>0 and row.primary.energy>0,"both priorities powered before trip: "..i)
      row.sink=build("sink",row.x,0)
      row.network_id=row.pole.electric_network_id
      if row.battery then o.battery_before=row.battery.energy+row.second_battery.energy end
    elseif tick==120 then
      row.before={load=consumed(row,"load"),primary=consumed(row,"primary-load"),sink=consumed(row,"sink")}
    elseif tick==180 then
      o.secondary_joules=consumed(row,"load")-row.before.load
      o.primary_joules=consumed(row,"primary-load")-row.before.primary
      o.sink_joules=consumed(row,"sink")-row.before.sink
      o.secondary_buffer=row.load.energy
      o.primary_buffer=row.primary.energy
      if row.battery then
        o.battery_after=row.battery.energy+row.second_battery.energy
        local stats=row.pole.electric_network_statistics
        o.storage_total=stats.get_storage_count(PREFIX.."battery")
        o.storage_samples={}
        for index=1,5 do
          o.storage_samples[index]=stats.get_flow_count{name=PREFIX.."battery",category="storage",
            precision_index=defines.flow_precision_index.five_seconds,sample_index=index}
        end
        check(math.abs(o.storage_samples[1]-o.battery_after)<1,"latest storage sample sums both accumulator charges")
        check(o.storage_total>o.battery_after,"storage total is historical, not current charge")
      end
      check(o.secondary_joules==0,"secondary consumption stops: "..i)
      check(o.primary_joules>0 and o.primary_joules<1,"primary consumption below 1 J per second but nonzero: "..i)
      check(o.sink_joules>999000,"sink consumes available generation: "..i)
      check(row.pole.electric_network_id==row.network_id,"network identity preserved: "..i)
      if row.battery then check(o.battery_after<o.battery_before,"sink drains battery through its output limit") end
    elseif tick==240 then
      check(row.load.energy==0,"secondary load stays off without scripted drains: "..i)
      row.sink.destroy()
    elseif tick==300 then
      check(row.load.energy>0 and row.primary.energy>0,"removing sink restores both loads: "..i)
      check(row.pole.electric_network_id==row.network_id,"reset preserves network identity: "..i)
    end
  end
  if tick==450 then
    local result={schema=1,case=CASE,status=#storage.failures==0 and "pass" or "fail",tick=tick,
      factorio_version=script.active_mods.base,assertions=storage.assertions,
      failure_count=#storage.failures,failures=storage.failures,observations=storage.observations}
    helpers.write_file("factorio-tests/"..CASE..".json",helpers.table_to_json(result),false)
    log(helpers.table_to_json(result))
    script.on_nth_tick(30,nil)
    if #storage.failures>0 then error(helpers.table_to_json(result)) end
  end
end)

-- given: fixed seed, native storms, four empty starter batteries, 500 kW fixed demand.
-- place/connect: isolated 1/8/32-pole grids; output-cap candidates use test collectors.
-- act: one explicit native strike, then five minutes each at noon and midnight.
-- run: sample native flow every 30 ticks; count collector hits, including buffer overflow.
-- expect: production grid trips; observational grids measure unclipped supply and trip risk.
local CASE='fulgora-power-budget'
local function check(ok,message) storage.assertions=storage.assertions+1;assert(ok,message) end
local profiles={{name='actual',poles=8,actual=true},{name='current-1',poles=1},
  {name='current-8',poles=8},{name='current-32',poles=32},
  {name='cap-0.5-8',poles=8,cap=0.5},{name='cap-1-8',poles=8,cap=1},
  {name='cap-2-8',poles=8,cap=2},{name='cap-5-8',poles=8,cap=5},
  {name='cap-0.5-32',poles=32,cap=0.5},{name='cap-1-32',poles=32,cap=1},
  {name='cap-2-32',poles=32,cap=2},
  {name='cap-0.5-8-dump-2',poles=8,cap=0.5,dump=2},
  {name='cap-0.5-32-dump-8',poles=32,cap=0.5,dump=8}}
local function blank() return {samples=0,trip_samples=0,powered_samples=0,captures=0,
  sum_offered_MW=0,max_offered_MW=0,sum_demand_MW=0,sum_charged_poles=0,max_charged_poles=0} end
script.on_event(defines.events.on_script_trigger_effect,function(event)
  if event.effect_id~='fulgora-power-capture' or not storage.owners then return end
  local target=event.target_entity
  local row=target and target.valid and storage.owners[target.unit_number]
  if row then row[storage.phase].captures=row[storage.phase].captures+1 end
end)
script.on_nth_tick(1,function()
  if game.tick==0 then return end
  script.on_nth_tick(1,nil)
  storage.rows={};storage.owners={};storage.phase='direct';storage.assertions=0
  local surface=game.planets['nullius-fulgora'].create_surface()
  storage.surface=surface
  local settings=surface.map_gen_settings;settings.seed=1729;surface.map_gen_settings=settings
  surface.freeze_daytime=true;surface.daytime=0
  for i,profile in ipairs(profiles) do
    local x=(i-1)*192
    surface.request_to_generate_chunks({x,0},2);surface.force_generate_chunk_requests()
    for _,entity in pairs(surface.find_entities_filtered{area={{x-32,-32},{x+80,64}}}) do entity.destroy() end
    local tiles={};for dx=-10,55 do for y=-10,35 do tiles[#tiles+1]={name='fulgoran-rock',position={x+dx,y}} end end
    surface.set_tiles(tiles,true)
    local row={name=profile.name,dump=profile.dump,poles={},collectors={},batteries={},loads={},
      direct=blank(),day=blank(),night=blank()}
    storage.rows[#storage.rows+1]=row
    local function place(name,px,py,raised)
      return assert(surface.create_entity{name=name,position={px,py},force='player',raise_built=raised})
    end
    for j=1,profile.poles do
      local px=x+((j-1)%8)*6;local py=math.floor((j-1)/8)*6
      local pole=place('small-electric-pole',px,py,profile.actual or false)
      row.poles[j]=pole
      if j>1 then
        local neighbour=row.poles[j%8==1 and j-8 or j-1]
        pole.get_wire_connector(defines.wire_connector_id.pole_copper,true).connect_to(
          neighbour.get_wire_connector(defines.wire_connector_id.pole_copper,true))
      end
      local collector
      if profile.actual then
        collector=surface.find_entities_filtered{name='nullius-pole-lightning-collector',position=pole.position,radius=0.1}[1]
      else
        collector=place(profile.cap and 'factorio-test-power-collector-'..math.floor(profile.cap*1000) or
          'nullius-pole-lightning-collector',pole.position.x,pole.position.y,false)
      end
      assert(collector)
      row.collectors[j]=collector;storage.owners[collector.unit_number]=row
    end
    -- Four batteries fit around the first pole; each overlaps its supply area.
    for _,p in ipairs({{-2,-2},{2,-2},{-2,2},{2,2}}) do
      row.batteries[#row.batteries+1]=place('nullius-grid-battery-1',x+p[1],p[2],false)
    end
    for j=1,5 do row.loads[j]=place('factorio-test-trip-load',x,1,false) end
    if profile.dump then place('factorio-test-power-dump-'..profile.dump,x,1,false) end
    surface.execute_lightning{name='nullius-fulgora-lightning',position={x,0}}
  end
end)
script.on_nth_tick(30,function()
  if game.tick==0 then return end
  for _,row in ipairs(storage.rows) do
    local flow=row.poles[1].electric_network.parent_network.flow_last_tick
    local offered=(flow.primary_output+flow.secondary_output+flow.solar_output)*60/1e6
    local demand=(flow.primary_demand+flow.secondary_demand+flow.tertiary_demand)*60/1e6
    if row.dump then assert(demand>=row.dump+0.5-1e-6,'dump demand is capped by its buffer') end
    local sample=row[storage.phase]
    sample.samples=sample.samples+1
    sample.sum_offered_MW=sample.sum_offered_MW+offered
    sample.sum_demand_MW=sample.sum_demand_MW+demand
    sample.max_offered_MW=math.max(sample.max_offered_MW,offered)
    if offered>2*demand and offered-demand>1 then sample.trip_samples=sample.trip_samples+1 end
    if row.loads[1].energy>0 then sample.powered_samples=sample.powered_samples+1 end
    local charged=0;for _,c in ipairs(row.collectors) do if c.energy>0 then charged=charged+1 end end
    sample.sum_charged_poles=sample.sum_charged_poles+charged
    sample.max_charged_poles=math.max(sample.max_charged_poles,charged)
    if row.name=='actual' and not row.first_trip and remote.call('nullius-test-overload','offline',row.poles[1]) then
      row.first_trip=game.tick
    end
    if game.tick==30 then row.first_flow={offered_MW=offered,demand_MW=demand} end
    if game.tick==1800 or game.tick==19800 or game.tick==37800 then
      sample.end_battery_MJ=0;sample.end_collector_MJ=0
      for _,b in ipairs(row.batteries) do sample.end_battery_MJ=sample.end_battery_MJ+b.energy/1e6 end
      for _,c in ipairs(row.collectors) do sample.end_collector_MJ=sample.end_collector_MJ+c.energy/1e6 end
    end
  end
  if game.tick==1800 then storage.phase='day'
  elseif game.tick==19800 then storage.phase='night';storage.surface.daytime=0.5
  elseif game.tick==37800 then
    local result={}
    for _,row in ipairs(storage.rows) do
      result[#result+1]={name=row.name,poles=#row.poles,first_trip=row.first_trip,first_flow=row.first_flow,
        direct=row.direct,day=row.day,night=row.night}
    end
    check(storage.rows[1].first_trip<=60,'production overload did not trip promptly')
    for _,row in ipairs(storage.rows) do
      check(row.direct.captures>0,'no declared strike captured: '..row.name)
      if row.dump then
        for _,phase in ipairs({'direct','day','night'}) do
          check(row[phase].trip_samples==0,'protected grid exceeded trip threshold')
          check(row[phase].powered_samples==row[phase].samples,'protected load lost power')
        end
      end
    end
    helpers.write_file('factorio-tests/'..CASE..'.json',helpers.table_to_json{
      schema=1,case=CASE,status='pass',failure_count=0,assertions=storage.assertions,tick=game.tick,
      factorio_version=script.active_mods.base,observations=result},false)
    script.on_nth_tick(30,nil)
  end
end)

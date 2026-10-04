-- given: generated planner loads, seed 1729, current poles/coils, empty batteries.
-- place: prescribed compact/spread collectors; artificial island pads for batteries.
-- connect: one noncollecting test distribution pole per bank; ideal copper links.
-- act: native storms only, no injected charge or strikes; freeze noon then midnight.
-- run: 60 s warmup, 600 s noon, 600 s midnight. Measure shortages; do not reset trips.
-- expect: valid isolated networks and measured native energy totals, not full supply.
return function(CASE,profiles)
local circuit=require('__nullius-star__/scenarios/fulgora-switched-grounding/circuit')
local collectors=require('__nullius-star__/shared/fulgora-collectors')
local function check(ok,msg) storage.assertions=storage.assertions+1;assert(ok,msg) end
local function blank() return {ticks=0,captures=0,trips=0,secondary_gaps=0,surge_gaps=0,switch_on=0,sensor_sum=0,sensor_high=0} end
local function totals(row)
  local stats=row.poles[1].electric_network_statistics
  local t={secondary_J=stats.get_input_count(row.secondary.name),surge_J=stats.get_input_count(row.surge.name),
    collector_J=0,coil_J=stats.get_input_count('nullius-grounding-coil')}
  for _,name in ipairs(collectors.names) do t.collector_J=t.collector_J+stats.get_output_count(name) end
  return t
end
script.on_event(defines.events.on_script_trigger_effect,function(e)
  if e.effect_id~='fulgora-power-capture' or not storage.owners then return end
  local row=e.target_entity and storage.owners[e.target_entity.unit_number]
  if row and storage.phase then row[storage.phase].captures=row[storage.phase].captures+1 end
end)
script.on_nth_tick(1,function()
  if game.tick==0 then return end
  script.on_nth_tick(1,nil)
  storage.assertions=0;storage.rows={};storage.owners={}
  local s=game.planets['nullius-fulgora'].create_surface();storage.surface=s
  local m=s.map_gen_settings;m.seed=1729;s.map_gen_settings=m;s.freeze_daytime=true;s.daytime=0
  for index,profile in ipairs(profiles) do
    local x=(index-1)*1536
    local wide=profile.switched and 940 or profile.layout=='spread' and 410 or 140
    s.request_to_generate_chunks({x+wide/2,wide/2},math.ceil(wide/64)+2)
    s.request_to_generate_chunks({x-100,100},3);s.force_generate_chunk_requests()
    for _,e in pairs(s.find_entities_filtered{area={{x-160,-40},{x+wide+40,math.max(wide+40,200)}}}) do e.destroy() end
    local tiles={}
    for dx=-24,wide do for y=-24,wide do tiles[#tiles+1]={name='nullius-fulgora-sediment',position={x+dx,y}} end end
    for dx=-124,-20 do for y=65,170 do tiles[#tiles+1]={name='fulgoran-rock',position={x+dx,y}} end end
    s.set_tiles(tiles,true)
    local row={name=profile.name,secondary_MW=profile.secondary_MW,surge_MW=profile.surge_MW,
      poles={},batteries={},day=blank(),night=blank(),load_name=profile.load_name or profile.name};storage.rows[#storage.rows+1]=row
    local function place(name,dx,y,raised)
      check(s.can_place_entity{name=name,position={x+dx,y},force='player'},'invalid '..profile.name..' placement '..name..' '..dx..','..y)
      return assert(s.create_entity{name=name,position={x+dx,y},force='player',raise_built=raised})
    end
    local function pole(name,dx,y)
      local p=place(name,dx,y,true);row.poles[#row.poles+1]=p
      local c=s.find_entities_filtered{name=collectors.by_pole[name].name,position=p.position,radius=.1}[1]
      check(c~=nil,'missing collector');storage.owners[c.unit_number]=row
      return p
    end
    if profile.layout=='starter' then
      for _,p in ipairs({{0,0},{42,0},{0,42},{42,42}}) do place('nullius-grounding-coil',p[1],p[2],true) end
      for i=0,7 do for _,p in ipairs({{2+i*6,2},{2+i*6,44},{-4,2+i*6},{50,2+i*6}}) do pole('small-electric-pole',p[1],p[2]) end end
      for _,p in ipairs({{-6,-4},{50,-4},{-6,50},{50,50}}) do pole('big-electric-pole',p[1],p[2]) end
    else
      local count=profile.layout=='spread' and 256 or 32
      local columns=profile.layout=='spread' and 16 or 8
      local spacing=profile.layout=='spread' and 24 or 6
      for i=0,count-1 do pole('big-electric-pole',(i%columns)*spacing,math.floor(i/columns)*spacing) end
      for i=0,(profile.switched and profile.permanent or math.ceil(count/8))-1 do
        local cx=profile.layout=='spread' and 12+(i%8)*48 or -16+i*42
        local cy=profile.layout=='spread' and 12+math.floor(i/8)*96 or -20
        place('nullius-grounding-coil',cx,cy,true)
        local feed=place('factorio-test-audit-distribution',cx+3,cy+3,false)
        check(feed.get_wire_connector(defines.wire_connector_id.pole_copper,true).connect_to(
          row.poles[1].get_wire_connector(defines.wire_connector_id.pole_copper,true)) or
          feed.electric_network_id==row.poles[1].electric_network_id,'disconnected permanent coil')
      end
    end
    -- Battery bank is off the collector grid; this test excludes distribution costs.
    local distribution=place('factorio-test-audit-distribution',-72,114,false)
    local previous=distribution
    for _,pos in ipairs({{-48,80},{-24,46},{0,8}}) do
      local link=place('factorio-test-audit-distribution',pos[1],pos[2],false)
      check(link.get_wire_connector(defines.wire_connector_id.pole_copper,true).connect_to(
        previous.get_wire_connector(defines.wire_connector_id.pole_copper,true)) or
        link.electric_network_id==previous.electric_network_id,'bank wire failed')
      previous=link
    end
    check(previous.get_wire_connector(defines.wire_connector_id.pole_copper,true).connect_to(
      row.poles[1].get_wire_connector(defines.wire_connector_id.pole_copper,true)) or
      previous.electric_network_id==row.poles[1].electric_network_id,'collector wire failed')
    for i=0,profile.batteries-1 do
      row.batteries[#row.batteries+1]=place('nullius-grid-battery-1',-120+(i%25)*4,70+math.floor(i/25)*4,false)
    end
    row.secondary=place('factorio-test-audit-'..row.load_name..'-secondary',-72,113,false)
    row.surge=place('factorio-test-audit-'..row.load_name..'-surge',-72,113,false)
    for _,p in ipairs(row.poles) do check(p.electric_network_id==distribution.electric_network_id,'disconnected collector '..profile.name..' '..p.position.x..','..p.position.y) end
    if profile.switched then
      circuit(s,x,profile,row,place,check)
    end
    row.network=distribution.electric_network_id
    for _,other in ipairs(storage.rows) do if other~=row then check(other.network~=row.network,'overlapping grids') end end
  end
end)
script.on_nth_tick(30,function()
  if game.tick==0 then return end
  for _,row in ipairs(storage.rows) do
    if remote.call('nullius-test-overload','offline',row.poles[1]) then row.first_trip=row.first_trip or game.tick end
    if row.switch and row.switch.power_switch_state then row.switch_seen=true end
  end
  if storage.phase then
    for _,row in ipairs(storage.rows) do
      local v=row[storage.phase];v.ticks=v.ticks+30
      if remote.call('nullius-test-overload','offline',row.poles[1]) then
        v.trips=v.trips+1;row.first_trip=row.first_trip or game.tick
      end
      if row.switch then
        if row.switch.power_switch_state then v.switch_on=v.switch_on+1 end
        local charge=100*row.sensor.energy/row.sensor.electric_buffer_size
        v.sensor_sum=v.sensor_sum+charge
        if charge>=80 then v.sensor_high=v.sensor_high+1 end
      end
      if row.secondary.energy<=0 then v.secondary_gaps=v.secondary_gaps+1 end
      if row.surge_MW>0 and row.surge.energy<=0 then v.surge_gaps=v.surge_gaps+1 end
    end
  end
  if game.tick==3600 or game.tick==39600 or game.tick==75600 then
    for _,row in ipairs(storage.rows) do
      if row.switch then check(row.switch_seen,'switch never closed: '..row.name) end
      local t=totals(row)
      if row.start then
        local v=row[storage.phase]
        for k,n in pairs(t) do v[k]=n-row.start[k] end
        v.battery_MJ=0
        for _,b in ipairs(row.batteries) do v.battery_MJ=v.battery_MJ+b.energy/1e6 end
        check(v.ticks==36000,'phase duration');check(v.captures>0,'no native captures')
      end
      row.start=t
    end
    if game.tick==3600 then storage.phase='day'
    elseif game.tick==39600 then storage.phase='night';storage.surface.daytime=.5
    else
      local result={}
      for _,row in ipairs(storage.rows) do result[#result+1]={name=row.name,secondary_MW=row.secondary_MW,surge_MW=row.surge_MW,day=row.day,night=row.night,first_trip=row.first_trip} end
      helpers.write_file('factorio-tests/'..CASE..'.json',helpers.table_to_json{schema=1,case=CASE,status='pass',failure_count=0,
        assertions=storage.assertions,tick=game.tick,factorio_version=script.active_mods.base,observations=result},false)
      script.on_nth_tick(30,nil)
    end
  end
end)

end

-- given: generated planner loads, seed 1729, current poles/coils, empty batteries.
-- place: prescribed compact/spread collectors; artificial island pads for batteries.
-- connect: one noncollecting test distribution pole per bank; ideal copper links.
-- act: native storms only, no injected charge or strikes; freeze noon then midnight.
-- run: 60 s warmup, 30 s noon, 30 s midnight. Measure shortages; do not reset trips.
-- expect: valid isolated networks and measured native energy totals, not full supply.
return function(CASE,profiles)
local warmup=3600
local phase_ticks=1800
local night_start=warmup+phase_ticks
local finish_tick=night_start+phase_ticks
local circuit=require('__nullius-star__/scenarios/fulgora-switched-grounding/circuit')
local starter_grid=require('__nullius-star__/scenarios/fulgora-starter-grid')
local metered=require('__nullius-star__/scenarios/fulgora-metered-grounding/circuit')
local starter_supplies=require('__nullius-star__/shared/fulgora-starter')
local collectors=require('__nullius-star__/shared/fulgora-collectors')
local function check(ok,msg) storage.assertions=storage.assertions+1;assert(ok,msg) end
local function blank() return {ticks=0,captures=0,trips=0,secondary_gaps=0,surge_gaps=0,switch_on=0,sensor_sum=0,sensor_high=0} end
local observe=require('__nullius-star__/scenarios/fulgora-metered-grounding/observe')
for _,profile in ipairs(profiles) do
  if profile.metered then
    script.on_event(defines.events.on_tick,function()
      if game.tick<=finish_tick then observe(storage.rows,check) end
    end)
    break
  end
end
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
    if profile.current_stock then
      local stock={}
      for _,container in ipairs(starter_supplies) do
        for _,stack in ipairs(container) do stock[stack[1]]=(stock[stack[1]] or 0)+stack[2] end
      end
      check(profile.batteries==stock['nullius-grid-battery-1'],'stale starter battery fixture')
      check(profile.coils==stock['nullius-grounding-coil'],'stale starter coil fixture')
      for name,count in pairs(profile.pole_counts) do check(count==stock[name],'stale starter pole fixture') end
    end
    local x=(index-1)*1536
    local wide=profile.starter_switching and 200 or profile.switched and 940 or profile.layout=='spread' and 410 or 140
    s.request_to_generate_chunks({x+wide/2,wide/2},math.ceil(wide/64)+2)
    s.request_to_generate_chunks({x-100,100},3);s.force_generate_chunk_requests()
    for _,e in pairs(s.find_entities_filtered{area={{x-160,-40},{x+wide+40,math.max(wide+40,200)}}}) do e.destroy() end
    local tiles={}
    for dx=-24,wide do for y=-24,wide do tiles[#tiles+1]={name='nullius-fulgora-sediment',position={x+dx,y}} end end
    for dx=-124,-20 do for y=65,170 do tiles[#tiles+1]={name='fulgoran-rock',position={x+dx,y}} end end
    if profile.starter_switching then
      for i=0,3 do for dx=52,56 do for y=1+i*42,5+i*42 do
        tiles[#tiles+1]={name='fulgoran-rock',position={x+dx,y}}
      end end end
    end
    s.set_tiles(tiles,true)
    local row={name=profile.name,secondary_MW=profile.secondary_MW,surge_MW=profile.surge_MW,
      poles={},batteries={},day=blank(),night=blank(),load_name=profile.load_name or profile.name,minimum_supply_percent=profile.minimum_supply_percent};storage.rows[#storage.rows+1]=row
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
    local starter_control
    if profile.starter_switching then
      starter_control=starter_grid(profile,row,pole,place,check)
    elseif profile.layout=='starter' then
      check(profile.pole_counts['small-electric-pole']==40 and profile.pole_counts['big-electric-pole']==6,
        'starter layout must be revised for changed pole stock')
      for _,p in ipairs({{0,0},{42,0},{0,42},{42,42}}) do place('nullius-grounding-coil',p[1],p[2],true) end
      for i=0,9 do for _,p in ipairs({{2+i*6,2},{2+i*6,56},{-4,2+i*6},{62,2+i*6}}) do pole('small-electric-pole',p[1],p[2]) end end
      for _,p in ipairs({{-6,-4},{62,-4},{-6,62},{62,62},{28,-4},{28,62}}) do pole('big-electric-pole',p[1],p[2]) end
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
    for _,pos in ipairs(profile.starter_switching and {{-48,114},{-24,114},{0,110}} or {{-48,80},{-24,46},{0,8}}) do
      local link=place(profile.starter_switching and 'factorio-test-audit-wire' or 'factorio-test-audit-distribution',pos[1],pos[2],false)
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
    if starter_control then starter_control() end
    for _,p in ipairs(row.poles) do check((row.isolated_poles and row.isolated_poles[p.unit_number]) or p.electric_network_id==distribution.electric_network_id,'disconnected collector '..profile.name..' '..p.position.x..','..p.position.y) end
    if profile.switched then
      if profile.metered then metered(s,x,profile,row,place,check)
      else circuit(s,x,profile,row,place,check) end
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
      if row.starter_banks then
        local connected=0
        for _,bank in ipairs(row.starter_banks) do if bank.switch.power_switch_state then connected=connected+1 end end
        v.connected_coils=(v.connected_coils or 0)+connected
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
  if game.tick==warmup or game.tick==night_start or game.tick==finish_tick then
    for _,row in ipairs(storage.rows) do
      if row.switch then check(row.switch_seen,'switch never closed: '..row.name) end
      local t=totals(row)
      if row.start then
        local v=row[storage.phase]
        for k,n in pairs(t) do v[k]=n-row.start[k] end
        v.battery_MJ=0
        for _,b in ipairs(row.batteries) do v.battery_MJ=v.battery_MJ+b.energy/1e6 end
        check(v.ticks==phase_ticks,'phase duration');check(v.captures>0,'no native captures')
        if row.minimum_supply_percent then
          check(100*v.secondary_J/(row.secondary_MW*1e6*phase_ticks/60)>=row.minimum_supply_percent,
            row.name..' supply below target in '..storage.phase)
          check(not row.first_trip,row.name..' tripped')
        end
      end
      row.start=t
    end
    if game.tick==warmup then storage.phase='day'
    elseif game.tick==night_start then storage.phase='night';storage.surface.daytime=.5
    else
      local result={}
      for _,row in ipairs(storage.rows) do result[#result+1]={name=row.name,batteries=#row.batteries,poles=#row.poles,minimum_supply_percent=row.minimum_supply_percent,secondary_MW=row.secondary_MW,surge_MW=row.surge_MW,day=row.day,night=row.night,first_trip=row.first_trip,controller=row.controller} end
      helpers.write_file('factorio-tests/'..CASE..'.json',helpers.table_to_json{schema=1,case=CASE,status='pass',failure_count=0,
        assertions=storage.assertions,tick=game.tick,factorio_version=script.active_mods.base,observations=result},false)
      script.on_nth_tick(30,nil)
    end
  end
end)

end

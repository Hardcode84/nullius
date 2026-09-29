-- given: seed 1729, three isolated starter grids, native day and night storms.
-- Each grid: 32 poles, four real coils, four empty batteries, 500 kW debug load.
-- place/connect: legal sand coil spacing, island batteries, copper-connected poles.
-- act: one native startup strike per grid; fill batteries once for the terminal fault.
-- run: 30 seconds startup, ten minutes noon, ten minutes midnight, then a fault.
-- expect: full load energy, continuous sampled supply, no protected trips; removing coils causes a trip.
local function check(ok,message) storage.assertions=storage.assertions+1;assert(ok,message) end
script.on_nth_tick(1,function()
  if game.tick==0 then return end
  script.on_nth_tick(1,nil)
  storage.assertions=0;storage.rows={}
  local s=game.planets['nullius-fulgora'].create_surface();storage.surface=s
  local settings=s.map_gen_settings;settings.seed=1729;s.map_gen_settings=settings
  s.freeze_daytime=true;s.daytime=0
  for grid=0,2 do
    local x=grid*256
    s.request_to_generate_chunks({x,0},3);s.force_generate_chunk_requests()
    for _,e in pairs(s.find_entities_filtered{area={{x-32,-32},{x+80,80}}}) do e.destroy() end
    local tiles={}
    for dx=-20,70 do for y=-20,70 do
      tiles[#tiles+1]={name='nullius-fulgora-sediment',position={x+dx,y}}
    end end
    for dx=5,29 do for y=3,7 do tiles[#tiles+1]={name='fulgoran-rock',position={x+dx,y}} end end
    s.set_tiles(tiles,true)
    local row={poles={},coils={},batteries={},loads={},day={samples=0,powered=0},night={samples=0,powered=0}}
    storage.rows[#storage.rows+1]=row
    local function place(name,dx,y,raised)
      check(s.can_place_entity{name=name,position={x+dx,y},force='player'},'illegal starter placement '..name)
      return assert(s.create_entity{name=name,position={x+dx,y},force='player',raise_built=raised})
    end
    for _,p in ipairs({{0,0},{42,0},{0,42},{42,42}}) do row.coils[#row.coils+1]=place('nullius-grounding-coil',p[1],p[2],true) end
    for i=0,7 do
      for _,p in ipairs({{2+i*6,2},{2+i*6,44},{-4,2+i*6},{50,2+i*6}}) do
        row.poles[#row.poles+1]=place('small-electric-pole',p[1],p[2],true)
      end
    end
    for _,pole in ipairs(row.poles) do check(pole.electric_network_id==row.poles[1].electric_network_id,'disconnected pole') end
    for i=0,3 do row.batteries[#row.batteries+1]=place('nullius-grid-battery-1',8+i*6,5,false) end
    -- The debug load has no physical footprint; five units request 500 kW.
    for i=1,5 do row.loads[i]=assert(s.create_entity{name='factorio-test-trip-load',position={x+2,1},force='player'}) end
    s.execute_lightning{name='nullius-fulgora-lightning',position=row.poles[1].position}
  end
end)
script.on_nth_tick(30,function()
  if game.tick==0 then return end
  if game.tick<=73800 then
    for i,row in ipairs(storage.rows) do
      check(not remote.call('nullius-test-overload','offline',row.poles[1]),'protected grid tripped '..i)
      if game.tick>1800 then
        local sample=game.tick<=37800 and row.day or row.night
        sample.samples=sample.samples+1
        local powered=true
        for _,load in ipairs(row.loads) do if load.energy==0 then powered=false end end
        if powered then sample.powered=sample.powered+1 end
      end
    end
  end
  if game.tick==1800 or game.tick==37800 or game.tick==73800 then
    for i,row in ipairs(storage.rows) do
      local consumed=row.poles[1].electric_network_statistics.get_input_count('factorio-test-trip-load')
      if row.energy_start then
        local phase=game.tick==37800 and row.day or row.night
        phase.consumed_J=consumed-row.energy_start
        -- Native totals round; 100 J is below one consumer's 1667 J tick.
        check(math.abs(phase.consumed_J-300000000)<100,'load did not receive 300 MJ in ten minutes: '..i..' got '..phase.consumed_J)
      end
      row.energy_start=consumed
    end
  end
  if game.tick==37800 then storage.surface.daytime=0.5
  elseif game.tick==73800 then
    for i,row in ipairs(storage.rows) do
      check(row.day.powered==row.day.samples,'daytime supply gap in starter grid '..i..': '..row.day.powered..'/'..row.day.samples)
      check(row.night.powered==row.night.samples,'nighttime supply gap in starter grid '..i)
    end
    -- Full batteries no longer absorb power; a new strike must trip an ungrounded grid.
    local row=storage.rows[1]
    for _,coil in ipairs(row.coils) do coil.destroy{raise_destroy=true} end
    for _,battery in ipairs(row.batteries) do battery.energy=battery.electric_buffer_size end
    storage.surface.execute_lightning{name='nullius-fulgora-lightning',position=row.poles[1].position}
  elseif game.tick==73860 then
    check(remote.call('nullius-test-overload','offline',storage.rows[1].poles[1]),'ungrounded full-storage grid did not trip')
    local observations={}
    for i,row in ipairs(storage.rows) do observations[i]={day=row.day,night=row.night} end
    helpers.write_file('factorio-tests/fulgora-starter-power.json',helpers.table_to_json{
      schema=1,case='fulgora-starter-power',status='pass',failure_count=0,assertions=storage.assertions,
      tick=game.tick,factorio_version=script.active_mods.base,observations=observations},false)
    script.on_nth_tick(30,nil)
  end
end)

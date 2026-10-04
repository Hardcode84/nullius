-- given: native 2 MW sources and 100 kW loads; no ambient storms or storage.
-- place/connect: isolated grids and two overlapping, unwired overloaded grids.
-- act/run: one/two-check pulses, a safe gap, pole replacement, split/merge, and sustained excess.
-- expect: three consecutive checks per shutdown group; a safe check clears history.
local P='factorio-test-trip-'
local function check(ok,message) storage.assertions=storage.assertions+1;assert(ok,message) end
local function offline(row) return remote.call('nullius-test-overload','offline',row.pole) end
local function place(name,x,y)
  return assert(storage.surface.create_entity{name=name,position={x,y},force='player',raise_built=true})
end
local function supply(row,watts)
  local p=row.source.position;row.source.destroy()
  row.source=place(P..'source-'..watts,p.x,p.y)
end
script.on_nth_tick(1,function()
  if game.tick==0 then return end
  script.on_nth_tick(1,nil)
  storage.assertions=0;storage.rows={}
  local s=game.planets['nullius-fulgora'].create_surface();storage.surface=s
  s.request_to_generate_chunks({180,0},8);s.force_generate_chunk_requests()
  for _,e in pairs(s.find_entities()) do e.destroy() end
  local tiles={};for x=-10,370 do for y=-10,10 do tiles[#tiles+1]={name='grass-1',position={x,y}} end end
  s.set_tiles(tiles,true)
  for i,x in ipairs({0,50,100,150,200,202,250,300,306,350,356}) do
    storage.rows[i]={pole=place('small-electric-pole',x,0),source=place(P..'source-2000000',x+1,0)}
    place(P..'load',x+1,1)
  end
  storage.rows[6].pole.get_wire_connector(defines.wire_connector_id.pole_copper,true).disconnect_all()
  storage.rows[9].pole.get_wire_connector(defines.wire_connector_id.pole_copper,true).disconnect_all()
  check(storage.rows[8].pole.electric_network_id~=storage.rows[9].pole.electric_network_id,'merge fixture is wired')
  check(storage.rows[10].pole.electric_network_id==storage.rows[11].pole.electric_network_id,'split fixture is not wired')
  check(storage.rows[5].pole.electric_network_id~=storage.rows[6].pole.electric_network_id,'overlap is wired')
end)
local actions={
  [31]=function()
    for _,row in ipairs(storage.rows) do check(not offline(row),'tripped on first check') end
    supply(storage.rows[2],100000)
    check(storage.rows[8].pole.get_wire_connector(defines.wire_connector_id.pole_copper,true).connect_to(
      storage.rows[9].pole.get_wire_connector(defines.wire_connector_id.pole_copper,true)),
      "merge connection failed")
  end,
  [61]=function()
    for _,row in ipairs(storage.rows) do check(not offline(row),'tripped on second check') end
    supply(storage.rows[3],100000);supply(storage.rows[4],100000)
    storage.rows[11].pole.get_wire_connector(defines.wire_connector_id.pole_copper,true).disconnect_all()
    supply(storage.rows[11],100000)
    storage.rows[7].pole=assert(storage.surface.create_entity{name='medium-electric-pole',position={250,0},
      force='player',fast_replace=true,spill=false,raise_built=true})
  end,
  [91]=function()
    for _,i in ipairs({1,5,6,7,8,9,10}) do check(offline(storage.rows[i]),'sustained overload did not trip: '..i) end
    for _,i in ipairs({2,3,4,11}) do check(not offline(storage.rows[i]),'short pulse tripped: '..i) end
    supply(storage.rows[4],2000000)
  end,
  [121]=function() check(not offline(storage.rows[4]),'safe gap did not clear count') end,
  [151]=function() check(not offline(storage.rows[4]),'restarted count tripped early') end,
  [181]=function()
    check(offline(storage.rows[4]),'three fresh checks did not trip')
    helpers.write_file('factorio-tests/fulgora-grid-debounce.json',helpers.table_to_json{
      schema=1,case='fulgora-grid-debounce',status='pass',failure_count=0,assertions=storage.assertions,
      tick=game.tick,factorio_version=script.active_mods.base},false)
  end,
}
for tick,action in pairs(actions) do
  script.on_nth_tick(tick,function(event)
    if event.tick==tick then action() end
    if event.tick>=tick then script.on_nth_tick(tick,nil) end
  end)
end

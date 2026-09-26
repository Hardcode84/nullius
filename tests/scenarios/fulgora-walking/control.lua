-- given: both production android tiers; no equipment, speed modifiers, or supplies.
-- place: clear walking lanes: island -> sediment -> island, one per sediment type.
-- act: walk east across both boundaries using native character movement.
-- run: 239 ticks.
-- expect: every android crosses the sand strip; no building placement bypass.
local assertions=0
local function check(ok,message) assertions=assertions+1; assert(ok,message) end
script.on_nth_tick(1,function()
  if game.tick==0 then return end
  script.on_nth_tick(1,nil)
  local surface=game.planets['nullius-fulgora'].create_surface()
  surface.request_to_generate_chunks({0,0},4)
  surface.force_generate_chunk_requests()
  for _,entity in pairs(surface.find_entities_filtered{area={{-32,-16},{96,112}}}) do entity.destroy() end
  local sand={}
  for name in pairs(prototypes.tile) do
    if name:find('nullius-fulgora-sediment',1,true)==1 then sand[#sand+1]=name end
  end
  table.sort(sand)
  storage.walkers={}
  local lane=0
  for _,tile in ipairs(sand) do
    for _,name in ipairs({'character','nullius-android-2'}) do
      local y=lane*12
      lane=lane+1
      local tiles={}
      for x=-24,80 do for dy=-4,4 do
        tiles[#tiles+1]={name=(x>=0 and x<16) and tile or 'fulgoran-rock',position={x,y+dy}}
      end end
      surface.set_tiles(tiles,true)
      local body=surface.create_entity{name=name,position={-4,y},force='player'}
      check(body~=nil,'could not create '..name)
      body.walking_state={walking=true,direction=defines.direction.east}
      storage.walkers[#storage.walkers+1]={body=body,tile=tile}
    end
  end
  storage.assertions=assertions
end)
script.on_nth_tick(240,function()
  if game.tick==0 then return end
  script.on_nth_tick(240,nil)
  assertions=storage.assertions
  for _,row in ipairs(storage.walkers) do
    check(row.body.position.x>18,row.body.name..' could not cross '..row.tile..': x='..row.body.position.x)
    row.body.walking_state={walking=false,direction=defines.direction.east}
  end
  helpers.write_file('factorio-tests/fulgora-walking.json',helpers.table_to_json{
    schema=1,case='fulgora-walking',status='pass',failure_count=0,assertions=assertions,
    tick=game.tick,factorio_version=script.active_mods.base},false)
end)

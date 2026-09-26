-- given: production Fulgora, fixed seed, no collectors, power, or equipment.
-- place: both android tiers and basic buildings on isolated cleared islands.
-- act: direct native strikes; then equal intervals at fixed noon and midnight.
-- run: 120 ticks for direct strikes, 3600 ticks for each ambient sample.
-- expect: real strikes preserve health; both samples have storms, night is busier.
local function check(ok,message)
  storage.assertions=storage.assertions+1
  assert(ok,message)
end
script.on_event(defines.events.on_script_trigger_effect,function(event)
  if not storage.phase then return end
  if event.effect_id=='fulgora-storm-created_effect' then
    storage.counts[storage.phase]=storage.counts[storage.phase]+1
  elseif event.effect_id=='fulgora-storm-strike_effect' and event.target_entity then
    storage.hits[event.target_entity.name]=true
  end
end)
script.on_nth_tick(1,function()
  if game.tick==0 then return end
  script.on_nth_tick(1,nil)
  storage.assertions=0; storage.counts={direct=0,day=0,night=0}; storage.hits={}
  local surface=game.planets['nullius-fulgora'].create_surface()
  storage.surface=surface
  local settings=surface.map_gen_settings; settings.seed=1729; surface.map_gen_settings=settings
  surface.request_to_generate_chunks({0,0},5); surface.force_generate_chunk_requests()
  for _,entity in pairs(surface.find_entities()) do entity.destroy() end
  surface.freeze_daytime=true; surface.daytime=0
  storage.targets={}
  for i,name in ipairs({'character','nullius-android-2','nullius-hydro-plant-1',
    'nullius-crusher-1','small-electric-pole','pipe','wooden-chest'}) do
    local x=(i-4)*32
    local tiles={}
    for dx=-6,6 do for dy=-6,6 do tiles[#tiles+1]={name='fulgoran-rock',position={x+dx,dy}} end end
    surface.set_tiles(tiles,true)
    local entity=assert(surface.create_entity{name=name,position={x,0},force='player'})
    storage.targets[#storage.targets+1]={entity=entity,health=entity.health,name=name}
  end
  storage.phase='direct'
  for _,row in ipairs(storage.targets) do
    surface.execute_lightning{name='nullius-fulgora-lightning',position=row.entity.position}
  end
end)
script.on_nth_tick(120,function()
  if game.tick==0 then return end
  for _,row in ipairs(storage.targets) do
    check(row.entity.valid and row.entity.health==row.health,'strike damaged '..row.name)
  end
  if game.tick==120 then
    for _,row in ipairs(storage.targets) do check(storage.hits[row.name],'no direct strike on '..row.name) end
    storage.phase='day'
  elseif game.tick==3720 then
    check(storage.counts.day>0,'no daytime storms')
    storage.surface.daytime=0.5
    storage.phase='night'
  elseif game.tick==7320 then
    check(storage.counts.night>storage.counts.day*2,'night storms not substantially stronger')
    check(storage.surface.count_entities_filtered{type='fire'}==0,'lightning started a fire')
    helpers.write_file('factorio-tests/fulgora-storms.json',helpers.table_to_json{
      schema=1,case='fulgora-storms',status='pass',failure_count=0,
      assertions=storage.assertions,tick=game.tick,factorio_version=script.active_mods.base,
      observations={strikes=storage.counts}},false)
    script.on_nth_tick(120,nil)
  end
end)

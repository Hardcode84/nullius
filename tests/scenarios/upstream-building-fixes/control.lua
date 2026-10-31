-- given: construction research off and declared chests on Nauvis and Fulgora.
-- place/act: destroy chests before and after construction research.
-- expect: rebuildable ghosts only after research.
local CASE='upstream-building-fixes'
local function check(ok,msg) storage.assertions=storage.assertions+1;assert(ok,msg) end
local function kill(surface,x)
  local chest=assert(surface.create_entity{name='wooden-chest',position={x,0},force='player',raise_built=true})
  check(chest.die('enemy'),'chest did not die')
end
script.on_init(function() storage.assertions=0 end)
script.on_nth_tick(30,function()
  if game.tick==0 then return end
  if game.tick==30 then
    storage.surfaces={game.surfaces.nauvis,game.planets['nullius-fulgora'].create_surface()}
    game.forces.player.technologies['nullius-construction-robot-1'].researched=false
    for _,s in ipairs(storage.surfaces) do
      s.request_to_generate_chunks({0,0},3);s.force_generate_chunk_requests()
      for _,e in pairs(s.find_entities_filtered{area={{-25,-25},{25,25}}}) do e.destroy() end
      local tiles={}
      for x=-24,24 do for y=-24,24 do tiles[#tiles+1]={name='grass-1',position={x,y}} end end
      s.set_tiles(tiles,true)
      kill(s,-10)
    end
  elseif game.tick==60 then
    for _,s in ipairs(storage.surfaces) do check(s.count_entities_filtered{type='entity-ghost',position={-10,0},radius=1}==0,'ghost before research') end
    game.forces.player.technologies['nullius-construction-robot-1'].researched=true
    for _,s in ipairs(storage.surfaces) do kill(s,10) end
  elseif game.tick==90 then
    for _,s in ipairs(storage.surfaces) do
      local ghosts=s.find_entities_filtered{type='entity-ghost',position={10,0},radius=1}
      check(#ghosts==1 and ghosts[1].ghost_name=='wooden-chest','missing death ghost after research')
      local _,revived=ghosts[1].revive{raise_revive=true}
      check(revived and revived.name=='wooden-chest','death ghost cannot be rebuilt')
    end
    helpers.write_file('factorio-tests/'..CASE..'.json',helpers.table_to_json{schema=1,case=CASE,status='pass',
      failure_count=0,assertions=storage.assertions,tick=game.tick,factorio_version=script.active_mods.base},false)
    script.on_nth_tick(30,nil)
  end
end)

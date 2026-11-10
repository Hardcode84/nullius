-- given: oxygenated mission, supplied trees and fish, two husbandry drones.
-- place: a launcher and a habitat on Nauvis.
-- act/run: launch one drone, then another at a separate site; 2400 ticks.
-- expect: both deployments create nests and the second raises evolution.
local CASE='victory-husbandry'
local function flare(y)
  assert(game.surfaces.nauvis.create_entity{name='nullius-husbandry-flare',
    position={128,y},force='player',movement={0,0},height=0,vertical_speed=0,frame_speed=1})
end
script.on_init(function()
  local s=game.surfaces.nauvis
  s.request_to_generate_chunks({96,0},4);s.force_generate_chunk_requests()
  for _,e in pairs(s.find_entities_filtered{area={{-16,-80},{210,80}}}) do e.destroy() end
  local tiles={}
  for x=-16,210 do for y=-80,80 do
    tiles[#tiles+1]={name=(x>=150 and x<=175 and y>=-15 and y<=15) and 'water' or 'grass-1',position={x,y}}
  end end
  s.set_tiles(tiles)
  for x=90,120,3 do for y=-24,24,3 do
    assert(s.create_entity{name='tree-01',position={x,y}})
  end end
  for x=152,172,2 do for y=-12,12,2 do
    assert(s.create_entity{name='fish',position={x,y}})
  end end
  remote.call('nullius-test-mission','create',game.forces.player)
  remote.call('nullius-test-mission','set_goal',2,125,game.forces.player)
  storage.launcher=assert(s.create_entity{name='nullius-drone-launcher-1',position={0,0},force='player'})
  assert(storage.launcher.insert{name='nullius-husbandry-drone',count=1}==1)
  flare(-8)
end)
script.on_nth_tick(1200,function(event)
  if event.tick==0 then return end
  local s=game.surfaces.nauvis
  local nests=s.count_entities_filtered{name='biter-spawner'}
  if event.tick==1200 then
    assert(nests==1,'first deployment must create a nest')
    assert(storage.launcher.insert{name='nullius-husbandry-drone',count=1}==1)
    flare(24)
  else
    assert(nests==2,'second deployment must create a nest')
    assert(game.forces.enemy.get_evolution_factor(s)>0,'second deployment must raise evolution')
    helpers.write_file('factorio-tests/'..CASE..'.json',helpers.table_to_json{
      schema=1,case=CASE,status='pass',failure_count=0,assertions=3,tick=event.tick,
      factorio_version=script.active_mods.base},false)
    script.on_nth_tick(1200,nil)
  end
end)

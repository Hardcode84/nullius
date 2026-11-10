-- given: oxygenated mission, supplied trees and fish, two husbandry drones.
-- place: a launcher and a habitat on Nauvis.
-- act: a player targets the husbandry remote at one site, then at another.
-- run: 1200 ticks after each order.
-- expect: both deployments create nests and the second raises evolution.
local CASE='victory-husbandry'
local REMOTE='nullius-husbandry-remote'
local DRONE='nullius-husbandry-drone'

local function check(ok,message)
  storage.assertions=storage.assertions+1
  if not ok then storage.failures[#storage.failures+1]=message end
end

local function finish(tick)
  local failed=#storage.failures>0
  helpers.write_file('factorio-tests/'..CASE..'.json',helpers.table_to_json{
    schema=1,case=CASE,status=failed and 'fail' or 'pass',failure_count=#storage.failures,
    failures=storage.failures,assertions=storage.assertions,tick=tick,
    factorio_version=script.active_mods.base},false)
  script.on_nth_tick(30,nil)
  if failed then error(helpers.table_to_json(storage.failures)) end
end

-- Order a drone the way a player does: load the launcher and use the remote.
local function order(player,y)
  check(storage.launcher.insert{name=DRONE,count=1}==1,'launcher accepts a husbandry drone')
  player.cursor_stack.set_stack{name=REMOTE,count=1}
  player.use_from_cursor({128,y})
  check(player.surface.count_entities_filtered{name='nullius-husbandry-flare'}==1,
    'husbandry remote marks a target at '..y)
end

local function prepare(player)
  local s=game.surfaces.nauvis
  s.request_to_generate_chunks({96,0},4);s.force_generate_chunk_requests()
  for _,e in pairs(s.find_entities_filtered{area={{-16,-80},{210,80}}}) do
    if e.type~='character' then e.destroy() end
  end
  local tiles={}
  for x=-16,210 do for y=-80,80 do
    tiles[#tiles+1]={name=(x>=150 and x<=175 and y>=-15 and y<=15) and 'water' or 'grass-1',position={x,y}}
  end end
  s.set_tiles(tiles)
  for x=90,120,3 do for y=-24,24,3 do
    check(s.create_entity{name='tree-01',position={x,y}}~=nil,'habitat tree')
  end end
  for x=152,172,2 do for y=-12,12,2 do
    check(s.create_entity{name='fish',position={x,y}}~=nil,'habitat fish')
  end end
  remote.call('nullius-test-mission','create',player.force)
  remote.call('nullius-test-mission','set_goal',2,125,player.force)
  player.set_controller{type=defines.controllers.god}
  player.teleport({0,0},s)
  player.force.chart(s,{{-32,-96},{224,96}})
  storage.launcher=s.create_entity{name='nullius-drone-launcher-1',position={0,0},force=player.force}
  check(storage.launcher~=nil,'drone launcher placed')
end

script.on_init(function() storage.assertions=0;storage.failures={} end)

script.on_nth_tick(30,function(event)
  if event.tick==0 then return end
  local player=game.get_player('nullius-test-a')
  if not player or not player.connected then return end
  local s=game.surfaces.nauvis
  if not storage.started then
    storage.started=event.tick
    prepare(player)
    if storage.launcher then order(player,-8) end
  elseif not storage.second and event.tick>=storage.started+1200 then
    storage.second=true
    check(s.count_entities_filtered{name='biter-spawner'}==1,'first deployment must create a nest')
    order(player,24)
  elseif event.tick>=storage.started+2400 then
    check(s.count_entities_filtered{name='biter-spawner'}==2,'second deployment must create a nest')
    check(game.forces.enemy.get_evolution_factor(s)>0,'second deployment must raise evolution')
    finish(event.tick)
  end
end)

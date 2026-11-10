-- given: a mission saved before goals 10 and 11 became stubs, with every
-- other goal complete and the copper and uranium goals unfinished.
-- act: run the configuration-change rebuild.
-- expect: the mission finishes; nothing else would cross 100% to finish it.
local CASE='mission-stub-upgrade'
local REQUIRED={1,2,3,4,5,6,7,8,9,12,13}
local function check(ok,msg) storage.assertions=storage.assertions+1;assert(ok,msg) end
local function mission(name,...) return remote.call('nullius-test-mission',name,...) end
-- Multiplayer, because a single-player victory dialog pauses the simulation.
script.on_nth_tick(30,function(event)
  if event.tick==0 then return end
  local a=game.get_player('nullius-test-a')
  if not a or not a.connected then return end
  script.on_nth_tick(30,nil)
  storage.assertions=0
  local force=a.force
  mission('create',force)
  for _,goal in ipairs(REQUIRED) do mission('seed_count',goal,1e12) end
  mission('seed_count',10,5)
  mission('seed_count',11,3)
  check(not mission('complete'),'seeding finished the mission')
  mission('reload')
  check(mission('complete'),'rebuild left a completed mission open')
  check(mission('overall')==100,'overall progress '..mission('overall'))
  check(game.finished or game.finished_but_continuing,'no victory')
  helpers.write_file('factorio-tests/'..CASE..'.json',helpers.table_to_json{schema=1,case=CASE,status='pass',
    failure_count=0,assertions=storage.assertions,tick=game.tick,factorio_version=script.active_mods.base},false)
end)

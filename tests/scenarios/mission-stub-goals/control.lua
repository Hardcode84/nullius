-- given: one client and a fresh mission.
-- act: complete every required goal except the probe, then the probe.
-- expect: goals 10 and 11 never appear in the panel or overall progress; the
-- probe completes the mission and removes the panel.
local CASE='mission-stub-goals'
local REQUIRED={1,2,3,4,5,6,7,8,9,12,13}
local function check(ok,msg) storage.assertions=storage.assertions+1;assert(ok,msg) end
local function mission(name,...) return remote.call('nullius-test-mission',name,...) end
script.on_init(function() storage.assertions=0;storage.stage='start' end)
script.on_nth_tick(30,function(event)
  if event.tick==0 then return end
  local a=game.get_player('nullius-test-a')
  if not a or not a.connected then return end
  if storage.stage=='start' then
    mission('create',a.force)
    local labels=a.gui.left.nullius_mission_panel.table
    check(labels.mission_probe and labels.mission_coal,'required goal missing from the panel')
    check(not labels.mission_copper and not labels.mission_uranium,'stub goal shown')
    -- Counts above the target reach the 400% cap.
    for _,goal in ipairs(REQUIRED) do
      if goal~=1 then mission('set_goal',goal,1e12,a.force) end
    end
    check(not mission('complete'),'finished without the probe')
    -- Eleven of twelve shares: ten goals plus oxygen's second share; the probe is at zero.
    check(mission('overall')==91.66,'overall progress '..mission('overall'))
    mission('set_goal',1,10,a.force)
    check(mission('complete'),'last required goal did not finish the mission')
    check(mission('overall')==100,'final overall progress '..mission('overall'))
    check(game.finished or game.finished_but_continuing,'no victory')
    check(not a.gui.left.nullius_mission_panel,'panel left after victory')
    storage.stage='finish'
  elseif storage.stage=='finish' then
    helpers.write_file('factorio-tests/'..CASE..'.json',helpers.table_to_json{schema=1,case=CASE,status='pass',
      failure_count=0,assertions=storage.assertions,tick=game.tick,factorio_version=script.active_mods.base},false)
    script.on_nth_tick(30,nil)
  end
end)

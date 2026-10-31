-- given: two real clients, old biology research unlocked, ecology research locked.
-- act: unlock each ecology remote; update mission progress while a client is offline.
-- expect: correct remote gates; offline GUI unchanged, current progress on rejoin.
-- place: hot and cold heat pipes of both tiers; capture their nighttime appearance.
local CASE='upstream-interface-fixes'
local remotes={{'algae',1,'biology-2'},{'grass',2,'botany-1'},{'tree',4,'botany-2'},
 {'worm',3,'zoology-1'},{'fish',5,'zoology-2'},{'arthropod',6,'zoology-3'}}
local function check(ok,msg) storage.assertions=storage.assertions+1;assert(ok,msg) end
local function action(kind)
  storage.action=(storage.action or 0)+1
  helpers.write_file('factorio-tests/multiplayer-action.json',helpers.table_to_json{id=storage.action,action=kind,player='nullius-test-b'},false)
end
local function progress(player) return tonumber(player.gui.left.nullius_mission_panel.table.mission_probe.caption[4]) end
local function buttons(player)
  remote.call('nullius-test-drone-remotes','open',{player_index=player.index})
  local frame=player.gui.center['nullius-remote-gui-window'];local found={}
  for _,flow in pairs(frame.children) do for _,button in pairs(flow.children) do found[button.name]=true end end
  frame.destroy();return found
end
script.on_init(function() storage.assertions=0;storage.stage='start' end)
script.on_nth_tick(30,function()
  if game.tick==0 then return end
  local a=game.get_player('nullius-test-a');local b=game.get_player('nullius-test-b')
  if not a or not a.connected then return end
  if storage.stage=='start' then action('join');storage.stage='both'
  elseif storage.stage=='both' and b and b.connected then
    for _,r in ipairs(remotes) do
      a.force.technologies['nullius-ecology-'..r[2]].researched=false
      a.force.technologies['nullius-'..r[3]].researched=true
    end
    local before=buttons(a)
    for _,r in ipairs(remotes) do check(not before['nullius-make-remote-nullius-'..r[1]],'remote enabled by old research') end
    for _,r in ipairs(remotes) do
      a.force.technologies['nullius-ecology-'..r[2]].researched=true
      local available=buttons(a)
      check(available['nullius-make-remote-nullius-'..r[1]],'ecology research did not enable remote')
    end
    remote.call('nullius-test-mission','create',a.force)
    remote.call('nullius-test-mission','set_goal',1,1,a.force)
    check(progress(a)==10 and progress(b)==10,'initial mission progress')
    storage.offline_panel=b.gui.left.nullius_mission_panel
    action('leave');storage.stage='offline'
  elseif storage.stage=='offline' and not b.connected then
    remote.call('nullius-test-mission','set_goal',1,5,a.force)
    check(progress(a)==50,'connected mission update')
    check(storage.offline_panel.valid and progress(b)==10,'offline mission GUI was rebuilt')
    action('join');storage.stage='rejoin'
  elseif storage.stage=='rejoin' and b.connected then
    check(progress(b)==50 and not storage.offline_panel.valid,'mission stale on rejoin')
    local s=a.surface
    a.set_controller{type=defines.controllers.god};a.teleport({0,0})
    s.request_to_generate_chunks({0,0},1);s.force_generate_chunk_requests()
    for _,e in pairs(s.find_entities_filtered{area={{-12,-10},{12,10}}}) do if e.type~='character' then e.destroy() end end
    local tiles={};for x=-12,12 do for y=-10,10 do tiles[#tiles+1]={name='grass-1',position={x,y}} end end
    s.set_tiles(tiles,true);s.freeze_daytime=true;s.daytime=.5
    for tier=1,2 do for hot=0,1 do for x=-4,4 do
      local e=assert(s.create_entity{name='nullius-heat-pipe-'..tier,position={x,-6+tier*4+hot*2},force='player'})
      e.temperature=hot==1 and 900 or 15
    end end end
    storage.stage='capture'
  elseif storage.stage=='capture' then
    game.take_screenshot{player=a,by_player=a,surface=a.surface,position={0,1},resolution={1000,700},zoom=2,
      show_gui=false,force_render=true,path=CASE..'/heat-pipes.png'}
    storage.stage='finish'
  elseif storage.stage=='finish' then
    helpers.write_file('factorio-tests/'..CASE..'.json',helpers.table_to_json{schema=1,case=CASE,status='pass',
      failure_count=0,assertions=storage.assertions,tick=game.tick,factorio_version=script.active_mods.base},false)
    script.on_nth_tick(30,nil)
  end
end)

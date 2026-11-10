-- given: loaded launchers, all restricted remotes, and declared oxygen flows.
-- place: identical clear ground on Nauvis, Vulcanus and Fulgora.
-- act: use each remote; fire coal and petroleum drones on Nauvis.
-- Supply off-world flares to check impacts from previously ordered drones.
-- expect: off-world use creates no targets, off-world impacts explain themselves,
-- and only Nauvis oxygen counts.
local CASE='drone-surface-restrictions'
local remotes={'terraforming-remote-grey','paving-remote-grey','excavation-remote',
  'shallow-excavation-remote','algaculture-remote','horticulture-remote',
  'arboriculture-remote','entomology-remote','aquaculture-remote','husbandry-remote',
  'sequestration-coal-remote','sequestration-petroleum-remote'}
local function mission(name,...) return remote.call('nullius-test-mission',name,...) end
local function check(ok,msg) storage.assertions=storage.assertions+1;assert(ok,msg) end
script.on_init(function() storage.assertions=0;storage.blocked={};storage.notices={} end)
script.on_nth_tick(30,function(event)
  if event.tick==0 then return end
  local p=game.get_player('nullius-test-a')
  if not p or not p.connected then return end
  -- Impact notices expire, so record them while polling.
  for _,object in pairs(rendering.get_all_objects('nullius-star')) do
    if object.type=='text' then storage.notices[object.surface.name]=true end
  end
  if not storage.started then
    storage.started=game.tick
    mission('create',p.force)
    p.set_controller{type=defines.controllers.god}
    for _,name in ipairs{'nullius-fulgora','nullius-vulcanus','nauvis'} do
      local s=game.surfaces[name] or game.planets[name].create_surface()
      s.request_to_generate_chunks({64,0},3);s.force_generate_chunk_requests()
      for _,e in pairs(s.find_entities_filtered{area={{-10,-40},{180,40}}}) do e.destroy() end
      local tiles={}
      for x=-10,180 do for y=-40,40 do tiles[#tiles+1]={name='grass-1',position={x,y}} end end
      s.set_tiles(tiles)
      p.force.chart(s,{{-32,-64},{224,64}})
      p.teleport({0,0},s)
      local target_launcher=assert(s.create_entity{name='nullius-drone-launcher-1',position={0,0},force=p.force})
      for _,remote in ipairs(remotes) do
        target_launcher.clear_items_inside()
        assert(target_launcher.insert{name='nullius-'..string.gsub(remote,'remote','drone'),count=1}==1)
        p.cursor_stack.set_stack{name='nullius-'..remote,count=1}
        p.use_from_cursor({128,0})
        local flares=s.find_entities_filtered{type='artillery-flare'}
        check(#flares==(name=='nauvis' and 1 or 0),name..' '..remote..' target restriction: '..#flares)
        for _,e in pairs(flares) do e.destroy() end
      end
      target_launcher.destroy()
      if name~='nauvis' then
        p.force.get_fluid_production_statistics(s).on_flow('nullius-oxygen',2560000)
      end
      if name=='nauvis' then
        for i,kind in ipairs{'coal','petroleum'} do
          local y=(i-1)*32-16
          local launcher=assert(s.create_entity{name='nullius-drone-launcher-1',position={0,y},force=p.force})
          assert(launcher.insert{name='nullius-sequestration-'..kind..'-drone',count=1}==1)
          p.cursor_stack.set_stack{name='nullius-sequestration-'..kind..'-remote',count=1}
          p.use_from_cursor({128,y})
        end
      else
        -- Supplied targets represent drones already ordered before the restriction.
        for i,kind in ipairs{'coal','petroleum'} do
          local y=(i-1)*32-16
          local launcher=assert(s.create_entity{name='nullius-drone-launcher-1',position={0,y},force=p.force})
          local ammo='nullius-sequestration-'..kind..'-drone'
          assert(launcher.insert{name=ammo,count=1}==1)
          assert(s.create_entity{name='nullius-sequestration-'..kind..'-flare',position={128,y},
            force=p.force,movement={0,0},height=0,vertical_speed=0,frame_speed=1})
          storage.blocked[#storage.blocked+1]={launcher=launcher,ammo=ammo}
        end
      end
    end
  elseif not storage.nauvis_flow then
    mission('update_oxygen')
    check(mission('count',2)==0,'off-world oxygen excluded after statistics update')
    p.force.get_fluid_production_statistics('nauvis').on_flow('nullius-oxygen',2560000)
    storage.nauvis_flow=true
  elseif not storage.oxygen_checked then
    mission('update_oxygen')
    check(math.abs(mission('count',2)-1)<0.000001,'Nauvis oxygen attribution: '..mission('count',2))
    storage.oxygen_checked=true
  elseif game.tick>=storage.started+1200 then
    for _,row in ipairs(storage.blocked) do
      check(row.launcher.get_item_count(row.ammo)==0,'supplied off-world target reached impact')
      check(row.launcher.surface.count_entities_filtered{name={'coal','crude-oil'}}==0,
        'off-world impact must not create deposits')
      check(storage.notices[row.launcher.surface.name],'off-world impact must tell the player why it had no effect')
    end
    check(mission('count',12)>0,'Nauvis coal credited')
    check(mission('count',13)>0,'Nauvis petroleum credited')
    helpers.write_file('factorio-tests/'..CASE..'.json',helpers.table_to_json{
      schema=1,case=CASE,status='pass',failure_count=0,assertions=storage.assertions,
      tick=game.tick,factorio_version=script.active_mods.base},false)
    script.on_nth_tick(30,nil)
  end
end)

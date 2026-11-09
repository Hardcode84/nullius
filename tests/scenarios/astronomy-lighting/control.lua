-- given: astronomy research, 50 blank modules or Nauvis recordings per supplied machine, 50 hydrogen
-- per dish, 1000 compressed volcanic gas per fueled dish, and debug electric sources.
-- place: each astronomy machine in working, powered-idle, and unpowered rows.
-- act: run real recipes; capture the same layout in daylight and at midnight.
-- expect: only supplied, powered machines craft; idle and unpowered rows stay dark.
local CASE='astronomy-lighting'
local function check(ok,message)
  storage.assertions=(storage.assertions or 0)+1
  assert(ok,message)
end
local function capture(player,state)
  game.take_screenshot{player=player,by_player=player,surface=player.surface,
    position={12,12},resolution={1500,1600},zoom=1.1,show_gui=false,force_render=true,
    path='astronomy-lighting-'..state..'.png'}
end
local function verify()
  for _,entry in ipairs(storage.machines) do
    local entity=entry.entity
    local status=tostring(entity.status)
    for label,value in pairs(defines.entity_status) do if value==entity.status then status=label end end
    check(entity.is_crafting()==(entry.state=='Working'),entry.state..' crafting state: '..entity.name..
      ' status='..status..' energy='..entity.energy..' recipe='..entity.get_recipe().name)
    if not entry.pneumatic then
      check((entity.energy>0)==(entry.state~='Unpowered'),entry.state..' energy state: '..entity.name)
    end
  end
end
local function capture_animation()
  local player=assert(game.get_player('nullius-test-a'))
  verify()
  local ticks=storage.capture_mode=='motion' and storage.motion_ticks or storage.animation_ticks
  local frame=#ticks
  game.take_screenshot{player=player,by_player=player,surface=player.surface,
    position={12,0},resolution={1600,600},zoom=1.5,show_gui=false,force_render=true,
    path=string.format('astronomy-%s/%02d.png',storage.capture_mode,frame)}
  ticks[#ticks+1]=game.tick
  if #ticks==64 then
    script.on_nth_tick(5,nil)
    storage.stage=storage.capture_mode=='glow' and 'day-motion' or 'finish'
  end
end
script.on_nth_tick(30,function()
  if game.tick==0 then return end
  local player=game.get_player('nullius-test-a')
  if not player or not player.connected then return end
  if not storage.stage then
    player.set_controller{type=defines.controllers.god}
    local surface=player.surface
    player.force.technologies['nullius-astronomy'].researched=true
    surface.request_to_generate_chunks({12,12},2);surface.force_generate_chunk_requests()
    for _,entity in pairs(surface.find_entities_filtered{area={{-10,-10},{35,35}}}) do entity.destroy() end
    local tiles={}
    for x=-10,35 do for y=-10,35 do tiles[#tiles+1]={name='refined-concrete',position={x,y}} end end
    surface.set_tiles(tiles);surface.daytime=0;surface.freeze_daytime=true
    storage.machines={}
    for row,state in ipairs({'Working','Idle','Unpowered'}) do
      for column,name in ipairs({'nullius-radio-dish','nullius-radio-dish-pneumatic','nullius-correlator'}) do
        local x,y=(column-1)*12,(row-1)*12
        local entity=assert(surface.create_entity{name=name,position={x,y},force='player'})
        check(entity.prototype.tile_width==5 and entity.prototype.tile_height==5,'five-tile footprint: '..name)
        local dish=column<3
        entity.set_recipe(dish and 'nullius-nauvis-interferometric-recording' or 'nullius-correlate-nauvis')
        if state~='Idle' then
          local ingredient=dish and 'nullius-blank-recording-module' or 'nullius-nauvis-interferometric-recording'
          check(entity.insert{name=ingredient,count=50}==50,'item input insertion: '..name)
        end
        if dish then
          local feed=assert(surface.create_entity{name='pipe',position={x-1,y-3},force='player'})
          check(feed.insert_fluid{name='nullius-hydrogen',amount=50}==50,'hydrogen feed insertion: '..name)
        end
        if column==2 and state~='Unpowered' then
          check(entity.insert_fluid{name='nullius-compressed-volcanic-gas',amount=1000}==1000,'fuel insertion')
        elseif column~=2 and state~='Unpowered' then
          assert(surface.create_entity{name='small-electric-pole',position={x+3,y+1},force='player'})
          local power=assert(surface.create_entity{name='electric-energy-interface',position={x+5,y+2},force='player'})
          power.electric_buffer_size=100000000
          power.power_production=10000000
          power.energy=100000000
        end
        storage.machines[#storage.machines+1]={entity=entity,state=state,pneumatic=column==2}
        rendering.draw_text{text=state,surface=surface,target={x,y+4},color={1,1,1},alignment='center',scale=1.3}
      end
    end
    player.teleport({12,12})
    storage.stage='settle';storage.ready_tick=game.tick+90
  elseif storage.stage=='settle' and game.tick>=storage.ready_tick then
    verify();capture(player,'day');storage.stage='night'
  elseif storage.stage=='night' then
    player.surface.daytime=0.5;storage.stage='night-settle'
  elseif storage.stage=='night-settle' then
    verify();capture(player,'night');storage.stage='pulse';storage.pulse_tick=game.tick+60
  elseif storage.stage=='pulse' and game.tick>=storage.pulse_tick then
    verify();capture(player,'night-pulse');storage.stage='animation'
    storage.capture_mode='glow';storage.animation_ticks={};script.on_nth_tick(5,capture_animation)
  elseif storage.stage=='day-motion' then
    player.surface.daytime=0;storage.stage='day-motion-settle'
  elseif storage.stage=='day-motion-settle' then
    verify();capture(player,'motion-start');storage.stage='animation'
    storage.capture_mode='motion';storage.motion_ticks={};script.on_nth_tick(5,capture_animation)
  elseif storage.stage=='finish' then
    verify();capture(player,'motion-end')
    local machines={}
    for _,entry in ipairs(storage.machines) do
      machines[#machines+1]={name=entry.entity.name,state=entry.state,position=entry.entity.position}
    end
    helpers.write_file('factorio-tests/'..CASE..'.json',helpers.table_to_json{
      schema=1,case=CASE,status='pass',failure_count=0,assertions=storage.assertions,
      tick=game.tick,factorio_version=script.active_mods.base,machines=machines,
      camera={x=12,y=12},zoom=1.1,animation_ticks=storage.animation_ticks,
      motion_ticks=storage.motion_ticks,animation_camera={x=12,y=0},animation_zoom=1.5},false)
    script.on_nth_tick(30,nil)
  end
end)

-- given: production astronomy machines, native pipe fittings, ten fuel units per dish.
-- place: both dishes in all cardinal directions beside native fitting references.
-- connect: hydrogen above; fuel west-to-east; rotate all ports with the body.
-- act: capture capped ports, connect pipes, and capture connected ports.
-- expect: each pipe connects to its building; fuel crosses between both side ports.
local CASE='astronomy-connectors'
local astronomy=require('__nullius-star__/shared/astronomy')
local directions={defines.direction.north,defines.direction.east,defines.direction.south,defines.direction.west}
local names={'North','East','South','West'}
local function check(ok,message)
  storage.assertions=(storage.assertions or 0)+1;assert(ok,message)
end
local function rotate(x,y,turns)
  for _=1,turns do x,y=-y,x end
  return x,y
end
local function capture(player,state)
  game.take_screenshot{player=player,by_player=player,surface=player.surface,position={14,7},
    resolution={1600,1400},zoom=1.3,show_gui=false,force_render=true,path='astronomy-connectors-'..state..'.png'}
end
script.on_nth_tick(30,function()
  if game.tick==0 then return end
  local player=game.get_player('nullius-test-a')
  if not player or not player.connected then return end
  if not storage.stage then
    player.set_controller{type=defines.controllers.god}
    local surface=player.surface
    surface.request_to_generate_chunks({14,7},2);surface.force_generate_chunk_requests()
    for _,entity in pairs(surface.find_entities_filtered{area={{-8,-8},{36,25}}}) do entity.destroy() end
    local tiles={}
    for x=-8,36 do for y=-8,25 do tiles[#tiles+1]={name='refined-concrete',position={x,y}} end end
    surface.set_tiles(tiles);surface.daytime=0;surface.freeze_daytime=true
    storage.rows={}
    storage.port_positions={}
    for row,name in ipairs({'nullius-radio-dish','nullius-radio-dish-pneumatic'}) do
      for column,direction in ipairs(directions) do
        local x,y=(column-1)*9+0.5,(row-1)*9+0.5
        local entity=assert(surface.create_entity{name=name,position={x,y},direction=direction,force='player'})
        entity.set_recipe(astronomy.recording('nauvis'))
        check(entity.direction==direction,'body orientation changed')
        storage.rows[#storage.rows+1]={entity=entity,turns=column-1,pneumatic=row==2}
        rendering.draw_text{text=names[column],surface=surface,
          target={x,y+4},color={1,1,1},alignment='center',scale=1.3}
      end
    end
    assert(surface.create_entity{name='nullius-hydro-plant-1',position={9.5,18.5},force='player'})
    rendering.draw_text{text='Hydro plant',surface=surface,target={9.5,22},color={1,1,1},alignment='center',scale=1.3}
    player.teleport({14,7});storage.stage='capped'
  elseif storage.stage=='capped' then
    capture(player,'capped');storage.stage='connect'
  elseif storage.stage=='connect' then
    for _,row in ipairs(storage.rows) do
      local entity=row.entity
      local offsets=row.pneumatic and {{-1,-3},{-3,0},{3,0}} or {{-1,-3}}
      local pipes={}
      for index,offset in ipairs(offsets) do
        local dx,dy=rotate(offset[1],offset[2],row.turns)
        local pos={entity.position.x+dx,entity.position.y+dy}
        check(entity.surface.can_place_entity{name='pipe',position=pos,force='player'},'pipe site blocked')
        local pipe=assert(entity.surface.create_entity{name='pipe',position=pos,force='player'})
        local connected=false
        for _,connection in pairs(pipe.get_fluid_box_pipe_connections(1)) do
          if connection.target==entity then
            connected=true
            local target=entity.get_fluid_box_pipe_connections(connection.target_fluidbox_index)[connection.target_pipe_connection_index]
            storage.port_positions[#storage.port_positions+1]={
              entity=entity.name,direction=names[row.turns+1],port=index,
              pipe={x=pipe.position.x-entity.position.x,y=pipe.position.y-entity.position.y},
              connection={x=target.position.x-entity.position.x,y=target.position.y-entity.position.y},
              target={x=target.target_position.x-entity.position.x,y=target.target_position.y-entity.position.y}}
            check(pipe.position.x==pos[1] and pipe.position.y==pos[2],'pipe centre shifted')
            local port_offset=({{-1,-2},{-2,0},{2,0}})[index]
            local px,py=rotate(port_offset[1],port_offset[2],row.turns)
            check(target.position.x==entity.position.x+px and target.position.y==entity.position.y+py,
              'machine port shifted from expected centreline')
            check(target.target_position.x==pipe.position.x and target.target_position.y==pipe.position.y,
              'connection target differs from pipe centre')
          end
        end
        check(connected,'native pipe is not connected to dish')
        pipes[index]=pipe
        if index==1 then
          local ex,ey=rotate(-1,-4,row.turns)
          assert(entity.surface.create_entity{name='pipe',
            position={entity.position.x+ex,entity.position.y+ey},force='player'})
        end
      end
      if row.pneumatic then
        check(pipes[2].insert_fluid{name='nullius-compressed-volcanic-gas',amount=10}==10,'fuel insertion')
        local fluid=pipes[3].get_fluid_segment_fluid(1)
        check(fluid and fluid.name=='nullius-compressed-volcanic-gas' and fluid.amount==10,
          'fuel does not pass through the machine')
      end
    end
    storage.stage='connected'
  elseif storage.stage=='connected' then
    capture(player,'connected');storage.stage='guides'
  elseif storage.stage=='guides' then
    for _,row in ipairs(storage.rows) do
      if row.pneumatic then
        local x,y=row.entity.position.x,row.entity.position.y
        local dx,dy=rotate(4,0,row.turns)
        rendering.draw_line{surface=row.entity.surface,from={x-dx,y-dy},to={x+dx,y+dy},
          color={0,1,1},width=1,draw_on_ground=false}
        rendering.draw_circle{surface=row.entity.surface,target={x,y},radius=0.1,
          color={0,1,1},width=1,draw_on_ground=false}
      end
    end
    storage.stage='capture-guides'
  elseif storage.stage=='capture-guides' then
    capture(player,'centres');storage.stage='finish'
  elseif storage.stage=='finish' then
    helpers.write_file('factorio-tests/'..CASE..'.json',helpers.table_to_json{
      schema=1,case=CASE,status='pass',failure_count=0,assertions=storage.assertions,
      tick=game.tick,factorio_version=script.active_mods.base,port_positions=storage.port_positions},false)
    script.on_nth_tick(30,nil)
  end
end)

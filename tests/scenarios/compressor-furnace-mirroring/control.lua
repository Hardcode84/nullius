-- given: all compressor and large-furnace variants; no power or ingredients
-- place: all cardinal directions, unmirrored and flipped on each axis
-- connect: pipes at independently reflected input and output positions
-- act: switch priority or thermal mode; copy mirrored ghosts
-- run: check connections after 30 ticks and capture the production graphics
-- expect: both ports connect, mode changes retain the layout, and no render errors
require("__nullius-star__/scripts/mirror")
local CASE="compressor-furnace-mirroring"
local function check(ok,message)
  storage.assertions=storage.assertions+1
  assert(ok,message)
end
local function ports(entity,pipes)
  for index,pipe in ipairs(pipes) do
    local connection=entity.get_fluid_box_pipe_connections(index)[1]
    check(connection.target==pipe,
      entity.name.." port "..index.." direction="..entity.direction.." mirror="..tostring(entity.mirroring)..
      " expected="..helpers.table_to_json(pipe.position).." actual="..helpers.table_to_json(connection))
  end
end
script.on_init(function() storage.assertions=0 end)
script.on_event(defines.events.on_player_joined_game,function(event)
  local player=game.get_player(event.player_index)
  local surface=player.surface
  player.set_controller{type=defines.controllers.god}
  surface.request_to_generate_chunks({45,36},4);surface.force_generate_chunk_requests()
  for _,entity in pairs(surface.find_entities_filtered{area={{-8,-8},{100,80}}}) do entity.destroy() end
  local tiles={}
  for x=-8,100 do for y=-8,80 do tiles[#tiles+1]={name="grass-1",position={x,y}} end end
  surface.set_tiles(tiles);surface.freeze_daytime=true;surface.daytime=0
  local specs={}
  for tier=1,3 do for _,mode in ipairs({"surge","priority"}) do
    specs[#specs+1]={name="nullius-"..mode.."-compressor-"..tier,
      replacement="nullius-"..(mode=="surge" and "priority" or "surge").."-compressor-"..tier,
      offsets={{2.5,1.5},{-2.5,-1.5}}}
  end end
  for tier=1,2 do for _,suffix in ipairs({"","-thermal"}) do
    specs[#specs+1]={name="nullius-large-furnace-"..tier..suffix,
      replacement="nullius-large-furnace-"..tier..(suffix=="" and "-thermal" or ""),
      offsets={{0.5,2.5},{-0.5,-2.5}}}
  end end
  storage.rows={}
  for row,spec in ipairs(specs) do
    for d,direction in ipairs({0,4,8,12}) do for flip=0,2 do
      local position={((d-1)*3+flip)*8,(row-1)*8}
      local entity=assert(surface.create_entity{name=spec.name,position=position,direction=direction,force="player"})
      if row>6 then
        entity.set_recipe("nullius-boxed-graphite")
        check(entity.get_recipe().name=="nullius-boxed-graphite",spec.name.." fluid recipe")
        entity.direction=direction
      end
      check(entity.direction==direction,spec.name.." base direction")
      check(entity.prototype.use_mirroring,spec.name.." allows mirroring")
      if flip>0 then
        check(entity.flip{horizontal=flip==1},spec.name.." flip")
        check(entity.mirroring,spec.name.." mirrored")
      end
      local pipes={}
      for index,offset in ipairs(spec.offsets) do
        local x,y=offset[1],offset[2]
        for _=1,direction/4 do x,y=-y,x end
        if flip==1 then x=-x elseif flip==2 then y=-y end
        pipes[index]=assert(surface.create_entity{name="pipe",position={position[1]+x,position[2]+y},force="player"})
      end
      ports(entity,pipes)
      local orientation,mirrored=entity.direction,entity.mirroring
      entity=assert(replace_fluid_entity(entity,spec.replacement,entity.force))
      check(entity.direction==orientation and entity.mirroring==mirrored,spec.name.." replacement orientation")
      ports(entity,pipes)
      entity=assert(replace_fluid_entity(entity,spec.name,entity.force))
      storage.rows[#storage.rows+1]={entity=entity,pipes=pipes}
      local ghost=assert(surface.create_entity{name="entity-ghost",inner_name=spec.name,
        position={110,0},direction=orientation,mirror=mirrored,force="player"})
      if row>6 then ghost.set_recipe("nullius-boxed-graphite");ghost.direction=orientation end
      ghost=assert(replace_fluid_entity(ghost,spec.replacement,ghost.force))
      check(ghost.direction==orientation and ghost.mirroring==mirrored,spec.name.." ghost orientation")
      ghost.destroy()
    end end
  end
  player.teleport({44,32});storage.player=player;storage.stage="capture"
end)
script.on_nth_tick(30,function()
  if storage.stage=="capture" then
    for _,row in ipairs(storage.rows) do ports(row.entity,row.pipes) end
    for panel=1,3 do
      game.take_screenshot{player=storage.player,by_player=storage.player,surface=storage.player.surface,
        position={44,(panel-1)*32+12},resolution={2000,800},zoom=.65,show_gui=false,
        force_render=true,path=CASE.."/panel-"..panel..".png"}
    end
    storage.stage="finish"
  elseif storage.stage=="finish" then
    helpers.write_file("factorio-tests/"..CASE..".json",helpers.table_to_json{
      schema=1,case=CASE,status="pass",assertions=storage.assertions,tick=game.tick,
      factorio_version=script.active_mods.base,failure_count=0},false)
    storage.stage="done"
  end
end)

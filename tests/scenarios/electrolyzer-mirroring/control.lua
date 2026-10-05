-- given: all six production electrolyzers, no power or ingredients
-- place: each tier and power mode in all cardinal directions
-- connect: pipes at each reflected port
-- act: flip on either axis, then change power mode
-- run: one tick
-- expect: reflected ports connect; mode changes preserve the mirrored layout
require("__nullius-star__/scripts/mirror")
local count=0
local function check(ok,message)
  count=count+1
  assert(ok,message)
end
script.on_nth_tick(1,function()
  if game.tick==0 then return end
  script.on_nth_tick(1,nil)
  local surface=game.create_surface("electrolyzer-mirroring",{width=64,height=64})
  surface.request_to_generate_chunks({0,0},1)
  surface.force_generate_chunk_requests()
  for _,e in pairs(surface.find_entities()) do e.destroy() end
  local offsets={{-1.5,-2.5},{-1.5,2.5},{1.5,-2.5},{1.5,2.5}}
  for tier=1,3 do
    for _,mode in ipairs({"surge","priority"}) do
      local name="nullius-"..mode.."-electrolyzer-"..tier
      for _,direction in ipairs({0,4,8,12}) do
        for _,horizontal in ipairs({true,false}) do
          local entity=assert(surface.create_entity{name=name,position={0,0},
            direction=direction,force="player"})
          check(entity.flip{horizontal=horizontal},name.." flip")
          check(entity.mirroring,name.." mirrored")
          local pipes={}
          for index,offset in ipairs(offsets) do
            local x,y=offset[1],offset[2]
            for _=1,direction/4 do x,y=-y,x end
            if horizontal then x=-x else y=-y end
            local pipe=assert(surface.create_entity{name="pipe",position={x,y},force="player"})
            pipes[index]=pipe
            check(entity.get_fluid_box_pipe_connections(index)[1].target==pipe,
              name.." reflected port "..index)
          end
          local replacement="nullius-"..(mode=="surge" and "priority" or "surge").."-electrolyzer-"..tier
          local orientation=entity.direction
          entity=assert(replace_fluid_entity(entity,replacement,entity.force))
          check(entity.mirroring and entity.direction==orientation,name.." mode preserves flip")
          for index,pipe in ipairs(pipes) do
            check(entity.get_fluid_box_pipe_connections(index)[1].target==pipe,
              name.." mode preserves port "..index)
            pipe.destroy()
          end
          entity.destroy()
          local ghost=assert(surface.create_entity{name="entity-ghost",inner_name=name,
            position={0,0},direction=orientation,mirror=true,force="player"})
          ghost=assert(replace_fluid_entity(ghost,replacement,ghost.force))
          check(ghost.mirroring and ghost.direction==orientation,name.." ghost preserves flip")
          ghost.destroy()
        end
      end
    end
  end
  helpers.write_file("factorio-tests/electrolyzer-mirroring.json",helpers.table_to_json{
    schema=1,case="electrolyzer-mirroring",status="pass",assertions=count,tick=game.tick,
    failure_count=0,failures={}},false)
end)

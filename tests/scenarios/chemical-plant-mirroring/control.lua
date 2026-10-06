-- given: all chemical plant tiers and power modes; no power or ingredients
-- place: each machine in all four cardinal directions
-- connect: pipes at all six reflected recipe connections
-- act: flip on both axes and switch electric/pneumatic modes
-- run: one tick
-- expect: each recipe port stays connected; ghost mode switches retain mirroring
require("__nullius-star__/scripts/mirror")
local count=0
local function check(ok,message)
  count=count+1
  assert(ok,message)
end
local function check_ports(entity,pipes)
  for index=1,entity.fluids_count do
    local prototype=entity.get_fluid_box_prototype(index)
    if not prototype.object_name then prototype=prototype[1] end
    if prototype.production_type~="none" then
      local connections=entity.get_fluid_box_pipe_connections(index)
      for j,pipe in ipairs(pipes[prototype.index]) do
        check(connections[j].target==pipe,entity.name.." reflected port "..prototype.index..":"..j)
      end
    end
  end
end
script.on_nth_tick(1,function()
  if game.tick==0 then return end
  script.on_nth_tick(1,nil)
  local surface=game.create_surface("chemical-plant-mirroring",{width=64,height=64})
  surface.request_to_generate_chunks({0,0},1)
  surface.force_generate_chunk_requests()
  for _,entity in pairs(surface.find_entities()) do entity.destroy() end
  local offsets={{{-1,-2}},{{1,-2}},{{-2,0},{2,0}},{{-1,2}},{{1,2}}}
  for tier=1,3 do
    for _,suffix in ipairs({"","-pneumatic"}) do
      local name="nullius-chemical-plant-"..tier..suffix
      local replacement="nullius-chemical-plant-"..tier..(suffix=="" and "-pneumatic" or "")
      for _,direction in ipairs({0,4,8,12}) do
        for _,horizontal in ipairs({true,false}) do
          local entity=assert(surface.create_entity{name=name,position={0.5,0.5},
            direction=direction,force="player"})
          check(entity.flip{horizontal=horizontal},name.." flip")
          check(entity.mirroring,name.." mirrored")
          local pipes={}
          for index,positions in ipairs(offsets) do
            pipes[index]={}
            for _,offset in ipairs(positions) do
              local x,y=offset[1],offset[2]
              for _=1,direction/4 do x,y=-y,x end
              if horizontal then x=-x else y=-y end
              table.insert(pipes[index],assert(surface.create_entity{name="pipe",
                position={entity.position.x+x,entity.position.y+y},force="player"}))
            end
          end
          check_ports(entity,pipes)
          local orientation=entity.direction
          entity=assert(replace_fluid_entity(entity,replacement,entity.force))
          check(entity.mirroring and entity.direction==orientation,name.." mode preserves flip")
          check_ports(entity,pipes)
          for _,group in ipairs(pipes) do for _,pipe in ipairs(group) do pipe.destroy() end end
          entity.destroy()
          local ghost=assert(surface.create_entity{name="entity-ghost",inner_name=name,
            position={0.5,0.5},direction=orientation,mirror=true,force="player"})
          ghost=assert(replace_fluid_entity(ghost,replacement,ghost.force))
          check(ghost.mirroring and ghost.direction==orientation,name.." ghost preserves flip")
          ghost.destroy()
        end
      end
    end
  end
  helpers.write_file("factorio-tests/chemical-plant-mirroring.json",helpers.table_to_json{
    schema=1,case="chemical-plant-mirroring",status="pass",assertions=count,
    factorio_version=script.active_mods.base,tick=game.tick,failure_count=0,failures={}},false)
end)

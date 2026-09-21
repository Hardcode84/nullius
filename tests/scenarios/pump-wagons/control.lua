-- given: void-powered production pump copies, straight rails, one wagon per case
-- place: two pump tiers in four directions, with separate load/unload cases
-- connect: a pipe at the pump's land-side port
-- act: put 100 water in the source pipe or wagon; run 599 ticks
-- expect: all 100 water in the destination, with an empty source
local fluid_api = require("__nullius-star__/scenarios/fluid-api")
local assertions=0
local function check(ok,message)
  assertions=assertions+1
  assert(ok,message)
end
script.on_nth_tick(1,function()
  script.on_nth_tick(1,nil)
  local surface=game.create_surface("pump-wagons-test",{width=160,height=160,autoplace_controls={}})
  surface.request_to_generate_chunks({0,0},3)
  surface.force_generate_chunk_requests()
  for _,entity in pairs(surface.find_entities()) do entity.destroy() end
  storage.rows={}
  for tier=1,2 do for rotation=0,3 do for mode=0,1 do
    local ox=(rotation-2)*24
    local oy=((tier-1)*2+mode-2)*24
    local function position(x,y)
      for _=1,rotation do x,y=-y,x end
      return {x+ox,y+oy}
    end
    for y=-9,11,2 do
      check(surface.create_entity{name="straight-rail",position=position(1,y),
        direction=rotation*4,force="player"}~=nil,"rail placed")
    end
    local wagon=surface.create_entity{name="fluid-wagon",position=position(1,1),direction=rotation*4,force="player"}
    check(wagon~=nil,"wagon placed")
    wagon.train.manual_mode=true
    local pump=surface.create_entity{name="factorio-test-nullius-pump-" .. tier,
      position=position(3,1.5),direction=(12+rotation*4+mode*8)%16,force="player"}
    check(pump~=nil,"pump placed")
    local pipe=surface.create_entity{name="pipe",position=position(4.5,1.5),force="player"}
    check(pipe~=nil,"pipe placed")
    local source=mode==0 and pipe or wagon
    check(source.insert_fluid{name="water",amount=100}==100,"declared water inserted")
    storage.rows[#storage.rows+1]={wagon=wagon,pipe=pipe,pump=pump,mode=mode,
      label="tier "..tier.." rotation "..rotation.." mode "..mode}
  end end end
  storage.assertions=assertions
end)
script.on_nth_tick(600,function(event)
  if event.tick==0 then return end
  script.on_nth_tick(600,nil)
  assertions=storage.assertions
  for _,row in ipairs(storage.rows) do
    local contents=assert(fluid_api.segment_contents(row.pipe,1),"pipe segment exists")
    local water=contents.water or 0
    local wagon=row.wagon.get_fluid_count("water")
    check(math.abs(wagon-(row.mode==0 and 100 or 0))<0.0001,row.label.." wagon: "..wagon)
    check(math.abs(water-(row.mode==0 and 0 or 100))<0.0001,row.label.." pipe: "..water)
  end
  helpers.write_file("factorio-tests/pump-wagons.json",helpers.table_to_json({
    schema=1,case="pump-wagons",status="pass",factorio_version=script.active_mods.base,
    tick=game.tick,assertions=assertions,cases=#storage.rows,failure_count=0,failures={}
  }),false)
end)

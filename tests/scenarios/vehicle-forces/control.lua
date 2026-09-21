-- given: the five production vehicles and independent reference prototypes
-- place: paired vehicles on separate, empty, grass lanes
-- connect: none
-- act: set speed to 0.5 once, then coast or apply native braking
-- run: sample speed and travelled distance at ticks 1, 5, 15, 30, and 60
-- expect: identical motion to the reference; brakes slow more than coasting
local cases = require("fixture")
local function check(ok,message)
  storage.assertions=storage.assertions+1
  assert(ok,message)
end
script.on_init(function()
  storage.assertions=0
  storage.rows={}
  local surface=game.create_surface("vehicle-forces-test",{width=256,height=128,autoplace_controls={}})
  surface.request_to_generate_chunks({0,0},4)
  surface.force_generate_chunk_requests()
  for _, entity in pairs(surface.find_entities()) do entity.destroy() end
  local tiles={}
  for x=-100,100 do for y=-50,50 do table.insert(tiles,{name="grass-1",position={x,y}}) end end
  surface.set_tiles(tiles)
  for i,case in ipairs(cases) do
    local p=prototypes.entity[case.name]
    check(math.abs(p.braking_force-case.force)<0.00001,case.name .. " braking force")
    check(p.friction_force==case.friction,case.name .. " friction")
    for _, braking in ipairs({false,true}) do
      local index=#storage.rows
      local x=-90+index*18
      local row={name=case.name,braking=braking,cars={},starts={}}
      for j,name in ipairs({case.name,"factorio-test-reference-" .. case.name}) do
        local car=surface.create_entity{name=name,position={x+(j-1)*7,30},force="player"}
        check(car ~= nil,name .. " placed")
        car.orientation=0
        car.speed=0.5
        car.riding_state={acceleration=braking and defines.riding.acceleration.braking or defines.riding.acceleration.nothing,
          direction=defines.riding.direction.straight}
        row.cars[j]=car
        row.starts[j]=car.position.y
      end
      storage.rows[index+1]=row
    end
  end
end)
local function sample(event)
  for _,row in ipairs(storage.rows) do
    local actual,reference=row.cars[1],row.cars[2]
    check(math.abs(actual.speed-reference.speed)<1e-9,row.name .. " speed at " .. event.tick)
    local distance=row.starts[1]-actual.position.y
    local expected=row.starts[2]-reference.position.y
    check(math.abs(distance-expected)<1e-9,row.name .. " distance at " .. event.tick)
    check(actual.speed>=0 and actual.speed<0.5,row.name .. " deceleration")
  end
  if event.tick==60 then
    for i=1,#storage.rows,2 do
      local coast,brake=storage.rows[i],storage.rows[i+1]
      check(brake.cars[1].speed<coast.cars[1].speed,coast.name .. " braking beats coasting")
      check(brake.cars[1].position.y>coast.cars[1].position.y,coast.name .. " braking distance")
    end
    helpers.write_file("factorio-tests/vehicle-forces.json",helpers.table_to_json({
      schema=1,case="vehicle-forces",status="pass",factorio_version=script.active_mods.base,
      tick=game.tick,assertions=storage.assertions,vehicles=#cases,failure_count=0,failures={},
    }),false)
  end
end
for _, tick in ipairs({1,5,15,30,60}) do
  script.on_nth_tick(tick,function(event)
    if event.tick == 0 then return end
    script.on_nth_tick(tick,nil)
    sample(event)
  end)
end

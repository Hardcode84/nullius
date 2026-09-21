-- given: sixteen void-powered wells with their production recipe and geometry
-- place: one well per variant and cardinal direction, eight tiles apart
-- connect: one 10000-unit collector pipe to each well; retain all water
-- act: pump freshwater for 480 ticks
-- expect: 800/3200 water for normal tiers, 1000/4000 for legacy tiers
local modern = require("__nullius-star__/factorio-version").is_2_1
local fluid_api = require("__nullius-star__/scenarios/fluid-api")
local assertions = 0
local function check(ok,message)
  assertions = assertions+1
  assert(ok,message)
end
script.on_nth_tick(1,function()
  script.on_nth_tick(1,nil)
  local surface=game.create_surface("well-pictures-test",{width=96,height=64,autoplace_controls={}})
  surface.request_to_generate_chunks({0,0},2)
  surface.force_generate_chunk_requests()
  for _,entity in pairs(surface.find_entities()) do entity.destroy() end
  storage.rows={}
  for legacy,prefix in ipairs({"nullius-well-","nullius-legacy-well-"}) do
    for tier=1,2 do
      local speed=(tier==1 and 1 or 4)*(legacy==2 and 1.25 or 1)
      for i,direction in ipairs({defines.direction.north,defines.direction.east,defines.direction.south,defines.direction.west}) do
        local well=surface.create_entity{name="factorio-test-" .. prefix .. tier,
          position={i*8-20,(legacy*2+tier)*8-32},direction=direction,force="player"}
        check(well~=nil,"well placed")
        check(well.direction==direction,"direction retained")
        check(well.crafting_speed==speed,"crafting speed retained")
        check(well.get_recipe().name=="nullius-freshwater","fixed recipe retained")
        local offset=({{1,-2},{2,-1},{-1,2},{-2,1}})[i]
        local collector=surface.create_entity{name="factorio-test-well-collector",
          position={well.position.x+offset[1],well.position.y+offset[2]},force="player"}
        check(collector~=nil,"collector placed")
        storage.rows[#storage.rows+1]={well=well,collector=collector,speed=speed}
      end
    end
  end
  storage.assertions=assertions
end)
script.on_nth_tick(481,function(event)
  if event.tick==0 then return end
  script.on_nth_tick(481,nil)
  assertions=storage.assertions
  for _,row in ipairs(storage.rows) do
    local contents = assert(fluid_api.segment_contents(row.collector,1),"collector segment exists")
    local water = contents["nullius-freshwater"] or 0
    -- 2.0 stores the producer buffer outside the pipe segment. In 2.1 the
    -- segment total already includes the well, so do not count it twice.
    if not modern then
      local buffer = fluid_api.get(row.well,1)
      if buffer then
        check(buffer.name=="nullius-freshwater","freshwater in output buffer")
        water=water+buffer.amount
      end
    end
    for name in pairs(contents) do check(name=="nullius-freshwater","freshwater output") end
    check(math.abs(water-800*row.speed)<0.0001,"water throughput: " .. water)
  end
  helpers.write_file("factorio-tests/well-pictures.json",helpers.table_to_json({
    schema=1,case="well-pictures",status="pass",factorio_version=script.active_mods.base,
    tick=game.tick,assertions=assertions,wells=#storage.rows,failure_count=0,failures={}
  }),false)
end)

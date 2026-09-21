-- given: eight finite resources with 10000 units each; each mining cycle gives
-- 10 water. Both extractor tiers use void power and their production geometry.
-- place: one pair per tier and cardinal direction, 12 tiles apart
-- connect: none; output stays in the extractor
-- act: mine for 120 ticks
-- expect: 20 water at tier 1 and 40 water at tier 2, in every direction
local fluid_api = require("__nullius-star__/scenarios/fluid-api")
local assertions = 0
local function check(ok,message)
  assertions = assertions + 1
  assert(ok,message)
end
script.on_nth_tick(1,function()
  script.on_nth_tick(1,nil)
  local surface = game.create_surface("extractor-pictures-test",{width=96,height=64,autoplace_controls={}})
  surface.request_to_generate_chunks({0,0},2)
  surface.force_generate_chunk_requests()
  for _,entity in pairs(surface.find_entities()) do entity.destroy() end
  storage.rows = {}
  for tier=1,2 do
    for i,direction in ipairs({defines.direction.north,defines.direction.east,defines.direction.south,defines.direction.west}) do
      local position = {i*12-30,tier*12-18}
      check(surface.create_entity{name="factorio-test-extractor-resource",position=position,amount=10000} ~= nil,"resource placed")
      local drill = surface.create_entity{name="factorio-test-extractor-" .. tier,position=position,direction=direction,force="player"}
      check(drill ~= nil,"extractor placed")
      check(drill.direction == direction,"direction retained")
      check(drill.prototype.mining_speed == tier,"mining speed retained")
      storage.rows[#storage.rows+1] = {drill=drill,tier=tier}
    end
  end
  storage.assertions = assertions
end)
script.on_nth_tick(121,function(event)
  if event.tick == 0 then return end
  script.on_nth_tick(121,nil)
  assertions = storage.assertions
  for _,row in ipairs(storage.rows) do
    local fluid = fluid_api.get(row.drill,1)
    check(fluid and fluid.name == "water","water extracted")
    check(math.abs(fluid.amount - row.tier*20)<0.0001,"extraction rate: " .. fluid.amount)
  end
  helpers.write_file("factorio-tests/extractor-pictures.json",helpers.table_to_json({
    schema=1,case="extractor-pictures",status="pass",factorio_version=script.active_mods.base,
    tick=game.tick,assertions=assertions,extractors=#storage.rows,failure_count=0,failures={}
  }),false)
end)

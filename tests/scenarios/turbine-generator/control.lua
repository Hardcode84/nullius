-- given: 500 units of nullius-energy per generator; no other generation
-- place: all 18 variants, each in north and east orientation, on isolated grids
-- connect: each generator and a 10 MW test load to a small electric pole
-- act: rotate each generator once, then supply its declared fuel
-- run: measure steady output and fuel use between ticks 15 and 30
-- expect: rotation preserves orientation; each tier reaches its power cap
local fluids = require("__nullius-star__/scenarios/fluid-api")
local function check(ok, message)
  storage.assertions = storage.assertions + 1
  assert(ok, message)
end
local function generated(row)
  return row.pole.electric_network_statistics.get_output_count(row.generator.name)
end
script.on_nth_tick(1, function()
  script.on_nth_tick(1,nil)
  storage.assertions = 0
  storage.rows = {}
  local surface = game.create_surface("turbine-generator-test",{width=256,height=160,autoplace_controls={}})
  surface.request_to_generate_chunks({0,0},5)
  surface.force_generate_chunk_requests()
  for _, entity in pairs(surface.find_entities()) do entity.destroy() end
  local tiles = {}
  for x=-110,110 do for y=-60,60 do table.insert(tiles,{name="grass-1",position={x,y}}) end end
  surface.set_tiles(tiles)
  for tier=1,3 do
    for _, openness in ipairs({"open","closed"}) do
      for priority, usage in pairs({backup="tertiary",standard="secondary-output",exhaust="primary-output"}) do
        local name="nullius-turbine-generator-" .. openness .. "-" .. priority .. "-" .. tier
        local prototype=prototypes.entity[name]
        local power=({1000000,2500000,6000000})[tier]
        local efficiency=({0.9,0.95,1})[tier] - (openness=="closed" and 0.05 or 0)
        check(prototype.electric_energy_source_prototype.usage_priority == usage, name .. " priority")
        for _, direction in ipairs({defines.direction.north,defines.direction.east}) do
          local index=#storage.rows
          local x,y=(index%9)*24-100, math.floor(index/9)*30-45
          local generator=surface.create_entity{name=name,position={x,y},direction=direction,force="player"}
          check(generator ~= nil and generator.direction == direction,name .. " placement")
          generator.rotate()
          check(generator.direction == direction,name .. " retains two-direction rotation")
          local pole=surface.create_entity{name="small-electric-pole",position={x+2,y},force="player"}
          local load=surface.create_entity{name="factorio-test-turbine-load",position={x+3,y+2},force="player"}
          check(pole ~= nil and load ~= nil,name .. " grid placed")
          fluids.set(generator,1,{name="nullius-energy",amount=500,temperature=100})
          check(fluids.get(generator,1).amount == 500,name .. " fuel stock")
          table.insert(storage.rows,{generator=generator,pole=pole,load=load,power=power,efficiency=efficiency})
        end
      end
    end
  end
end)
script.on_nth_tick(15,function(event)
  if event.tick == 0 then return end
  for _, row in ipairs(storage.rows) do
    if event.tick == 15 then
      row.generated=generated(row)
      row.fuel=fluids.get(row.generator,1).amount
    else
      local joules=generated(row)-row.generated
      local used=row.fuel-fluids.get(row.generator,1).amount
      local name=row.generator.name
      check(math.abs(joules-row.power/4) < 1,name .. " output: " .. joules)
      check(math.abs(used*10000*row.efficiency-joules) < 1,name .. " fuel conversion")
      check(row.load.energy > 0,name .. " powered load")
    end
  end
  if event.tick == 30 then
    script.on_nth_tick(15,nil)
    helpers.write_file("factorio-tests/turbine-generator.json", helpers.table_to_json({
      schema=1,case="turbine-generator",status="pass",factorio_version=script.active_mods.base,
      tick=game.tick,assertions=storage.assertions,variants=#storage.rows/2,
      failure_count=0,failures={},
    }),false)
  end
end)

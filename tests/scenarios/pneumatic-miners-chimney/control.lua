-- given: pneumatic research, declared iron deposits and infinite fuel/waste gas.
-- place: each solid miner and chimney 3 in all four directions on Vulcanus.
-- connect: fuel through both machine ports; waste gas through its own inlet.
-- act: switch modes with gas present, then run without electricity.
-- expect: miners produce ore, chimneys vent nitrogen, and mode changes preserve waste gas.
local CASE = "pneumatic-miners-chimney"
local fluid = require("__nullius-star__/scenarios/fluid-api")
local names = {
  "nullius-small-miner-1", "nullius-small-miner-2", "nullius-small-miner-3",
  "nullius-medium-miner-1", "nullius-medium-miner-2", "nullius-medium-miner-3",
  "nullius-large-miner-1", "nullius-large-miner-2", "nullius-chimney-3",
}
local assertions, failures, rows = 0, {}, {}
local function check(value, message)
  assertions = assertions + 1
  if not value then failures[#failures + 1] = message end
end
local function toggle(entity, name)
  local surface, position, direction = entity.surface, entity.position, entity.direction
  check(remote.call("nullius-test-transitions", "execute", entity), "transition rejected: " .. name)
  local replacement = assert(surface.find_entity(name, position), "missing replacement " .. name)
  check(replacement.direction == direction, name .. " direction changed")
  return replacement
end
local function setup()
  local force = game.forces.player
  force.technologies["nullius-pneumatic-technology"].researched = true
  force.recipes["nullius-void-nitrogen"].enabled = true
  local planet = game.planets["nullius-vulcanus"]
  local surface = planet.surface or planet.create_surface()
  surface.request_to_generate_chunks({0, 0}, 4)
  surface.force_generate_chunk_requests()
  for _, entity in pairs(surface.find_entities()) do entity.destroy() end
  local tiles = {}
  for x=-15,115 do for y=-15,65 do
    tiles[#tiles+1] = {name="volcanic-soil-dark", position={x,y}}
  end end
  surface.set_tiles(tiles)
  for n, name in ipairs(names) do
    for d, direction in ipairs({defines.direction.north, defines.direction.east,
        defines.direction.south, defines.direction.west}) do
      local position = {((n-1)%5)*22, (math.floor((n-1)/5)*4+d-1)*8}
      local chimney = name == "nullius-chimney-3"
      if not chimney then
        assert(surface.create_entity{name="iron-ore", position=position, amount=100000})
      end
      local machine = assert(surface.create_entity{name=name, position=position, direction=direction, force=force})
      if chimney then fluid.set(machine, 1, {name="nullius-nitrogen", amount=100}) end
      machine = toggle(machine, name .. "-pneumatic")
      local fuel, process
      for i=1,fluid.count(machine) do
        if fluid.prototype(machine,i).production_type == "none" then fuel=i else process=i end
      end
      assert(fuel, "missing fuel port")
      if chimney then
        check(fluid.get(machine,process).name == "nullius-nitrogen", "waste gas lost entering pneumatic mode")
      end
      fluid.set(machine,fuel,{name="nullius-compressed-volcanic-gas",amount=100,temperature=200})
      machine = toggle(machine, name)
      if chimney then
        local gas = fluid.get(machine,1)
        check(gas and gas.name == "nullius-nitrogen" and gas.amount == 100, "waste gas lost leaving pneumatic mode")
      end
      check(#surface.find_entities_filtered{position=machine.position, radius=0.1,
        name={"nullius-pneumatic-heat-small","nullius-pneumatic-heat-medium",
          "nullius-pneumatic-heat-medium2","nullius-pneumatic-heat-large"}} == 0,
        name .. " left a heat interface")
      machine = toggle(machine, name .. "-pneumatic")
      check(machine.prototype.electric_energy_source_prototype == nil, name .. " requires electricity")
      check(machine.prototype.get_max_energy_usage() == prototypes.entity[name].get_max_energy_usage(), name .. " power changed")
      local ports = fluid.connections(machine,fuel)
      check(#ports == 2, name .. " missing pass-through port")
      local pipes = {}
      for i, port in ipairs(ports) do
        check(surface.can_place_entity{name="pipe",position=port.target_position,force=force}, name .. " fuel pipe obstructed")
        local pipe = assert(surface.create_entity{name=i==1 and "infinity-pipe" or "pipe",position=port.target_position,force=force})
        if i==1 then pipe.set_infinity_pipe_filter{name="nullius-compressed-volcanic-gas",percentage=1,mode="at-least",temperature=200} end
        pipes[#pipes+1]=pipe
      end
      local chest
      if chimney then
        local port = fluid.connections(machine,process)[1]
        check(surface.can_place_entity{name="pipe",position=port.target_position,force=force}, "waste inlet obstructed")
        local source=assert(surface.create_entity{name="infinity-pipe",position=port.target_position,force=force})
        source.set_infinity_pipe_filter{name="nullius-nitrogen",percentage=1,mode="at-least"}
      else
        chest=assert(surface.create_entity{name="iron-chest",position=machine.drop_position,force=force})
      end
      rows[#rows+1]={machine=machine,chest=chest,pipes=pipes,chimney=chimney}
    end
  end
end
local function finish()
  for _, row in ipairs(rows) do
    local machine=row.machine
    for _, pipe in ipairs(row.pipes) do
      local gas=fluid.get(pipe,1)
      check(gas and gas.name=="nullius-compressed-volcanic-gas" and gas.amount>0,
        machine.name .. " fuel pass-through disconnected")
    end
    if row.chimney then
      check(machine.products_finished>0, "chimney did not vent gas")
    else
      check(row.chest.get_item_count("iron-ore")>0, machine.name .. " did not mine ore")
    end
  end
  local result={schema=1,case=CASE,status=#failures==0 and "pass" or "fail",
    factorio_version=script.active_mods.base,tick=game.tick,assertions=assertions,
    failure_count=#failures,failures=failures,observations={machines=#rows}}
  helpers.write_file("factorio-tests/"..CASE..".json",helpers.table_to_json(result),false)
  if #failures>0 then error(helpers.table_to_json(result)) end
end
script.on_nth_tick(1,function()
  script.on_nth_tick(1,nil)
  setup()
end)
script.on_nth_tick(600,function()
  if game.tick == 0 then return end
  script.on_nth_tick(600,nil)
  finish()
end)

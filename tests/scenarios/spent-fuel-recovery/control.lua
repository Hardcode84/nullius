-- given: production cars with declared half-consumed fuel, two unused fuel items,
-- and three spent items; normal and rare quality; debug power and fifty robots.
-- place/connect: cars, a storage chest, and a powered roboport on clear land.
-- act: mine with the native player API or construction robots; kill other cars.
-- run: allow 1800 ticks for robot collection.
-- expect: one extra spent item per active fuel, preserved quality and inventory,
-- no refunds from empty burners or deaths.
local CASE="spent-fuel-recovery"
local fuels={"nullius-battery-1","nullius-battery-2","nullius-battery-3",
  "processed-fuel","nullius-hydrogen-canister"}
local function check(ok,msg) storage.assertions=storage.assertions+1;assert(ok,msg) end
local function count(inventory,name,quality)
  return inventory.get_item_count{name=name,quality=quality}
end
local function car(surface,pos,fuel,quality)
  local e=assert(surface.create_entity{name="nullius-car-1",position=pos,force="player"})
  if fuel then
    local result=prototypes.item[fuel].burnt_result.name
    e.burner.currently_burning={name=fuel,quality=quality}
    e.burner.remaining_burning_fuel=prototypes.item[fuel].fuel_value/2
    check(e.burner.inventory.insert{name=fuel,quality=quality,count=2}==2,"unused fuel fixture")
    check(e.burner.burnt_result_inventory.insert{name=result,quality=quality,count=3}==3,"spent fixture")
  end
  return e
end
script.on_nth_tick(1,function()
  local player=game.get_player("nullius-test-a")
  if not player or not player.connected then return end
  storage.start_tick=game.tick
  storage.player_events=0;storage.robot_events=0
  script.on_nth_tick(1,nil)
  storage.assertions=0;storage.expected={};storage.cars={};storage.player_expected={}
  local s=game.surfaces.nauvis
  s.request_to_generate_chunks({0,0},3);s.force_generate_chunk_requests()
  for _,e in pairs(s.find_entities_filtered{area={{-60,-60},{60,60}}}) do e.destroy() end
  local tiles={}
  for x=-60,60 do for y=-60,60 do tiles[#tiles+1]={name="landfill",position={x,y}} end end
  s.set_tiles(tiles,true)
  player.set_controller{type=defines.controllers.god}
  player.teleport({0,-20},s)
  local character=player
  local inventory=character.get_main_inventory()
  inventory.clear()
  storage.character=character
  for _,quality in ipairs{"normal","rare"} do
    for _,fuel in ipairs(fuels) do
      local e=car(s,{0,-16},fuel,quality)
      local result=prototypes.item[fuel].burnt_result.name
      check(character.mine_entity(e,true),"native player mining")
      storage.player_expected[#storage.player_expected+1]={fuel=fuel,result=result,quality=quality}
    end
  end
  local full=car(s,{0,-16},"nullius-battery-1","normal")
  full.burner.burnt_result_inventory.clear()
  local stack_size=prototypes.item["nullius-uncharged-battery-1"].stack_size
  check(full.burner.burnt_result_inventory.insert{name="nullius-uncharged-battery-1",count=stack_size}==stack_size,"full spent slot")
  check(character.mine_entity(full,true),"mine full spent slot")
  storage.player_expected[1].spent=4+stack_size+1
  storage.player_expected[1].unused=4
  local empty=car(s,{0,-16})
  check(character.mine_entity(empty,true),"empty burner mining")
  for _,fuel in ipairs(fuels) do
    local dead=car(s,{0,-16},fuel,"normal")
    dead.burner.inventory.clear();dead.burner.burnt_result_inventory.clear()
    check(dead.die(),"car death")
  end
  check(s.count_entities_filtered{type="item-entity"}==0,"death fabricated return")
  local port=assert(s.create_entity{name="roboport",position={0,12},force="player"})
  check(port.insert{name="construction-robot",count=50}==50,"robot fixture")
  assert(s.create_entity{name="substation",position={4,12},force="player"})
  local power=assert(s.create_entity{name="factorio-test-planner-grid",position={8,12},force="player"})
  power.power_production=1000000000;power.electric_buffer_size=1000000000;power.energy=1000000000
  storage.chest=assert(s.create_entity{name="storage-chest",position={4,16},force="player"})
  for q,quality in ipairs{"normal","rare"} do
    for i,fuel in ipairs(fuels) do
      local e=car(s,{(i-3)*6,(q-1)*6},fuel,quality)
      check(e.order_deconstruction("player"),"robot deconstruction ordered")
      storage.cars[#storage.cars+1]=e
      local result=prototypes.item[fuel].burnt_result.name
      storage.expected[#storage.expected+1]={fuel=fuel,result=result,quality=quality}
    end
  end
end)
script.on_nth_tick(60,function()
  if not storage.start_tick or game.tick<storage.start_tick+60 then return end
  script.on_nth_tick(60,nil)
  local inventory=storage.character.get_main_inventory()
  for _,row in ipairs(storage.player_expected) do
    check(count(inventory,row.result,row.quality)==(row.spent or 4),"player spent return "..row.fuel.." "..row.quality.." actual "..count(inventory,row.result,row.quality))
    check(count(inventory,row.fuel,row.quality)==(row.unused or 2),"player unused fuel")
  end
  check(storage.player_events==12,"native player mining events")
  check(count(inventory,"nullius-car-1","normal")==12,"player car and empty burner returns")
end)
script.on_nth_tick(30,function()
  if not storage.start_tick or game.tick<storage.start_tick+1800 then return end
  script.on_nth_tick(30,nil)
  for _,e in ipairs(storage.cars) do check(not e.valid,"robot did not mine car") end
  local inventory=storage.chest.get_inventory(defines.inventory.chest)
  for _,row in ipairs(storage.expected) do
    check(count(inventory,row.result,row.quality)==4,"robot spent return "..row.fuel.." "..row.quality)
    check(count(inventory,row.fuel,row.quality)==2,"robot unused fuel "..row.fuel)
  end
  check(storage.robot_events==10,"native robot mining events")
  check(count(inventory,"nullius-car-1","normal")==10,"robot car returns")
  helpers.write_file("factorio-tests/"..CASE..".json",helpers.table_to_json{
    schema=1,case=CASE,status="pass",assertions=storage.assertions,failure_count=0,
    tick=game.tick,factorio_version=script.active_mods.base},false)
end)

script.on_event(defines.events.on_player_mined_entity,function(event)
  if event.entity.name=="nullius-car-1" then storage.player_events=storage.player_events+1 end
end)
script.on_event(defines.events.on_robot_mined_entity,function(event)
  if event.entity.name=="nullius-car-1" then storage.robot_events=storage.robot_events+1 end
end)

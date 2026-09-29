-- given: empty batteries with unlimited generators; charged batteries without generators;
-- charged isolated supercapacitors; one motor and three gears per consumer.
-- place/connect: separate copper networks for charge, normal load, surge and storage transfer.
-- act/run: fill initial storage once; run 601 ticks without further energy writes.
-- expect: native charging/discharge, idle leakage; record surge and storage transfer behavior.
local config=require("__nullius-star__/shared/supercapacitors")
local input=require("__nullius-star__/scenarios/inventory-api").crafting_input
local function check(ok,message)
  storage.assertions=storage.assertions+1;assert(ok,message)
end
local function near(actual,expected,message)
  check(math.abs(actual-expected)<1, message..": "..actual.." expected "..expected)
end
local function place(name,x,y)
  return assert(game.surfaces.nauvis.create_entity{name=name,position={x,y},force="player",raise_built=true})
end
script.on_nth_tick(1,function()
  if game.tick==0 then return end
  script.on_nth_tick(1,nil)
  storage.assertions=0;storage.leaks={};storage.charges={};storage.observations={}
  game.forces.player.technologies[config.technology].researched=true
  for _,base in ipairs(config.machines) do game.forces.player.recipes[base].enabled=true end
  local surface=game.surfaces.nauvis
  surface.request_to_generate_chunks({160,0},12);surface.force_generate_chunk_requests()
  for _,entity in ipairs(surface.find_entities_filtered{area={{-20,-20},{540,120}}}) do entity.destroy() end
  local tiles={}
  for x=-20,540 do for y=-20,120 do tiles[#tiles+1]={name="landfill",position={x,y}} end end
  surface.set_tiles(tiles,true)
  for i,base in ipairs(config.machines) do
    local name=base.."-supercapacitor"
    local x=(i-1)*100
    local battery=place(name,x,0)
    local ordinary=prototypes.entity[base].electric_energy_source_prototype
    local source=battery.prototype.electric_energy_source_prototype
    near(battery.electric_buffer_size,ordinary.buffer_capacity*config.capacity_factor,"capacity")
    near(source.get_input_flow_limit(),ordinary.get_input_flow_limit()*config.flow_factor,"input rate")
    near(source.get_output_flow_limit(),ordinary.get_output_flow_limit()*config.flow_factor,"output rate")
    battery.energy=battery.electric_buffer_size
    storage.leaks[#storage.leaks+1]={entity=battery,energy=battery.energy,drain=battery.electric_buffer_size*config.leakage_per_second/60}
    local charging=place(name,x,40)
    local grid=place("factorio-test-planner-grid",x+6,40)
    grid.power_production=1000000000;grid.electric_buffer_size=1000000000
    place("substation",x+3,44)
    storage.charges[#storage.charges+1]=charging
    local ordinary_charging=place(base,x,100)
    local ordinary_grid=place("factorio-test-planner-grid",x+6,100)
    ordinary_grid.power_production=1000000000;ordinary_grid.electric_buffer_size=1000000000
    place("substation",x+3,104)
    storage.charges[#storage.charges+1]=ordinary_charging
  end
  storage.switching=place("nullius-grid-battery-1-supercapacitor",0,80)
  storage.switching.energy=storage.switching.electric_buffer_size
  storage.empty=place("nullius-grid-battery-1-supercapacitor",20,80)
  storage.empty.energy=1
  for i,mode in ipairs({"ordinary","surge","transfer"}) do
    local x=300+(i-1)*100
    local donor=place("nullius-grid-battery-3-supercapacitor",x,0)
    donor.energy=donor.electric_buffer_size
    place("substation",x+4,5)
    local load
    if mode=="transfer" then
      load=place("nullius-grid-battery-1",x+7,0)
    else
      load=place("nullius-medium-assembler-1"..(mode=="surge" and "-overcharged" or ""),x+7,0)
      game.forces.player.recipes["nullius-mechanical-pack"].enabled=true
      load.set_recipe("nullius-mechanical-pack")
      check(load.get_recipe()~=nil,"consumer recipe rejected")
      load.get_inventory(input).insert{name="nullius-motor-1",count=1}
      load.get_inventory(input).insert{name="nullius-iron-gear",count=3}
    end
    storage[mode]={donor=donor,load=load}
  end
end)
script.on_nth_tick(2,function()
  if game.tick==0 then return end
  for _,entity in ipairs(storage.charges) do
    local rate=entity.prototype.electric_energy_source_prototype.get_input_flow_limit()
    near(entity.energy,math.min(entity.electric_buffer_size,rate),"first-tick native charge")
  end
  script.on_nth_tick(2,nil)
end)
script.on_nth_tick(31,function()
  if game.tick==0 then return end
  for _,entity in ipairs(storage.charges) do
    near(entity.energy,math.min(entity.electric_buffer_size,entity.prototype.electric_energy_source_prototype.get_input_flow_limit()*30),"native charge saturation")
  end
  local entity=storage.switching
  local expected=entity.energy-entity.electric_buffer_size*config.leakage_per_second*30/60
  remote.call("nullius-test-transitions","execute",entity)
  entity=game.surfaces.nauvis.find_entity("nullius-grid-battery-1",{0,80})
  near(entity.energy,expected,"switch settles pending leakage")
  remote.call("nullius-test-transitions","execute",entity)
  entity=game.surfaces.nauvis.find_entity("nullius-grid-battery-1-supercapacitor",{0,80})
  near(entity.energy,expected,"same tick switch double leakage")
  script.on_nth_tick(31,nil)
end)
script.on_nth_tick(61,function()
  if game.tick==0 then return end
  for _,row in ipairs(storage.leaks) do
    near(row.entity.energy,row.energy-row.drain*59,"isolated leakage")
  end
  check(storage.empty.energy==0,"leakage below zero")
  script.on_nth_tick(61,nil)
end)
script.on_nth_tick(601,function()
  if game.tick==0 then return end
  for _,entity in ipairs(storage.charges) do check(entity.energy>entity.electric_buffer_size*.98,"charging stalled") end
  check(storage.ordinary.load.crafting_progress>0 or storage.ordinary.load.products_finished>0,"normal consumer not supplied")
  check(storage.surge.load.energy==0,"accumulator unexpectedly supplies surge")
  check(storage.transfer.load.energy==0,"accumulator unexpectedly transfers storage")
  near(storage.transfer.donor.energy,storage.transfer.donor.electric_buffer_size*(1-config.leakage_per_second*599/60),"connected idle leakage")
  for _,mode in ipairs({"ordinary","surge","transfer"}) do
    local row=storage[mode]
    storage.observations[mode]={donor_energy=row.donor.energy,load_energy=row.load.energy}
  end
  log("SUPERCAPACITOR ENERGY "..helpers.table_to_json(storage.observations))
  helpers.write_file("factorio-tests/supercapacitor-energy.json",helpers.table_to_json{
    schema=1,case="supercapacitor-energy",status="pass",failure_count=0,assertions=storage.assertions,
    observations=storage.observations,tick=game.tick,factorio_version=script.active_mods.base},false)
end)

-- given: pneumatic research, a configured silo, two rocket stages, a module and finite gas.
-- place/connect: silo and gas tank on Vulcanus; a wired circuit at the silo.
-- act/run: round-trip idle and partly crafted silos through the production switch.
-- expect: inventories, requests, circuit settings and progress survive; heat follows mode.
local CASE="pneumatic-silo-transition"
local function check(ok,message)
  storage.assertions=storage.assertions+1
  assert(ok,message)
end
local function toggle(e,name)
  local s,p=e.surface,e.position
  check(remote.call("nullius-test-transitions","execute",e),"registered transition")
  return assert(s.find_entity(name,p),"missing "..name)
end
local function heat(e,count)
  check(#e.surface.find_entities_filtered{position=e.position,radius=0.1,
    name="nullius-pneumatic-heat-large"}==count,"heat ownership")
end
local function verify(e)
  check(e.send_to_orbit_automatically,"automatic orbit setting")
  check(e.use_transitional_requests == (not storage.partial),"platform request setting")
  check(e.products_finished==7,"production counter")
  if storage.expected_bonus then
    check(e.get_inventory(defines.inventory.crafter_input).get_item_count("nullius-rocket-stage")==1,"spare stage preserved")
  end
  check(e.bonus_progress==(storage.expected_bonus or 0.25),"productivity progress")
  check(e.get_inventory(defines.inventory.rocket_silo_trash).get_item_count("iron-plate")==3,"trash stock")
  check(#e.get_output_inventory()==0,"silo has no result slots in 2.1")
  check(e.get_module_inventory().get_item_count("nullius-productivity-module-1")==1,"module")
  local section=e.get_logistic_sections().get_section(2)
  check(section.group=="silo fixture" and section.get_slot(1).min==5,"logistic section and request")
  check(e.get_or_create_control_behavior().read_mode==1,"circuit setting")
  check(#e.get_wire_connector(defines.wire_connector_id.circuit_red,true).connections==1,"circuit wire")
end
script.on_nth_tick(1,function()
  script.on_nth_tick(1,nil)
  storage.assertions=0
  local ground=false
  for _,condition in pairs(prototypes.entity["nullius-silo-pneumatic"].surface_conditions) do
    ground=ground or (condition.property=="pressure" and condition.min==1)
  end
  check(ground,"native platform prohibition")
  local planet=game.planets["nullius-vulcanus"]
  local s=planet.surface or planet.create_surface()
  s.request_to_generate_chunks({0,0},1);s.force_generate_chunk_requests()
  for _,e in pairs(s.find_entities()) do e.destroy() end
  local tiles={}
  for x=-15,15 do for y=-15,15 do tiles[#tiles+1]={name="volcanic-soil-dark",position={x,y}} end end
  s.set_tiles(tiles)
  local f=game.forces.player
  local e=assert(s.create_entity{name="nullius-silo",position={0,0},force=f})
  check(not remote.call("nullius-test-transitions","execute",e),"research gate")
  f.technologies["nullius-pneumatic-technology"].researched=true
  f.technologies["nullius-rocket-science-2"].researched=true
  e.send_to_orbit_automatically=true;e.use_transitional_requests=true
  e.products_finished=7;e.bonus_progress=0.25
  e.get_inventory(defines.inventory.rocket_silo_trash).insert{name="iron-plate",count=3}
  e.get_module_inventory().insert{name="nullius-productivity-module-1",count=1}
  e.get_logistic_sections().add_section("silo fixture").set_slot(1,
    {value={type="item",name="iron-plate",quality="normal"},min=5,max=5})
  e.get_or_create_control_behavior().read_mode=1
  local pole=assert(s.create_entity{name="small-electric-pole",position={0,6},force=f})
  e.get_wire_connector(defines.wire_connector_id.circuit_red,true).connect_to(
    pole.get_wire_connector(defines.wire_connector_id.circuit_red,true))
  verify(e)
  e=toggle(e,"nullius-silo-pneumatic");verify(e);heat(e,1)
  e=toggle(e,"nullius-silo");verify(e);heat(e,0)
  e=toggle(e,"nullius-silo-pneumatic")
  local tank=assert(s.create_entity{name="nullius-medium-tank-2",position={6,1},force=f})
  tank.set_fluid(1,{name="nullius-compressed-volcanic-gas",amount=1000,temperature=200})
  storage.partial=true
  e.use_transitional_requests=false
  check(e.insert{name="nullius-rocket-stage",count=2}==2,"finite stages")
  storage.silo=e
  local ghost=assert(s.create_entity{name="entity-ghost",inner_name="nullius-silo",position={-10,0},force=f})
  check(remote.call("nullius-test-transitions","execute",ghost) and ghost.valid,"unproven ghost stays unchanged")
  local surface=game.surfaces.nauvis
  local other=assert(surface.create_entity{name="nullius-silo",position={40,40},force=f})
  check(not remote.call("nullius-test-transitions","execute",other),"planet gate")
end)
script.on_nth_tick(120,function()
  if game.tick==0 then return end
  local e=storage.silo
  local progress=e.crafting_progress
  check(progress>0 and progress<1,"native partial craft")
  storage.expected_bonus=e.bonus_progress
  check(e.get_inventory(defines.inventory.crafter_input).get_item_count("nullius-rocket-stage")==1,"one stage consumed")
  check(storage.expected_bonus>0.25,"native productivity accrues")
  e=toggle(e,"nullius-silo");verify(e)
  check(e.crafting_progress==progress,"partial craft entering electric")
  e=toggle(e,"nullius-silo-pneumatic");verify(e)
  check(e.crafting_progress==progress,"partial craft entering pneumatic")
  heat(e,1)
  helpers.write_file("factorio-tests/"..CASE..".json",helpers.table_to_json{
    schema=1,case=CASE,status="pass",assertions=storage.assertions,failure_count=0,tick=game.tick},false)
  script.on_nth_tick(120,nil)
end)

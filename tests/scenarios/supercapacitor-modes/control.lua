-- given: ordinary battery recipes and research prerequisites; ten research units;
-- unlimited electricity for labs only. Battery charge is assigned once per fixture.
-- place/connect: all battery tiers, ghosts, circuit wires and powered labs on Nauvis.
-- act: use the Ctrl+R transition, build/revive/clone variants, research in real labs.
-- run: 3000 ticks. Expect force-specific gates, energy caps and retained settings.
local config=require("__nullius-star__/shared/supercapacitors")
local function check(ok,message)
  storage.assertions=storage.assertions+1;assert(ok,message)
end
local function toggle(entity,name)
  local surface,position=entity.surface,entity.position
  remote.call("nullius-test-transitions","execute",entity)
  local result=surface.find_entity(name,position)
  check(result~=nil,"expected "..name)
  return result
end
local function place(name,pos,force,raise)
  local entity=game.surfaces.nauvis.create_entity{name=name,position=pos,force=force,raise_built=raise}
  if not raise then assert(entity,"Cannot place "..name) end
  return entity
end
local function gates(force,unlocked)
  for i,base in ipairs(config.machines) do
    local pos={i*16,40}
    local variant=base.."-supercapacitor"
    local expected=unlocked and variant or base
    toggle(place(base,pos,force),expected).destroy()
    place(variant,pos,force,true)
    local result=game.surfaces.nauvis.find_entity(expected,pos)
    check(result~=nil,"placement gate");result.destroy()
    local ghost=game.surfaces.nauvis.create_entity{name="entity-ghost",inner_name=base,position=pos,force=force}
    ghost.tags={fixture="mode"}
    local pole=place("substation",{pos[1],50},force)
    ghost.get_wire_connector(defines.wire_connector_id.circuit_red,true).connect_to(
      pole.get_wire_connector(defines.wire_connector_id.circuit_red,true))
    local behavior=ghost.get_or_create_control_behavior()
    behavior.output_signal={type="virtual",name="signal-A"};behavior.read_charge=false
    remote.call("nullius-test-transitions","execute",ghost)
    result=game.surfaces.nauvis.find_entities_filtered{position=pos,type="entity-ghost"}[1]
    check(result.ghost_name==expected,"ghost gate")
    check(result.tags.fixture=="mode","ghost tags")
    check(#result.get_wire_connector(defines.wire_connector_id.circuit_red,true).connections==1,"ghost wire")
    pole.destroy()
    check(result.get_control_behavior().output_signal.name=="signal-A","ghost signal")
    check(not result.get_control_behavior().read_charge,"ghost read setting")
    result.destroy()
    local inventory=game.create_inventory(1)
    inventory[1].set_stack{name="blueprint"}
    inventory[1].set_blueprint_entities{{entity_number=1,name=variant,position={0,0},tags={fixture="blueprint"}}}
    inventory[1].build_blueprint{surface=game.surfaces.nauvis,force=force,position=pos,raise_built=true}
    result=game.surfaces.nauvis.find_entities_filtered{position=pos,radius=4,type="entity-ghost"}[1]
    check(result and result.ghost_name==expected,"blueprint gate")
    check(result.tags.fixture=="blueprint","blueprint tags")
    local revived_position=result.position
    result.revive{raise_revive=true}
    check(game.surfaces.nauvis.find_entity(expected,revived_position)~=nil,"revive gate")
    for _,e in pairs(game.surfaces.nauvis.find_entities_filtered{position=pos,radius=4,type="accumulator"}) do e.destroy() end
    inventory.destroy()
  end
end
script.on_nth_tick(1,function()
  if game.tick==0 then return end
  script.on_nth_tick(1,nil);storage.assertions=0
  local force=game.create_force("supercapacitors")
  storage.force=force;storage.peer=game.create_force("capacitor-peer")
  local surface=game.surfaces.nauvis
  surface.request_to_generate_chunks({40,0},4);surface.force_generate_chunk_requests()
  for _,e in pairs(surface.find_entities_filtered{area={{-20,-20},{120,100}}}) do e.destroy() end
  local tiles={}
  for x=-20,120 do for y=-20,100 do tiles[#tiles+1]={name="landfill",position={x,y}} end end
  surface.set_tiles(tiles,true)
  for _,base in ipairs(config.machines) do
    force.recipes[base].enabled=true;storage.peer.recipes[base].enabled=true
  end
  gates(force,false)
  force.technologies["nullius-primitive-filtration"].researched=true
  force.technologies["nullius-battery-storage-2"].researched=true
  local tech=force.technologies[config.technology]
  check(tech.prerequisites["nullius-primitive-filtration"]~=nil,"filtration prerequisite")
  check(tech.prerequisites["nullius-battery-storage-2"]~=nil,"battery prerequisite")
  check(tech.research_unit_count==10 and tech.research_unit_energy==1800,"research cost")
  for i=1,10 do
    local x=(i-1)*10
    local lab=place("nullius-lab-1",{x,0},force)
    local grid=place("factorio-test-planner-grid",{x+4,0},force)
    grid.power_production=100000000;grid.electric_buffer_size=100000000
    place("substation",{x,5},force)
    local inv=lab.get_inventory(defines.inventory.lab_input)
    check(inv.insert{name="nullius-electromagnetic-pack",count=10}==10,"EM fixture")
    check(inv.insert{name="nullius-electrical-pack",count=4}==4,"electrical fixture")
  end
  check(force.add_research(config.technology),"start research")
end)
script.on_nth_tick(3000,function()
  if game.tick==0 then return end
  local force=storage.force
  check(force.technologies[config.technology].researched,"lab research stalled")
  gates(force,true);gates(storage.peer,false)
  for i,base in ipairs(config.machines) do
    local variant=base.."-supercapacitor"
    local pos={i*16,70}
    local entity=place(base,pos,force)
    entity.energy=entity.electric_buffer_size;entity.health=100
    local control=entity.get_or_create_control_behavior()
    control.output_signal={type="virtual",name="signal-A"};control.read_charge=false
    local pole=place("substation",{pos[1],80},force)
    entity.get_wire_connector(defines.wire_connector_id.circuit_red,true).connect_to(
      pole.get_wire_connector(defines.wire_connector_id.circuit_red,true))
    entity=toggle(entity,variant)
    local capacity=entity.electric_buffer_size
    check(entity.energy==capacity,"energy cap")
    check(entity.health==100,"health retained")
    check(entity.get_control_behavior().output_signal.name=="signal-A","output signal retained")
    check(not entity.get_control_behavior().read_charge,"read setting retained")
    check(#entity.get_wire_connector(defines.wire_connector_id.circuit_red,true).connections==1,"wire retained")
    entity=toggle(entity,base)
    check(entity.energy==capacity,"return created energy")
    entity.energy=100000
    entity=toggle(entity,variant);check(entity.energy==100000,"partial energy lost")
    entity.clone{position={pos[1],90},surface=entity.surface,force=storage.peer}
    local clone=entity.surface.find_entity(base,{pos[1],90})
    check(clone~=nil and clone.energy<=100000,"clone gate/energy")
    clone.destroy()
    force.recipes[base].enabled=false
    entity=toggle(entity,base)
    toggle(entity,base).destroy()
    force.recipes[base].enabled=true
    local next_upgrade=prototypes.entity[variant].next_upgrade
    check(i==3 and next_upgrade==nil or i<3 and next_upgrade.name==config.machines[i+1].."-supercapacitor","upgrade chain")
  end
  helpers.write_file("factorio-tests/supercapacitor-modes.json",helpers.table_to_json{
    schema=1,case="supercapacitor-modes",status="pass",failure_count=0,assertions=storage.assertions,
    tick=game.tick,factorio_version=script.active_mods.base},false)
end)

-- given: ordinary prerequisite research; exactly one research unit per lab;
-- ten labs for tier 2, twenty for tier 3; declared unlimited electricity.
-- place: all assembler sizes, ghosts and clones on Nauvis; pneumatic units on Vulcanus.
-- connect: labs to a supplied electric grid.
-- act: research both tiers in real labs; try each mode before and after research.
-- run: 8000 ticks.
-- expect: force-specific gates, no placement bypass, and ordinary recipe requirements.
local specs=require("__nullius-star__/shared/overcharged-assemblers")
local function check(ok,message)
  storage.assertions=storage.assertions+1
  assert(ok,message)
end
local function tech(tier) return "nullius-overcharged-assembly-"..tier end
local function place(surface,name,position,force,raise)
  return surface.create_entity{name=name,position=position,force=force,raise_built=raise}
end
local function toggle(entity,expected)
  local surface,position=entity.surface,entity.position
  remote.call("nullius-test-transitions","execute",entity)
  local replacement=surface.find_entity(expected,position)
  check(replacement~=nil,"expected transition to "..expected)
  return replacement
end
local function gates(force,tier)
  local surface=game.surfaces.nauvis
  for i,spec in ipairs(specs) do
    local pos={i*16,40}
    local ordinary=assert(place(surface,spec.base,pos,force))
    local allowed=spec.tier==1 or spec.tier<=tier
    local mode=spec.base..(allowed and "-overcharged" or "")
    local changed=toggle(ordinary,mode)
    if allowed then changed=toggle(changed,spec.base) end
    changed.destroy()
    local ghost=assert(surface.create_entity{name="entity-ghost",inner_name=spec.base,
      position=pos,force=force})
    remote.call("nullius-test-transitions","execute",ghost)
    local result=surface.find_entities_filtered{position=pos,type="entity-ghost"}[1]
    check(result.ghost_name==mode,"ghost research gate "..spec.base)
    result.destroy()
    place(surface,spec.base.."-overcharged",pos,force,true)
    result=surface.find_entity(mode,pos)
    check(result~=nil,"built variant research gate "..spec.base)
    result.destroy()
    local inventory=game.create_inventory(1)
    inventory[1].set_stack{name="blueprint"}
    inventory[1].set_blueprint_entities{{entity_number=1,name=spec.base.."-overcharged",
      position={0,0},tags={fixture="blueprint"}}}
    inventory[1].build_blueprint{surface=surface,force=force,position=pos,
      skip_fog_of_war=false,raise_built=true}
    result=surface.find_entities_filtered{position=pos,radius=4,type="entity-ghost"}[1]
    check(result~=nil,"blueprint placement")
    inventory.destroy()
    check(result.ghost_name==mode,"blueprint research gate "..spec.base)
    check(result.tags.fixture=="blueprint","blueprint tags lost")
    result.destroy()
  end
end
local function research(tier,unit_count,ingredients)
  local force=storage.force
  local technology=force.technologies[tech(tier)]
  check(technology.research_unit_count==unit_count,"unit count")
  check(technology.research_unit_energy==(tier==2 and 45 or 60)*60,"research time")
  local actual={}
  for _,ingredient in pairs(technology.research_unit_ingredients) do actual[ingredient.name]=ingredient.amount end
  for name,amount in pairs(ingredients) do check(actual[name]==amount,"research ingredient "..name) end
  for name in pairs(actual) do check(ingredients[name]~=nil,"unexpected science "..name) end
  for i=1,unit_count do
    local x,y=(i-1)*8,tier*8-16
    local lab=assert(place(game.surfaces.nauvis,"nullius-lab-1",{x,y},force))
    local grid=assert(place(game.surfaces.nauvis,"factorio-test-planner-grid",{x+4,y},force))
    grid.power_production=100000000;grid.electric_buffer_size=100000000
    place(game.surfaces.nauvis,"substation",{x,y+4},force)
    for name,amount in pairs(ingredients) do
      check(lab.get_inventory(defines.inventory.lab_input).insert{name=name,count=amount}==amount,"lab fixture "..name)
    end
  end
  check(force.add_research(tech(tier)),"cannot start research")
end
script.on_nth_tick(1,function()
  if game.tick==0 then return end
  script.on_nth_tick(1,nil)
  storage.assertions=0
  local force=game.create_force("overcharged-research")
  storage.force=force
  storage.peer=game.create_force("overcharged-peer")
  local surface=game.surfaces.nauvis
  surface.request_to_generate_chunks({64,0},5);surface.force_generate_chunk_requests()
  for _,e in ipairs(surface.find_entities_filtered{area={{-16,-16},{180,80}}}) do e.destroy() end
  local tiles={}
  for x=-16,180 do for y=-16,80 do tiles[#tiles+1]={name="landfill",position={x,y}} end end
  surface.set_tiles(tiles,true)
  force.technologies["nullius-primitive-filtration"].researched=true
  force.technologies["nullius-automation-2"].researched=true
  for _,spec in ipairs(specs) do
    force.recipes[spec.base].enabled=true
    storage.peer.recipes[spec.base].enabled=true
  end
  local prerequisites=force.technologies[tech(2)].prerequisites
  check(prerequisites["nullius-primitive-filtration"]~=nil and prerequisites["nullius-automation-2"]~=nil,"tier 2 prerequisites")
  prerequisites=force.technologies[tech(3)].prerequisites
  check(prerequisites[tech(2)]~=nil and prerequisites["nullius-automation-3"]~=nil,"tier 3 prerequisites")
  check(not force.technologies[tech(2)].researched and not force.technologies[tech(3)].researched,"premature research")
  gates(force,1)
  local old_ghost=assert(surface.create_entity{name="entity-ghost",
    inner_name="nullius-small-assembler-2-overcharged",position={0,60},force=force})
  old_ghost.revive{raise_revive=true}
  local revived=surface.find_entity("nullius-small-assembler-2",{0,60})
  check(revived~=nil,"revived ghost bypass")
  revived.destroy()
  -- Given a legacy placed variant, leaving its mode is always allowed.
  local legacy=assert(place(surface,"nullius-small-assembler-2-overcharged",{0,60},force))
  toggle(legacy,"nullius-small-assembler-2").destroy()
  -- A native clone into another force must obey the destination force's gate.
  local source=assert(place(surface,"nullius-medium-assembler-2-overcharged",{16,60},force))
  source.clone{position={32,60},surface=surface,force=storage.peer}
  check(surface.find_entity("nullius-medium-assembler-2",{32,60})~=nil,"clone bypass")
  source.destroy()
  local vulcanus=game.planets["nullius-vulcanus"].create_surface()
  vulcanus.request_to_generate_chunks({0,0},1);vulcanus.force_generate_chunk_requests()
  force.technologies["nullius-pneumatic-technology"].researched=true
  local machine=assert(place(vulcanus,"nullius-small-assembler-2",{0,0},force))
  machine=toggle(machine,"nullius-small-assembler-2-pneumatic")
  toggle(machine,"nullius-small-assembler-2").destroy()
  research(2,10,{["nullius-electromagnetic-pack"]=20,["nullius-mechanical-pack"]=4,["nullius-electrical-pack"]=4})
end)
script.on_nth_tick(3300,function()
  if game.tick==0 then return end
  script.on_nth_tick(3300,nil)
  local force=storage.force
  check(force.technologies[tech(2)].researched,"tier 2 lab research stalled")
  check(not force.technologies[tech(3)].researched,"tier 2 unlocked tier 3")
  gates(force,2);gates(storage.peer,1)
  force.recipes["nullius-large-assembler-1"].enabled=false
  local machine=assert(place(game.surfaces.nauvis,"nullius-large-assembler-1",{0,60},force))
  toggle(machine,"nullius-large-assembler-1").destroy()
  force.technologies["nullius-mass-production-3"].researched=true
  machine=assert(place(game.surfaces.nauvis,"nullius-large-assembler-1",{0,60},force))
  toggle(machine,"nullius-large-assembler-1-overcharged").destroy()
  local vulcanus=game.surfaces["nullius-vulcanus"]
  machine=assert(place(vulcanus,"nullius-small-assembler-2",{0,0},force))
  machine=toggle(machine,"nullius-small-assembler-2-pneumatic")
  machine=toggle(machine,"nullius-small-assembler-2-overcharged")
  toggle(machine,"nullius-small-assembler-2").destroy()
  force.technologies["nullius-automation-3"].researched=true
  research(3,20,{["nullius-electromagnetic-pack"]=40,["nullius-mechanical-pack"]=8,
    ["nullius-electrical-pack"]=8,["nullius-chemical-pack"]=16,["nullius-physics-pack"]=8})
end)
script.on_nth_tick(8000,function()
  if game.tick==0 then return end
  check(storage.force.technologies[tech(3)].researched,"tier 3 lab research stalled")
  gates(storage.force,3);gates(storage.peer,1)
  helpers.write_file("factorio-tests/overcharged-research.json",helpers.table_to_json{
    schema=1,case="overcharged-research",status="pass",failure_count=0,assertions=storage.assertions,
    tick=game.tick,factorio_version=script.active_mods.base},false)
end)

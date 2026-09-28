-- given: five recipe batches per allowed machine; twenty loose packs for packing;
-- unlocked ordinary machines, Overcharged Assembly 2/3, and unlimited electricity.
-- place: every overcharged size/tier on Fulgora and Nauvis, plus packing machines.
-- connect: native recipe-selection circuits and electric substations.
-- act: research each unlock; select recipes; transfer produced boxes to unpackers.
-- run: 10000 ticks.
-- expect: surface, tier and size gates; exact productivity yields; lossless packing.
local specs=require("__nullius-star__/shared/overcharged-assemblers")
local input=require("__nullius-star__/scenarios/inventory-api").crafting_input
local pack="nullius-electromagnetic-pack"
local box="nullius-box-electromagnetic-pack"
local recipes={"nullius-electromagnetic-pack-improved","nullius-boxed-electromagnetic-pack"}
local function check(ok,message)
  storage.assertions=storage.assertions+1;assert(ok,message)
end
local function place(surface,name,x,y)
  return assert(surface.create_entity{name=name,position={x,y},force=storage.force})
end
local function power(surface,x,y)
  local grid=place(surface,"factorio-test-planner-grid",x+6,y+5)
  grid.power_production=10000000000;grid.electric_buffer_size=10000000000
  place(surface,"substation",x+6,y)
end
script.on_nth_tick(1,function()
  if game.tick==0 then return end
  script.on_nth_tick(1,nil)
  storage.assertions=0;storage.cells={};storage.unpackers={}
  local force=game.create_force("em-upgrades");storage.force=force
  force.technologies["nullius-primitive-filtration"].researched=true
  for _,name in ipairs({recipes[1],recipes[2],box,"nullius-unbox-electromagnetic-pack"}) do
    check(not force.recipes[name].enabled,"premature unlock "..name)
  end
  force.technologies["nullius-overcharged-assembly-2"].researched=true
  check(force.recipes[recipes[1]].enabled,"improved unlock")
  check(not force.recipes[recipes[2]].enabled and not force.recipes[box].enabled,"tier 2 bulk unlock")
  force.technologies["nullius-overcharged-assembly-3"].researched=true
  for _,name in ipairs({recipes[2],box,"nullius-unbox-electromagnetic-pack"}) do
    check(force.recipes[name].enabled,"boxed unlock "..name)
  end
  for _,spec in ipairs(specs) do force.recipes[spec.base].enabled=true end
  for _,name in ipairs({box,"nullius-unbox-electromagnetic-pack"}) do
    check(prototypes.recipe[name].maximum_productivity==0,"packing productivity loop")
  end
  for _,surface in ipairs({game.surfaces.nauvis,game.planets["nullius-fulgora"].create_surface()}) do
    surface.ignore_surface_conditions=false
    surface.request_to_generate_chunks({64,0},5);surface.force_generate_chunk_requests()
    for _,e in ipairs(surface.find_entities_filtered{area={{-16,-16},{170,90}}}) do e.destroy() end
    local tiles={}
    for x=-16,170 do for y=-16,90 do tiles[#tiles+1]={name="fulgoran-rock",position={x,y}} end end
    surface.set_tiles(tiles,true)
    for i,spec in ipairs(specs) do for step,recipe in ipairs(recipes) do
      local x,y=(i-1)*20,(step-1)*24
      local machine=place(surface,spec.base.."-overcharged",x,y)
      power(surface,x,y)
      local allowed=surface.name=="nullius-fulgora" and (step==1 and spec.tier>=2 or
        step==2 and spec.tier==3 and spec.base~="nullius-small-assembler-3")
      machine.get_or_create_control_behavior().circuit_set_recipe=true
      local signal=place(surface,"constant-combinator",x-5,y)
      local behavior=signal.get_or_create_control_behavior()
      local section=behavior.get_section(1) or behavior.add_section()
      section.set_slot(1,{value={type="recipe",name=recipe,quality="normal"},min=1})
      local red=defines.wire_connector_id.circuit_red
      check(machine.get_wire_connector(red,true).connect_to(signal.get_wire_connector(red,true)),"wire")
      storage.cells[#storage.cells+1]={machine=machine,allowed=allowed,tier=spec.tier,step=step}
      local category="nullius-electromagnetism-"..(step+1)
      check(not prototypes.entity[spec.base].crafting_categories[category],"ordinary category leak")
      check(not prototypes.entity[spec.base.."-pneumatic"].crafting_categories[category],"pneumatic category leak")
    end end
    if surface.name=="nullius-fulgora" then
      local boxing=place(surface,"nullius-small-assembler-3-overcharged",0,55)
      boxing.set_recipe(box);power(surface,0,55)
      check(boxing.get_inventory(input).insert{name=pack,count=20}==20,"packing fixture")
      storage.boxing=boxing
    end
  end
end)
script.on_nth_tick(60,function()
  if game.tick==0 then return end
  script.on_nth_tick(60,nil)
  for _,row in ipairs(storage.cells) do
    local recipe=row.machine.get_recipe()
    check((recipe~=nil)==row.allowed,"native gate "..row.machine.name.." "..row.step.." "..row.machine.surface.name)
    if row.allowed then
      check(recipe.name==recipes[row.step],"recipe selected")
      for _,ingredient in pairs(recipe.ingredients) do
        local count=ingredient.amount*5
        check(row.machine.get_inventory(input).insert{name=ingredient.name,count=count}==count,"input fixture")
      end
    end
  end
end)
script.on_nth_tick(8000,function()
  if game.tick==0 then return end
  script.on_nth_tick(8000,nil)
  local function unpack(machine,count,x)
    local output=machine.get_output_inventory()
    check(output.remove{name=box,count=count}==count,"transfer boxes")
    local target=place(machine.surface,"nullius-small-assembler-3-overcharged",x,70)
    target.set_recipe("nullius-unbox-electromagnetic-pack");power(machine.surface,x,70)
    check(target.get_inventory(input).insert{name=box,count=count}==count,"receive boxes")
    storage.unpackers[#storage.unpackers+1]={machine=target,expected=count*5}
  end
  local x=0
  for _,row in ipairs(storage.cells) do
    local expected=row.allowed and (25+5*row.tier) or 0
    check(row.machine.get_output_inventory().get_item_count(row.step==1 and pack or box)==expected,"productive output")
    check(row.machine.get_inventory(input).is_empty(),"remaining ingredients")
    if row.allowed and row.step==2 then unpack(row.machine,expected,x);x=x+20 end
  end
  check(storage.boxing.get_output_inventory().get_item_count(box)==4,"packing multiplied science")
  unpack(storage.boxing,4,x)
end)
script.on_nth_tick(10000,function()
  if game.tick==0 then return end
  for _,row in ipairs(storage.unpackers) do
    check(row.machine.get_output_inventory().get_item_count(pack)==row.expected,"unpacking changed pack count")
    check(row.machine.bonus_progress==0,"unpacking accrued productivity")
  end
  helpers.write_file("factorio-tests/fulgora-em-upgrades.json",helpers.table_to_json{
    schema=1,case="fulgora-em-upgrades",status="pass",failure_count=0,assertions=storage.assertions,
    tick=game.tick,factorio_version=script.active_mods.base},false)
end)

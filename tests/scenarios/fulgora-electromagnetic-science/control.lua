-- given: ten batches per overcharged assembler; three batches for mode switching.
-- place: all eight variants on Fulgora, and gated cells on Nauvis and Fulgora.
-- connect: declared unlimited electricity and recipe-selection signals.
-- act: unlock Primitive Filtration and select EM science through circuits.
-- run: 30000 ticks.
-- expect: native tier productivity, planet/category gates and lab acceptance.
local name = "nullius-electromagnetic-pack"
local category = "nullius-electromagnetism-1"
local specs = require("__nullius-star__/shared/overcharged-assemblers")
local input = require("__nullius-star__/scenarios/inventory-api").crafting_input
local function check(ok, message)
  storage.assertions = storage.assertions + 1
  assert(ok, message)
end
local function place(surface, entity, x, y)
  return assert(surface.create_entity{name=entity,position={x,y},force=storage.force})
end
local function cell(surface, entity, x, y, allowed, tier)
  local machine = place(surface, entity, x, y)
  local grid = place(surface, "factorio-test-planner-grid", x+6, y+4)
  grid.power_production=10000000000; grid.electric_buffer_size=10000000000
  place(surface,"substation",x+6,y)
  machine.get_or_create_control_behavior().circuit_set_recipe=true
  local signal=place(surface,"constant-combinator",x-4,y)
  local behavior=signal.get_or_create_control_behavior()
  local section=behavior.get_section(1) or behavior.add_section()
  section.set_slot(1,{value={type="recipe",name=name,quality="normal"},min=1})
  local red=defines.wire_connector_id.circuit_red
  check(machine.get_wire_connector(red,true).connect_to(signal.get_wire_connector(red,true)),"wire")
  storage.cells[#storage.cells+1]={machine=machine,allowed=allowed,tier=tier}
  return machine
end
script.on_nth_tick(1,function()
  if game.tick==0 then return end
  script.on_nth_tick(1,nil)
  storage.assertions=0; storage.cells={}
  storage.force=game.create_force("em-test")
  local force=storage.force
  check(not force.recipes[name].enabled,"premature unlock")
  force.technologies["nullius-primitive-filtration"].researched=true
  check(force.recipes[name].enabled,"filtration unlock")
  force.technologies["nullius-overcharged-assembly-2"].researched=true
  force.technologies["nullius-overcharged-assembly-3"].researched=true
  for _,spec in ipairs(specs) do force.recipes[spec.base].enabled=true end
  check(prototypes.recipe[name].allowed_effects.productivity,"productivity disabled")
  check(not prototypes.item["nullius-box-electromagnetic-pack"],"premature boxed pack")
  check(not prototypes.recipe["nullius-boxed-electromagnetic-pack"],"premature boxed recipe")
  for _,lab in ipairs({"nullius-hidden-lab","nullius-lab-1","nullius-lab-2","nullius-lab-3"}) do
    local accepts=false
    for _,pack in pairs(prototypes.entity[lab].lab_inputs) do if pack==name then accepts=true end end
    check(accepts,lab.." cannot consume EM")
  end
  for _,surface in ipairs({game.surfaces.nauvis,game.planets["nullius-fulgora"].create_surface()}) do
    surface.ignore_surface_conditions=false
    surface.request_to_generate_chunks({64,0},5);surface.force_generate_chunk_requests()
    for _,e in pairs(surface.find_entities_filtered{area={{-16,-16},{164,64}}}) do e.destroy() end
    local tiles={}
    for x=-16,164 do for y=-16,64 do tiles[#tiles+1]={name="fulgoran-rock",position={x,y}} end end
    surface.set_tiles(tiles,true)
    local fulgora=surface.name=="nullius-fulgora"
    for i,spec in ipairs(specs) do
      check(not prototypes.entity[spec.base].crafting_categories[category],"ordinary category leak")
      cell(surface,spec.base.."-overcharged",(i-1)*20,0,fulgora,spec.tier)
    end
    cell(surface,"nullius-small-assembler-1",0,20,false)
    if fulgora then
      storage.switching=cell(surface,"nullius-small-assembler-1-overcharged",30,20,true,1)
      storage.cells[#storage.cells].batches=3
      local ghost=surface.create_entity{name="entity-ghost",inner_name="nullius-small-assembler-1-overcharged",position={60,20},force=force}
      ghost.set_recipe(name)
      check(remote.call("nullius-test-transitions","execute",ghost),"ghost switch")
      local replacement=surface.find_entities_filtered{type="entity-ghost",position={60,20}}[1]
      check(replacement.ghost_name=="nullius-small-assembler-1","ghost mode")
      check(not replacement.get_recipe(),"ghost retained incompatible recipe")
    end
  end
end)
script.on_nth_tick(60,function()
  if game.tick==0 then return end
  script.on_nth_tick(60,nil)
  for _,row in ipairs(storage.cells) do
    local recipe=row.machine.get_recipe()
    check((recipe~=nil)==row.allowed,"native selection "..row.machine.name.." on "..row.machine.surface.name)
    if row.allowed then
      check(recipe.name==name,"selected wrong recipe")
      for _,ingredient in pairs(recipe.ingredients) do
        local count=ingredient.amount*(row.batches or 10)
        check(row.machine.get_inventory(input).insert{name=ingredient.name,count=count}==count,"fixture stock")
      end
    end
  end
end)
script.on_nth_tick(660,function()
  if game.tick==0 then return end
  script.on_nth_tick(660,nil)
  local machine=storage.switching
  check(machine.crafting_progress>0 and machine.crafting_progress<1,"switch must interrupt a paid craft")
  machine.get_or_create_control_behavior().circuit_set_recipe=false
  check(remote.call("nullius-test-transitions","execute",machine),"live switch")
  local ordinary=assert(game.surfaces["nullius-fulgora"].find_entity("nullius-small-assembler-1",{30,20}))
  check(not ordinary.get_recipe(),"ordinary retained exclusive recipe")
  check(ordinary.crafting_progress==0 and ordinary.bonus_progress==0,"incompatible craft progress retained")
  check(remote.call("nullius-test-transitions","execute",ordinary),"switch back")
  storage.switching=assert(game.surfaces["nullius-fulgora"].find_entity("nullius-small-assembler-1-overcharged",{30,20}))
  storage.switching.set_recipe(name)
  local refunded={}
  for _,item in ipairs(storage.switching.surface.find_entities_filtered{type="item-entity"}) do
    local stack=item.stack
    refunded[stack.name]=(refunded[stack.name] or 0)+stack.count
    check(storage.switching.get_inventory(input).insert(stack)==stack.count,"refund pickup")
    item.destroy()
  end
  for _,ingredient in pairs(prototypes.recipe[name].ingredients) do
    check(refunded[ingredient.name]==ingredient.amount*3,"cancelled recipe refund "..ingredient.name)
  end
end)
script.on_nth_tick(30000,function()
  if game.tick==0 then return end
  for _,row in ipairs(storage.cells) do
    if not row.batches then
      local expected=row.allowed and (10+2*row.tier) or 0
      check(row.machine.get_output_inventory().get_item_count(name)==expected,"native yield "..row.machine.name.." on "..row.machine.surface.name.." count="..row.machine.get_output_inventory().get_item_count(name).." progress="..row.machine.crafting_progress.." bonus="..row.machine.bonus_progress)
      check(row.machine.get_inventory(input).is_empty(),"unconsumed inputs")
    end
  end
  check(storage.switching.get_output_inventory().get_item_count(name)==3,"interrupted craft ingredients lost or duplicated")
  helpers.write_file("factorio-tests/fulgora-electromagnetic-science.json",helpers.table_to_json{
    schema=1,case="fulgora-electromagnetic-science",status="pass",failure_count=0,
    assertions=storage.assertions,tick=game.tick,factorio_version=script.active_mods.base},false)
end)

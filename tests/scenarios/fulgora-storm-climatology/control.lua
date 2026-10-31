-- given: exact ingredients for one ordinary and one boxed craft, debug electricity.
-- place: chemical plants on Fulgora and Nauvis with finite fluid inputs.
-- act: unlock each recipe through its research and select it on each surface.
-- expect: one product per Fulgora craft; no crafts on Nauvis.
local CASE = "fulgora-storm-climatology"
local specs = {
  {recipe="nullius-climatology-pack-fulgora-2", tech="nullius-storm-climatology", machine="nullius-chemical-plant-2", product="nullius-climatology-pack", seconds=10,
    inputs={{"nullius-nitrogen",200},{"nullius-ammonia",5},{"nullius-hydrocarbon-slurry",20}}},
  {recipe="nullius-boxed-climatology-pack-fulgora-2", tech="nullius-bulk-storm-climatology", machine="nullius-chemical-plant-2", product="nullius-box-climatology-pack", seconds=50,
    inputs={{"nullius-nitrogen",1000},{"nullius-ammonia",25},{"nullius-hydrocarbon-slurry",100}}},
}
local function check(ok, message)
  storage.assertions = storage.assertions + 1
  if not ok then storage.failures[#storage.failures+1] = message end
end
local function finish()
  local result={schema=1,case=CASE,factorio_version=script.active_mods.base,status=#storage.failures==0 and "pass" or "fail",tick=game.tick,
    assertions=storage.assertions,failure_count=#storage.failures,failures=storage.failures,
    observations={recipes=2,cycles_per_recipe=1}}
  helpers.write_file("factorio-tests/"..CASE..".json",helpers.table_to_json(result),false)
  script.on_nth_tick(30,nil)
  if #storage.failures>0 then error(helpers.table_to_json(result)) end
end
script.on_nth_tick(30,function()
  if not storage.rows then
    storage.rows={};storage.failures={};storage.assertions=0
    local force=game.create_force("science-tier2-test")
    force.technologies["nullius-climatology-2"].researched=true
    force.technologies["nullius-mass-production-7"].researched=true
    local bulk=force.technologies["nullius-bulk-storm-climatology"]
    check(bulk.prerequisites["nullius-mass-production-7"]~=nil,"bulk requires Mass Production 7")
    check(bulk.prerequisites["nullius-storm-climatology"]~=nil,"bulk requires ordinary storm research")
    check(bulk.prerequisites["nullius-overcharged-assembly-2"]~=nil,"bulk requires later EM research")
    for _,spec in ipairs(specs) do
      force.technologies[spec.tech].researched=false
      check(not force.recipes[spec.recipe].enabled,"recipe enabled before research: "..spec.recipe)
      force.technologies[spec.tech].researched=true
      check(force.recipes[spec.recipe].enabled,"missing unlock: "..spec.recipe)
      local recipe=prototypes.recipe[spec.recipe]
      check(#recipe.surface_conditions==1 and recipe.surface_conditions[1].property=="magnetic-field" and recipe.surface_conditions[1].min==99 and recipe.surface_conditions[1].max==99,"magnetic field: "..spec.recipe)
      check(recipe.energy==spec.seconds,"craft time: "..spec.recipe)
      check(#recipe.ingredients==#spec.inputs,"ingredient count: "..spec.recipe)
      for _,input in ipairs(spec.inputs) do
        local found=false
        for _,ingredient in pairs(recipe.ingredients) do
          if ingredient.name==input[1] and ingredient.amount==input[2] then found=true end
        end
        check(found,"ingredient quantity: "..spec.recipe.." "..input[1])
      end
      check(#recipe.products==1 and recipe.products[1].name==spec.product and recipe.products[1].amount==1,"output: "..spec.recipe)
    end
    local planet=game.planets["nullius-fulgora"]
    local surface=planet.surface or planet.create_surface()
    surface.request_to_generate_chunks({0,0},3);surface.force_generate_chunk_requests()
    for _,surface in ipairs({surface,game.surfaces.nauvis}) do
    surface.ignore_surface_conditions=false
    surface.request_to_generate_chunks({0,0},3);surface.force_generate_chunk_requests()
    for i,spec in ipairs(specs) do
      local x=i*20
      local tiles={}
      for dx=-6,6 do for dy=-6,6 do tiles[#tiles+1]={name="fulgoran-rock",position={x+dx,dy}} end end
      surface.set_tiles(tiles,true,false,false,false)
      for _,e in pairs(surface.find_entities_filtered{area={{x-7,-7},{x+7,7}}}) do e.destroy() end
      local machine=surface.create_entity{name=spec.machine,position={x,0},force=force}
      check(machine~=nil,"placement: "..spec.machine)
      machine.get_or_create_control_behavior().circuit_set_recipe=true
      local signal=assert(surface.create_entity{name="constant-combinator",position={x-4,0},force=force})
      local behavior=signal.get_or_create_control_behavior()
      local section=behavior.get_section(1) or behavior.add_section()
      section.set_slot(1,{value={type="recipe",name=spec.recipe,quality="normal"},min=1})
      local red=defines.wire_connector_id.circuit_red
      check(machine.get_wire_connector(red,true).connect_to(signal.get_wire_connector(red,true)),"recipe wire")
      local power=assert(surface.create_entity{name="factorio-test-planner-grid",position={x,8},force=force})
      power.power_production=100000000; power.electric_buffer_size=100000000
      assert(surface.create_entity{name="substation",position={x,5},force=force})
      storage.rows[#storage.rows+1]={machine=machine,product=spec.product,recipe=spec.recipe,inputs=spec.inputs,
        expected=surface.name=="nauvis" and 0 or 1}
    end
    end
  end
  if game.tick==60 then
    for _,row in ipairs(storage.rows) do
      local recipe=row.machine.get_recipe()
      check((recipe~=nil)==(row.expected==1),"surface selection: "..row.machine.surface.name)
      if row.expected==1 then
        check(recipe and recipe.name==row.recipe,"recipe selection")
        for _,input in ipairs(row.inputs) do
          check(row.machine.insert_fluid{name=input[1],amount=input[2]}==input[2],"finite fluid stock")
        end
      end
    end
  end
  if game.tick>=2400 then
    for _,row in ipairs(storage.rows) do
      check(row.machine.products_finished==row.expected,"completed one craft: "..row.product.." status="..row.machine.status.." progress="..row.machine.crafting_progress.." crafts="..row.machine.products_finished)
      check(row.machine.get_output_inventory().get_item_count(row.product)==row.expected,"crafted output: "..row.product)
    end
    finish()
  end
end)

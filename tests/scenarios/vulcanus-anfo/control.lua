-- given: one batch of each recipe's ingredients and 5000 fuel gas per plant.
-- place: two tier-1 pneumatic chemical plants on Vulcanus.
-- connect: three input pipes and one wastewater pipe per plant; delay SO2 to tick 600.
-- act: research ordinary and bulk unlocks independently.
-- run: 2400 ticks with finite fuel and ingredient supplies.
-- expect: no early craft, then one explosive or box and exact wastewater output.
local CASE = "vulcanus-anfo"
local specs = {
  {recipe="nullius-anfo-explosive", tech="nullius-explosives-2", product="cliff-explosives", scale=1, prefix="nullius-"},
  {recipe="nullius-boxed-anfo-explosive", tech="nullius-mass-production-6", product="nullius-box-explosive", scale=5, prefix="nullius-box-"},
}
local function check(ok, message)
  storage.assertions = storage.assertions + 1
  if not ok then storage.failures[#storage.failures+1] = message end
end
local function build(surface, force, name, x, y)
  local entity=surface.create_entity{name=name,position={x,y},force=force}
  assert(entity, "Cannot place " .. name)
  return entity
end
local function finish()
  local result={schema=1,case=CASE,status=#storage.failures==0 and "pass" or "fail",tick=game.tick,
    assertions=storage.assertions,failure_count=#storage.failures,failures=storage.failures,
    observations={cycles_per_recipe=1,connection_tick=600,fuel_per_machine=5000}}
  helpers.write_file("factorio-tests/"..CASE..".json",helpers.table_to_json(result),false)
  script.on_nth_tick(30,nil)
  if #storage.failures>0 then error(helpers.table_to_json(result)) end
end
script.on_nth_tick(30,function()
  if not storage.rows then
    storage.rows={};storage.failures={};storage.assertions=0
    local force=game.create_force("anfo-test")
    for _,spec in ipairs(specs) do
      check(not force.recipes[spec.recipe].enabled,"starts locked: "..spec.recipe)
    end
    force.technologies[specs[1].tech].researched=true
    check(force.recipes[specs[1].recipe].enabled,"ordinary unlock")
    check(not force.recipes[specs[2].recipe].enabled,"bulk remains locked")
    force.technologies[specs[2].tech].researched=true
    check(force.recipes[specs[2].recipe].enabled,"bulk unlock")
    local planet=game.planets["nullius-vulcanus"]
    local surface=planet.surface or planet.create_surface()
    surface.request_to_generate_chunks({0,0},3);surface.force_generate_chunk_requests()
    storage.surface=surface;storage.force=force
    for i,spec in ipairs(specs) do
      local x=i*20
      local tiles={}
      for dx=-7,7 do for dy=-7,7 do tiles[#tiles+1]={name="volcanic-soil-dark",position={x+dx,dy}} end end
      surface.set_tiles(tiles,true,false,false,false)
      for _,e in pairs(surface.find_entities_filtered{area={{x-7,-7},{x+7,7}}}) do e.destroy() end
      local machine=build(surface,force,"nullius-chemical-plant-1-pneumatic",x,0)
      check(machine.set_recipe(spec.recipe)~=nil,"select recipe: "..spec.recipe)
      local recipe=prototypes.recipe[spec.recipe]
      check(recipe.energy==4*spec.scale,"base time: "..spec.recipe)
      check(#recipe.ingredients==6,"six ingredients: "..spec.recipe)
      check(#recipe.products==2,"two products: "..spec.recipe)
      for _,input in ipairs({{"aluminum-powder",4},{"iron-oxide",2},{"red-wire",1}}) do
        check(machine.insert{name=spec.prefix..input[1],count=input[2]}==input[2],"solid input: "..input[1])
      end
      local ammonia=build(surface,force,"pipe",x-1,-2)
      local acid=build(surface,force,"pipe",x+1,-2)
      local output=build(surface,force,"pipe",x-1,2)
      check(ammonia.insert_fluid{name="nullius-ammonia",amount=30*spec.scale}==30*spec.scale,"ammonia supply")
      check(acid.insert_fluid{name="nullius-acid-nitric",amount=20*spec.scale}==20*spec.scale,"acid supply")
      storage.rows[#storage.rows+1]={machine=machine,output=output,x=x,product=spec.product,scale=spec.scale,fuel_left=5000}
    end
  end
  for _,row in ipairs(storage.rows) do
    row.fuel_left=row.fuel_left-row.machine.insert_fluid{name="nullius-compressed-volcanic-gas",amount=row.fuel_left}
    if game.tick==600 then
      check(row.machine.products_finished==0,"no craft before SO2 connection")
      local pipe=build(storage.surface,storage.force,"pipe",row.x-2,0)
      check(pipe.insert_fluid{name="nullius-sulfur-dioxide",amount=20*row.scale}==20*row.scale,"SO2 supply")
    end
  end
  if game.tick>=2400 then
    for _,row in ipairs(storage.rows) do
      check(row.machine.products_finished==1,"one craft: "..row.product.." status="..row.machine.status)
      check(row.machine.get_output_inventory().get_item_count(row.product)==1,"one product: "..row.product)
      check(row.machine.get_inventory(defines.inventory.assembling_machine_input).is_empty(),"all solids consumed")
      local fluids=row.output.get_fluid_contents()
      check(math.abs((fluids["nullius-wastewater"] or 0)-16*row.scale)<0.001,"connected wastewater output")
      check(row.fuel_left<5000,"fuel supplied")
    end
    finish()
  end
end)

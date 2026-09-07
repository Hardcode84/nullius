-- given: exact ingredients for one craft per recipe and 5000 gas per machine.
-- place: four independent pneumatic science machines on Vulcanus.
-- connect: deliver declared fluid stock to each machine's matching fluid box.
-- act: check locked recipes, then research each declared unlock.
-- run: 2400 ticks, feeding fuel from the finite declared stock.
-- expect: one craft and two output items or boxes from each machine.
local CASE = "vulcanus-science-tier2"
local specs = {
  {recipe="nullius-geology-pack-vulcanus-2", tech="nullius-geology-2", machine="nullius-medium-assembler-2-pneumatic", product="nullius-geology-pack", seconds=10,
    inputs={{"nullius-glass",1},{"nullius-lime",1},{"nullius-mineral-dust",2}}},
  {recipe="nullius-boxed-geology-pack-vulcanus-2", tech="nullius-mass-production-7", machine="nullius-large-assembler-1-pneumatic", product="nullius-box-geology-pack", seconds=50,
    inputs={{"nullius-box-glass",1},{"nullius-box-lime",1},{"nullius-box-mineral-dust",2}}},
  {recipe="nullius-climatology-pack-vulcanus-2", tech="nullius-climatology-2", machine="nullius-chemical-plant-2-pneumatic", product="nullius-climatology-pack", seconds=10,
    inputs={{"nullius-compressed-carbon-dioxide",100},{"nullius-compressed-nitrogen",10},{"nullius-acid-sulfuric",5}}},
  {recipe="nullius-boxed-climatology-pack-vulcanus-2", tech="nullius-mass-production-7", machine="nullius-chemical-plant-2-pneumatic", product="nullius-box-climatology-pack", seconds=50,
    inputs={{"nullius-compressed-carbon-dioxide",500},{"nullius-compressed-nitrogen",50},{"nullius-acid-sulfuric",25}}},
}
local function check(ok, message)
  storage.assertions = storage.assertions + 1
  if not ok then storage.failures[#storage.failures+1] = message end
end
local function finish()
  local result={schema=1,case=CASE,status=#storage.failures==0 and "pass" or "fail",tick=game.tick,
    assertions=storage.assertions,failure_count=#storage.failures,failures=storage.failures,
    observations={recipes=4,cycles_per_recipe=1,declared_fuel_per_machine=5000}}
  helpers.write_file("factorio-tests/"..CASE..".json",helpers.table_to_json(result),false)
  script.on_nth_tick(30,nil)
  if #storage.failures>0 then error(helpers.table_to_json(result)) end
end
script.on_nth_tick(30,function()
  if not storage.rows then
    storage.rows={};storage.failures={};storage.assertions=0
    local force=game.create_force("science-tier2-test")
    for _,spec in ipairs(specs) do
      force.technologies[spec.tech].researched=false
      check(not force.recipes[spec.recipe].enabled,"recipe enabled before research: "..spec.recipe)
      force.technologies[spec.tech].researched=true
      check(force.recipes[spec.recipe].enabled,"missing unlock: "..spec.recipe)
      local recipe=prototypes.recipe[spec.recipe]
      check(#recipe.surface_conditions==1 and recipe.surface_conditions[1].property=="nullius-ambient-temperature" and recipe.surface_conditions[1].min==100,"hot surface: "..spec.recipe)
      check(recipe.energy==spec.seconds,"craft time: "..spec.recipe)
      check(#recipe.ingredients==#spec.inputs,"ingredient count: "..spec.recipe)
      for _,input in ipairs(spec.inputs) do
        local found=false
        for _,ingredient in pairs(recipe.ingredients) do
          if ingredient.name==input[1] and ingredient.amount==input[2] then found=true end
        end
        check(found,"ingredient quantity: "..spec.recipe.." "..input[1])
      end
      check(#recipe.products==1 and recipe.products[1].name==spec.product and recipe.products[1].amount==2,"output: "..spec.recipe)
    end
    local planet=game.planets["nullius-vulcanus"]
    local surface=planet.surface or planet.create_surface()
    surface.request_to_generate_chunks({0,0},3);surface.force_generate_chunk_requests()
    for i,spec in ipairs(specs) do
      local x=i*20
      local tiles={}
      for dx=-6,6 do for dy=-6,6 do tiles[#tiles+1]={name="volcanic-soil-dark",position={x+dx,dy}} end end
      surface.set_tiles(tiles,true,false,false,false)
      for _,e in pairs(surface.find_entities_filtered{area={{x-7,-7},{x+7,7}}}) do e.destroy() end
      local machine=surface.create_entity{name=spec.machine,position={x,0},force=force}
      check(machine~=nil,"placement: "..spec.machine)
      check(machine.set_recipe(spec.recipe),"select recipe: "..spec.recipe)
      for _,input in ipairs(spec.inputs) do
        if prototypes.fluid[input[1]] then
          local assigned=false
          for index=1,#machine.fluidbox do
            local filter=machine.fluidbox.get_filter(index)
            if filter and filter.name==input[1] then
              machine.fluidbox[index]={name=input[1],amount=input[2]};assigned=true
            end
          end
          check(assigned,"fluid port: "..input[1])
        else check(machine.insert{name=input[1],count=input[2]}==input[2],"insert: "..input[1]) end
      end
      local fuel_index
      for index=1,#machine.fluidbox do
        if not machine.fluidbox.get_filter(index) then
          fuel_index=index
        end
      end
      check(fuel_index~=nil,"fuel port: "..spec.recipe)
      storage.rows[#storage.rows+1]={machine=machine,product=spec.product,fuel_index=fuel_index,fuel_left=5000}
    end
  end
  for _,row in ipairs(storage.rows) do
    local fluid=row.machine.fluidbox[row.fuel_index]
    local amount=fluid and fluid.amount or 0
    local added=math.min(row.fuel_left,row.machine.fluidbox.get_capacity(row.fuel_index)-amount)
    row.machine.fluidbox[row.fuel_index]={name="nullius-compressed-volcanic-gas",amount=amount+added}
    row.fuel_left=row.fuel_left-added
  end
  if game.tick>=2400 then
    for _,row in ipairs(storage.rows) do
      check(row.machine.products_finished==1,"completed one craft: "..row.product.." status="..row.machine.status.." progress="..row.machine.crafting_progress.." crafts="..row.machine.products_finished)
      check(row.machine.get_output_inventory().get_item_count(row.product)==2,"crafted output: "..row.product)
    end
    finish()
  end
end)

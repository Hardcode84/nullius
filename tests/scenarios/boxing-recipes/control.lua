-- given: exactly one boxing batch per pair and void power
-- place: one boxer and four unboxers per pair
-- connect: transfer only the four crafted boxes at tick 90
-- act: box the input, then unbox all boxes
-- run: 180 ticks
-- expect: exact round trips, categories, amounts, durations, and box capacities
local boundary_cases=require("__nullius-star__/scenarios/boxing-recipes/fixture")
local modern=require("__nullius-star__/factorio-version").is_2_1
local assertions=0
local function check(ok,message)
  assertions=assertions+1
  assert(ok,message)
end
local function check_recipe(recipe,input,amount,output,count,seconds)
  local categories=modern and recipe.categories or {recipe.category}
  check(#categories==1 and categories[1]=="packaging",recipe.name.." category")
  check(math.abs(recipe.energy-seconds)<0.000001,recipe.name.." duration")
  check(#recipe.ingredients==1 and recipe.ingredients[1].name==input
    and recipe.ingredients[1].type=="item" and recipe.ingredients[1].amount==amount,recipe.name.." input")
  check(#recipe.products==1 and recipe.products[1].name==output
    and recipe.products[1].type=="item" and recipe.products[1].amount==count,recipe.name.." output")
end
script.on_nth_tick(1,function()
  script.on_nth_tick(1,nil)
  local cases={}
  if prototypes.item["nullius-probe-10"] then
    for _,case in ipairs(boundary_cases) do
      cases[#cases+1]={name=case.name,item="nullius-"..case.name,ratio=case.ratio,boxes=case.boxes}
    end
  else
    for name,recipe in pairs(prototypes.recipe) do
      if name:sub(1,14)=="nullius-unbox-" then
        local item=prototypes.item[recipe.products[1].name]
        local size=item.stack_size
        local ratio=size>300 and 10 or 5
        cases[#cases+1]={name=name:sub(15),item=item.name,ratio=ratio}
      end
    end
    check(#cases==258+(script.active_mods["ch-concentrated-solar"] and 1 or 0),"all production boxing pairs: "..#cases)
  end
  table.sort(cases,function(a,b) return a.name<b.name end)
  storage.cases=cases
  local surface=game.create_surface("boxing-test",{width=512,height=256,autoplace_controls={}})
  surface.request_to_generate_chunks({0,0},9)
  surface.force_generate_chunk_requests()
  for _,entity in pairs(surface.find_entities()) do entity.destroy() end
  storage.rows={}
  for i,case in ipairs(cases) do
    local box="nullius-box-"..case.name
    local unbox="nullius-unbox-"..case.name
    if case.boxes then check(prototypes.item[box].stack_size==case.boxes,box.." stack size") end
    check_recipe(prototypes.recipe[box],case.item,4*case.ratio,box,4,1)
    check_recipe(prototypes.recipe[unbox],box,1,case.item,case.ratio,0.2)
    local x=((i-1)%16)*24-192
    local y=math.floor((i-1)/16)*8-68
    local row={}
    for j,name in ipairs({box,unbox,unbox,unbox,unbox}) do
      game.forces.player.recipes[name].enabled=true
      local machine=surface.create_entity{name="factorio-test-boxing",position={x+4*(j-1),y},force="player"}
      machine.set_recipe(name)
      check(machine.get_recipe().name==name,name.." selected")
      row[j]=machine
    end
    check(row[1].insert{name=case.item,count=4*case.ratio}==4*case.ratio,box.." stock")
    storage.rows[i]=row
  end
  storage.assertions=assertions
end)
script.on_nth_tick(90,function(event)
  if event.tick~=90 then return end
  script.on_nth_tick(90,nil)
  assertions=storage.assertions
  for i,case in ipairs(storage.cases) do
    local row=storage.rows[i]
    local box="nullius-box-"..case.name
    check(row[1].products_finished==1,box.." one craft")
    check(row[1].get_output_inventory().get_item_count(box)==4,box.." four boxes")
    check(row[1].get_item_count(case.item)==0,box.." input consumed")
    check(row[1].remove_item{name=box,count=4}==4,box.." transfer out")
    for j=2,5 do check(row[j].insert{name=box,count=1}==1,box.." transfer in") end
  end
  storage.assertions=assertions
end)
script.on_nth_tick(180,function(event)
  if event.tick==0 then return end
  script.on_nth_tick(180,nil)
  assertions=storage.assertions
  for i,case in ipairs(storage.cases) do
    local row=storage.rows[i]
    local total=0
    for j=2,5 do
      check(row[j].products_finished==1,case.name.." one unbox craft")
      total=total+row[j].get_output_inventory().get_item_count(case.item)
      check(row[j].get_item_count("nullius-box-"..case.name)==0,case.name.." box consumed")
    end
    check(total==4*case.ratio,case.name.." exact round trip")
  end
  helpers.write_file("factorio-tests/boxing-recipes.json",helpers.table_to_json({
    schema=1,case="boxing-recipes",status="pass",factorio_version=script.active_mods.base,
    tick=game.tick,assertions=assertions,pairs=#storage.cases,crafts=5*#storage.cases,failure_count=0,failures={}
  }),false)
end)

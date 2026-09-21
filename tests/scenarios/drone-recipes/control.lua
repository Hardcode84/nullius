-- given: one declared recipe batch per recipe and void power
-- place: 50 independent executors at crafting speed 60
-- connect: no external item or fluid supply
-- act: reject the other category, select the recipe, and insert its ingredients
-- run: 600 ticks
-- expect: exact contracts, one complete recipe batch each, and no input left
local cases=require("__nullius-star__/scenarios/drone-recipes/fixture")
for _,case in ipairs(require("__nullius-star__/scenarios/terrain-drone-recipes/fixture")) do
  case.category="huge-crafting"
  case.products={{name=case.name,amount=1}}
  cases[#cases+1]=case
end
local modern=require("__nullius-star__/factorio-version").is_2_1
local assertions=0
local function check(ok,message)
  assertions=assertions+1
  assert(ok,message)
end
local function parts(actual,expected,label)
  check(#actual==#expected,label.." count")
  local amounts={}
  for _,part in ipairs(actual) do
    check(part.type=="item",label.." item")
    amounts[part.name]=part.amount
  end
  for _,part in ipairs(expected) do check(amounts[part.name]==part.amount,label.." "..part.name) end
end
script.on_nth_tick(1,function()
  script.on_nth_tick(1,nil)
  local surface=game.create_surface("drone-test",{width=128,height=96,autoplace_controls={}})
  surface.request_to_generate_chunks({0,0},3)
  surface.force_generate_chunk_requests()
  for _,entity in pairs(surface.find_entities()) do entity.destroy() end
  storage.machines={}
  if script.active_mods["factorio-test-support"] then
    check(prototypes.recipe["nullius-android-1"]==nil,"android recipe renamed")
    for _,case in ipairs(cases) do
      if case.name=="nullius-android-1" then case.name="character" end
    end
  end
  for i,case in ipairs(cases) do
    local recipe=prototypes.recipe[case.name]
    check(recipe~=nil,case.name.." recipe exists")
    local categories=modern and recipe.categories or {recipe.category}
    check(#categories==1 and categories[1]==case.category,case.name.." category")
    check(recipe.energy==case.seconds,case.name.." duration")
    parts(recipe.ingredients,case.ingredients,case.name.." ingredients")
    parts(recipe.products,case.products,case.name.." products")
    game.forces.player.recipes[case.name].enabled=true
    local other="tiny-crafting"
    local position={((i-1)%8)*8-32,math.floor((i-1)/8)*8-20}
    local wrong=surface.create_entity{name="factorio-test-drone-"..other,position=position,force="player"}
    wrong.set_recipe(case.name)
    check(wrong.get_recipe()==nil,case.name.." rejects other category")
    wrong.destroy()
    local machine=surface.create_entity{name="factorio-test-drone-"..case.category,position=position,force="player"}
    machine.set_recipe(case.name)
    check(machine.get_recipe().name==case.name,case.name.." selected")
    for _,part in ipairs(case.ingredients) do
      check(machine.insert{name=part.name,count=part.amount}==part.amount,case.name.." input stock")
    end
    storage.machines[i]=machine
  end
  storage.assertions=assertions
end)
script.on_nth_tick(600,function(event)
  if event.tick==0 then return end
  script.on_nth_tick(600,nil)
  assertions=storage.assertions
  for i,case in ipairs(cases) do
    local machine=storage.machines[i]
    check(machine.products_finished==1,case.name.." one craft: "..machine.products_finished)
    for _,part in ipairs(case.products) do
      check(machine.get_output_inventory().get_item_count(part.name)==part.amount,case.name.." recipe output")
    end
    for _,part in ipairs(case.ingredients) do
      check(machine.get_item_count(part.name)==0,case.name.." consumed "..part.name)
    end
  end
  helpers.write_file("factorio-tests/drone-recipes.json",helpers.table_to_json({
    schema=1,case="drone-recipes",status="pass",factorio_version=script.active_mods.base,
    tick=game.tick,assertions=assertions,recipes=#cases,crafts=#cases,failure_count=0,failures={}
  }),false)
end)

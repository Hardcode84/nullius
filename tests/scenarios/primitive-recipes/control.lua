-- given: one declared batch per recipe, void power, and no modules
-- place: one executor per recipe
-- act: reject the other category, enable the recipe, and insert its batch
-- run: 60 ticks
-- expect: exact recipe contracts, one output each, and no remaining input
local cases=require("__nullius-star__/scenarios/primitive-recipes/fixture")
local modern=require("__nullius-star__/factorio-version").is_2_1
local assertions=0
local function check(ok,message) assertions=assertions+1; assert(ok,message) end
script.on_nth_tick(1,function()
  script.on_nth_tick(1,nil)
  storage.machines={}
  local surface=game.create_surface("primitive-recipes",{width=64,height=64,autoplace_controls={}})
  surface.request_to_generate_chunks({0,0},1)
  surface.force_generate_chunk_requests()
  for _,entity in pairs(surface.find_entities()) do entity.destroy() end
  for i,case in ipairs(cases) do
    local recipe=prototypes.recipe[case.name]
    local categories=modern and recipe.categories or {recipe.category}
    check(#categories==1 and categories[1]==case.category,case.name.." category")
    check(recipe.energy==case.seconds,case.name.." duration")
    check(#recipe.ingredients==#case.ingredients,case.name.." ingredient count")
    local amounts={}
    for _,part in ipairs(recipe.ingredients) do amounts[part.name]=part.amount end
    for _,part in ipairs(case.ingredients) do check(amounts[part.name]==part.amount,case.name.." ingredient "..part.name) end
    check(#recipe.products==1 and recipe.products[1].name==case.name and recipe.products[1].amount==1,case.name.." product")
    game.forces.player.recipes[case.name].enabled=true
    local position={i*6-18,0}
    local wrong=surface.create_entity{name="factorio-test-primitive-rejected",position=position,force="player"}
    wrong.set_recipe(case.name)
    check(wrong.get_recipe()==nil,case.name.." category rejection")
    wrong.destroy()
    local machine=surface.create_entity{name="factorio-test-primitive-"..case.category,position=position,force="player"}
    machine.set_recipe(case.name)
    check(machine.get_recipe().name==case.name,case.name.." selection")
    for _,part in ipairs(case.ingredients) do check(machine.insert{name=part.name,count=part.amount}==part.amount,case.name.." batch insertion") end
    storage.machines[i]=machine
  end
  storage.assertions=assertions
end)
script.on_nth_tick(60,function(event)
  if event.tick==0 then return end
  script.on_nth_tick(60,nil)
  assertions=storage.assertions
  for i,case in ipairs(cases) do
    local machine=storage.machines[i]
    check(machine.products_finished==1,case.name.." one craft")
    check(machine.get_output_inventory().get_item_count(case.name)==1,case.name.." exact output")
    for _,part in ipairs(case.ingredients) do check(machine.get_item_count(part.name)==0,case.name.." input consumed") end
  end
  helpers.write_file("factorio-tests/primitive-recipes.json",helpers.table_to_json({schema=1,case="primitive-recipes",status="pass",factorio_version=script.active_mods.base,tick=game.tick,assertions=assertions,recipes=#cases,crafts=#cases,failure_count=0,failures={}}),false)
end)

-- given: one declared repair batch per recipe and void power
-- place: ten independent executors at native crafting speed 1
-- connect: no external item or fluid supply
-- act: reject the other category, select the repair, and insert its ingredients
-- run: 660 ticks
-- expect: exact contracts, one repaired item each, and no input left
local cases=require("__nullius-star__/scenarios/broken-recipes/fixture")
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
  local surface=game.create_surface("repair-test",{width=128,height=96,autoplace_controls={}})
  surface.request_to_generate_chunks({0,0},3)
  surface.force_generate_chunk_requests()
  for _,entity in pairs(surface.find_entities()) do entity.destroy() end
  storage.machines={}
  for i,case in ipairs(cases) do
    local recipe=prototypes.recipe[case.name]
    local categories=modern and recipe.categories or {recipe.category}
    check(#categories==1 and categories[1]==case.category,case.name.." category")
    check(recipe.energy==case.seconds,case.name.." duration")
    parts(recipe.ingredients,case.ingredients,case.name.." ingredients")
    parts(recipe.products,case.products,case.name.." products")
    check(prototypes.item["nullius-box-"..case.name:sub(9)]==nil,case.name.." no boxed wreck")
    game.forces.player.recipes[case.name].enabled=true
    local other=case.category=="large-crafting" and "hand-casting" or "large-crafting"
    local position={i*6-33,0}
    local wrong=surface.create_entity{name="factorio-test-repair-"..other,position=position,force="player"}
    wrong.set_recipe(case.name)
    check(wrong.get_recipe()==nil,case.name.." rejects other category")
    wrong.destroy()
    local machine=surface.create_entity{name="factorio-test-repair-"..case.category,position=position,force="player"}
    machine.set_recipe(case.name)
    check(machine.get_recipe().name==case.name,case.name.." selected")
    for _,part in ipairs(case.ingredients) do
      check(machine.insert{name=part.name,count=part.amount}==part.amount,case.name.." input stock")
    end
    storage.machines[i]=machine
  end
  storage.assertions=assertions
end)
script.on_nth_tick(660,function(event)
  if event.tick==0 then return end
  script.on_nth_tick(660,nil)
  assertions=storage.assertions
  for i,case in ipairs(cases) do
    local machine=storage.machines[i]
    check(machine.products_finished==1,case.name.." one repair: "..machine.products_finished)
    for _,part in ipairs(case.products) do
      check(machine.get_output_inventory().get_item_count(part.name)==part.amount,case.name.." repaired output")
    end
    for _,part in ipairs(case.ingredients) do
      check(machine.get_item_count(part.name)==0,case.name.." consumed "..part.name)
    end
  end
  helpers.write_file("factorio-tests/broken-recipes.json",helpers.table_to_json({
    schema=1,case="broken-recipes",status="pass",factorio_version=script.active_mods.base,
    tick=game.tick,assertions=assertions,recipes=#cases,crafts=#cases,failure_count=0,failures={}
  }),false)
end)

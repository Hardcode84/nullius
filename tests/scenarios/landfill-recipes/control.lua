-- given: one declared recipe batch per recipe and void power
-- place: 30 independent executors at crafting speed 60
-- connect: one finite buffer and pump per fluid input
-- act: reject the other category, select the recipe, and insert its ingredients
-- run: 960 ticks
-- expect: exact contracts, one complete recipe batch each, and no input left
local cases=require("__nullius-star__/scenarios/landfill-recipes/fixture")
local fluid_api=require("__nullius-star__/scenarios/fluid-api")
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
    amounts[part.type..":"..part.name]=part.amount
  end
  for _,part in ipairs(expected) do check(amounts[part.type..":"..part.name]==part.amount,label.." "..part.name) end
end
script.on_nth_tick(1,function()
  script.on_nth_tick(1,nil)
  local surface=game.create_surface("landfill-test",{width=128,height=160,autoplace_controls={}})
  surface.request_to_generate_chunks({0,0},3)
  surface.force_generate_chunk_requests()
  for _,entity in pairs(surface.find_entities()) do entity.destroy() end
  storage.machines={}
  storage.feeds={}
  for i,case in ipairs(cases) do
    local recipe=prototypes.recipe[case.name]
    local categories=modern and recipe.categories or {recipe.category}
    check(#categories==1 and categories[1]==case.category,case.name.." category")
    check(recipe.energy==case.seconds,case.name.." duration")
    parts(recipe.ingredients,case.ingredients,case.name.." ingredients")
    parts(recipe.products,case.products,case.name.." products")
    game.forces.player.recipes[case.name].enabled=true
    local other="tiny-crafting"
    local position={((i-1)%5)*16-32,math.floor((i-1)/5)*16-40}
    local wrong=surface.create_entity{name="factorio-test-landfill-"..other,position=position,force="player"}
    wrong.set_recipe(case.name)
    check(wrong.get_recipe()==nil,case.name.." rejects other category")
    wrong.destroy()
    local machine=surface.create_entity{name="factorio-test-landfill-"..case.category,position=position,force="player"}
    machine.set_recipe(case.name)
    check(machine.get_recipe().name==case.name,case.name.." selected")
    storage.feeds[i]={}
    for _,part in ipairs(case.ingredients) do
      if part.type=="item" then
        check(machine.insert{name=part.name,count=part.amount}==part.amount,case.name.." input stock")
      else
        local index
        for slot=1,math.min(2,fluid_api.count(machine)) do
          local filter=fluid_api.filter(machine,slot)
          if filter and filter.name==part.name then index=slot end
        end
        check(index~=nil,case.name.." input port "..part.name)
        local x=machine.position.x+2*index-4
        local pump=surface.create_entity{name="factorio-test-void-pump",position={x,machine.position.y-4.5},direction=defines.direction.south,force="player"}
        local buffer=surface.create_entity{name="factorio-test-landfill-buffer",position={x,machine.position.y-6},force="player"}
        fluid_api.set(buffer,1,{name=part.name,amount=part.amount,temperature=prototypes.fluid[part.name].default_temperature})
        check(fluid_api.get(buffer,1).amount==part.amount,case.name.." full fluid batch")
        storage.feeds[i][#storage.feeds[i]+1]={pump=pump,buffer=buffer,name=part.name}
      end
    end
    storage.machines[i]=machine
  end
  storage.assertions=assertions
end)
script.on_nth_tick(960,function(event)
  if event.tick==0 then return end
  script.on_nth_tick(960,nil)
  assertions=storage.assertions
  for i,case in ipairs(cases) do
    local machine=storage.machines[i]
    check(machine.products_finished==1,case.name.." one craft: "..machine.products_finished.." status "..machine.status.." fluids "..helpers.table_to_json(machine.get_fluid_contents()))
    for _,part in ipairs(case.products) do
      local amount=part.type=="item" and machine.get_output_inventory().get_item_count(part.name) or machine.get_fluid_count(part.name)
      check(math.abs(amount-part.amount)<0.000001,case.name.." recipe output "..part.name..": "..amount)
    end
    for _,part in ipairs(case.ingredients) do
      local amount=part.type=="item" and machine.get_item_count(part.name) or machine.get_fluid_count(part.name)
      if part.type=="item" then check(amount==0,case.name.." consumed "..part.name) end
    end
    for _,feed in ipairs(storage.feeds[i]) do
      local remaining=machine.get_fluid_count(feed.name)+feed.buffer.get_fluid_count(feed.name)+feed.pump.get_fluid_count(feed.name)
      check(math.abs(remaining)<0.000001,case.name.." fluid stock balance "..feed.name..": "..remaining)
    end
  end
  helpers.write_file("factorio-tests/landfill-recipes.json",helpers.table_to_json({
    schema=1,case="landfill-recipes",status="pass",factorio_version=script.active_mods.base,
    tick=game.tick,assertions=assertions,recipes=#cases,crafts=#cases,failure_count=0,failures={}
  }),false)
end)

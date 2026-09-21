-- given: one declared input batch per recipe and void power
-- place: 25 independent executors at crafting speed 60
-- connect: one finite buffer and pump per fluid input
-- act: reject the other category, select the recipe, and insert its ingredients
-- run: 3600 ticks
-- expect: exact contracts, optional guards, and no input left
local all_cases=require("__nullius-star__/scenarios/optional-override-recipes/fixture")
local fluid_api=require("__nullius-star__/scenarios/fluid-api")
local modern=require("__nullius-star__/factorio-version").is_2_1
local cases={}
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
  storage.active=script.active_mods["Transport_Drones"]~=nil
  storage.cases={}
  for _,case in ipairs(all_cases) do
    local active=storage.active and (case.name~="oil_rig" or settings.startup.offshore_oil_enabled.value)
    if active then
      storage.cases[#storage.cases+1]=case
    else
      local recipe=prototypes.recipe[case.name]
      if recipe then
        local categories=modern and recipe.categories or {recipe.category}
        check(categories[1]=="crafting" and #categories==(modern and 2 or 1),case.name.." guarded categories")
        check(recipe.energy==7,case.name.." guarded duration")
        check(#recipe.ingredients==1 and recipe.ingredients[1].name=="iron-plate" and recipe.ingredients[1].amount==2,case.name.." guarded inputs")
      else check(not storage.active,case.name.." absent optional recipe") end
    end
  end
  cases=storage.cases
  if storage.active then
    check(math.abs(prototypes.entity["cargo-drone"].friction_force-0.0041)<1e-9,"cargo drone friction")
    for _,name in ipairs({"cargo-drone-mooring-constant-combinator-refueler","cargo-drone-mooring-constant-combinator-provider","cargo-drone-mooring-constant-combinator-requester","cargo-drone-depot-constant-combinator"}) do
      check(prototypes.entity[name].collision_mask.layers.layer_43,"cargo drone wind collision")
      check(prototypes.item[name].stack_size==10,name.." stack size")
    end
    check(game.forces.player.technologies["transport-drone-speed-3"].prototype.effects[2].recipe=="fast-road","fast-road research unlock")
  end
  local surface=game.create_surface("optional-override-test",{width=192,height=192,autoplace_controls={}})
  surface.request_to_generate_chunks({0,0},3)
  surface.force_generate_chunk_requests()
  for _,entity in pairs(surface.find_entities()) do entity.destroy() end
  if storage.active then
    for i,name in ipairs({"request-depot","buffer-depot","fuel-depot","fluid-depot"}) do
      local depot=surface.create_entity{name=name,position={i*8-40,-20},force="player"}
      check(fluid_api.capacity(depot,1)==100 and fluid_api.capacity(depot,2)==500,name.." inherited fluid volumes")
    end
  end
  storage.machines={}
  storage.feeds={}
  for i,case in ipairs(cases) do
    local name=case.name
    local recipe=assert(prototypes.recipe[name],"missing "..name)
    local categories=modern and recipe.categories or {recipe.category}
    check(#categories==1 and categories[1]==case.category,case.name.." category")
    check(recipe.energy==case.seconds,case.name.." duration")
    parts(recipe.ingredients,case.ingredients,case.name.." ingredients")
    parts(recipe.products,case.products,case.name.." products")
    check(game.forces.player.recipes[name].enabled,case.name.." inherited enabled state")
    game.forces.player.recipes[name].enabled=true
    local inputs=0
    for _,part in ipairs(case.ingredients) do if part.type=="fluid" then inputs=inputs+1 end end
    local other="factorio-test-optional-override-rejected"
    local position={((i-1)%5)*16-32,math.floor((i-1)/5)*16}
    local wrong=surface.create_entity{name="factorio-test-optional-override-"..other,position=position,force="player"}
    wrong.set_recipe(name)
    check(wrong.get_recipe()==nil,case.name.." rejects other category")
    wrong.destroy()
    local machine=surface.create_entity{name="factorio-test-optional-override-"..case.name,position=position,force="player"}
    machine.set_recipe(name)
    check(machine.get_recipe() and machine.get_recipe().name==name,case.name.." selected")
    storage.feeds[i]={}
    for _,part in ipairs(case.ingredients) do
      if part.type=="item" then
        check(machine.insert{name=part.name,count=part.amount}==part.amount,case.name.." input stock")
      else
        local index
        for slot=1,inputs do
          local filter=fluid_api.filter(machine,slot)
          if filter and filter.name==part.name then index=slot end
        end
        check(index~=nil,case.name.." input port "..part.name)
        local x=machine.position.x+2*(part.port or index)-4
        local pump=surface.create_entity{name="factorio-test-optional-override-pump",position={x,machine.position.y-4.5},direction=defines.direction.south,force="player"}
        local buffer=surface.create_entity{name="factorio-test-optional-override-buffer-"..case.name,position={x,machine.position.y-6},force="player"}
        fluid_api.set(buffer,1,{name=part.name,amount=part.amount,temperature=prototypes.fluid[part.name].default_temperature})
        check(fluid_api.get(buffer,1).amount==part.amount,case.name.." full fluid batch")
        storage.feeds[i][#storage.feeds[i]+1]={pump=pump,buffer=buffer,name=part.name}
      end
    end
    storage.machines[i]=machine
  end
  storage.assertions=assertions
end)
script.on_nth_tick(3600,function(event)
  if event.tick==0 then return end
  script.on_nth_tick(3600,nil)
  assertions=storage.assertions
  cases=storage.cases
  for i,case in ipairs(cases) do
    local machine=storage.machines[i]
    local batches=1
    check(machine.products_finished==batches,case.name.." one craft: "..machine.products_finished.." status "..machine.status.." fluids "..helpers.table_to_json(machine.get_fluid_contents()))
    for _,part in ipairs(case.products) do
      local amount=part.type=="item" and machine.get_output_inventory().get_item_count(part.name) or machine.get_fluid_count(part.name)
      check(math.abs(amount-part.amount*batches)<0.000001,case.name.." recipe output "..part.name..": "..amount)
      if part.type=="fluid" then
        local found=false
        for slot=1,fluid_api.count(machine) do
          local fluid=fluid_api.get(machine,slot)
          if fluid and fluid.name==part.name then
            found=true
            check(math.abs(fluid.temperature-prototypes.fluid[part.name].default_temperature)<0.000001,case.name.." output temperature "..part.name)
          end
        end
        check(found,case.name.." output fluid port "..part.name)
      end
    end
    for _,part in ipairs(case.ingredients) do
      local amount=part.type=="item" and (machine.get_item_count(part.name)-machine.get_output_inventory().get_item_count(part.name)) or machine.get_fluid_count(part.name)
      if part.type=="item" then check(amount==0,case.name.." consumed "..part.name) end
    end
    for _,feed in ipairs(storage.feeds[i]) do
      local remaining=machine.get_fluid_count(feed.name)+feed.buffer.get_fluid_count(feed.name)+feed.pump.get_fluid_count(feed.name)
      local expected=0
      for _,part in ipairs(case.products) do if part.type=="fluid" and part.name==feed.name then expected=part.amount end end
      check(math.abs(remaining-expected)<0.000001,case.name.." fluid stock balance "..feed.name..": "..remaining)
    end
  end
  helpers.write_file("factorio-tests/optional-override-recipes.json",helpers.table_to_json({
    schema=1,case="optional-override-recipes",status="pass",factorio_version=script.active_mods.base,
    tick=game.tick,assertions=assertions,recipes=#cases,crafts=#cases,active=storage.active,failure_count=0,failures={}
  }),false)
end)

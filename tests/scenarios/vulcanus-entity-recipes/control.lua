-- given: one declared input batch per recipe and void power
-- place: 5 independent executors at crafting speed 60
-- connect: one finite buffer and pump per fluid input
-- act: reject the other category, select the recipe, and insert its ingredients
-- run: 960 ticks
-- expect: exact contracts and no input left; ingredient-free recipes fill their outputs
-- Output backpressure permits two batches on 2.0 and three on 2.1.
local cases=require("__nullius-star__/scenarios/vulcanus-entity-recipes/fixture")
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
  local surface=game.create_surface("vulcanus-entity-test",{width=128,height=64,autoplace_controls={}})
  surface.ignore_surface_conditions=false
  surface.set_property("nullius-ambient-temperature",100)
  surface.request_to_generate_chunks({0,0},1)
  surface.force_generate_chunk_requests()
  for _,entity in pairs(surface.find_entities()) do entity.destroy() end
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
    check(game.forces.player.recipes[name].enabled==(case.name=="nullius-lava-pumping" or case.name=="nullius-vulcanus-deacon" or case.name=="nullius-vulcanus-cracking"),case.name.." initial enabled state")
    local conditions=recipe.surface_conditions or {}
    local radiator=case.name=="nullius-vulcanus-radiator-1" or case.name=="nullius-vulcanus-radiator-2"
    check(#conditions==(radiator and 1 or 0),case.name.." surface condition count")
    if radiator then
      check(conditions[1].property=="nullius-ambient-temperature" and conditions[1].min==100,case.name.." hot surface threshold")
    end
    game.forces.player.recipes[name].enabled=true
    local inputs,outputs=0,0
    for _,part in ipairs(case.ingredients) do if part.type=="fluid" then inputs=inputs+1 end end
    for _,part in ipairs(case.products) do if part.type=="fluid" then outputs=outputs+1 end end
    local other="factorio-test-vulcanus-entity-rejected"
    local position={((i-1)%5)*16-32,math.floor((i-1)/5)*16}
    local wrong=surface.create_entity{name="factorio-test-vulcanus-entity-"..other,position=position,force="player"}
    wrong.set_recipe(name)
    check(wrong.get_recipe()==nil,case.name.." rejects other category")
    wrong.destroy()
    local machine=surface.create_entity{name="factorio-test-vulcanus-entity-"..case.name,position=position,force="player"}
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
        local pump=surface.create_entity{name="factorio-test-vulcanus-entity-pump",position={x,machine.position.y-4.5},direction=defines.direction.south,force="player"}
        local buffer=surface.create_entity{name="factorio-test-vulcanus-entity-buffer",position={x,machine.position.y-6},force="player"}
        fluid_api.set(buffer,1,{name=part.name,amount=part.amount,temperature=prototypes.fluid[part.name].default_temperature})
        check(fluid_api.get(buffer,1).amount==part.amount,case.name.." full fluid batch")
        storage.feeds[i][#storage.feeds[i]+1]={pump=pump,buffer=buffer,name=part.name}
      end
    end
    storage.machines[i]=machine
  end
  local cold=game.create_surface("radiator-cold",{width=64,height=64,autoplace_controls={}})
  cold.ignore_surface_conditions=false
  cold.set_property("nullius-ambient-temperature",99)
  cold.request_to_generate_chunks({0,0},1)
  cold.force_generate_chunk_requests()
  for _,entity in pairs(cold.find_entities()) do entity.destroy() end
  storage.selection={}
  -- Use native circuit selection: Lua set_recipe bypasses surface restrictions.
  for _,test_surface in ipairs({cold,surface}) do
    for i=4,5 do
      local case=cases[i]
      local machine=test_surface.create_entity{name="factorio-test-vulcanus-entity-"..case.name,position={i*8-32,16},force="player"}
      machine.get_or_create_control_behavior().circuit_set_recipe=true
      local signal=test_surface.create_entity{name="constant-combinator",position={i*8-32,21},force="player"}
      local behavior=signal.get_or_create_control_behavior()
      local section=behavior.get_section(1) or behavior.add_section()
      section.set_slot(1,{value={type="item",name=case.name,quality="normal"},min=1})
      local red=defines.wire_connector_id.circuit_red
      check(machine.get_wire_connector(red,true).connect_to(signal.get_wire_connector(red,true)),case.name.." recipe signal wire")
      storage.selection[#storage.selection+1]={machine=machine,name=case.name,allowed=test_surface==surface}
    end
  end
  storage.assertions=assertions
end)
script.on_nth_tick(960,function(event)
  if event.tick==0 then return end
  script.on_nth_tick(960,nil)
  assertions=storage.assertions
  for i,case in ipairs(cases) do
    local machine=storage.machines[i]
    local batches=#case.ingredients==0 and (modern and 3 or 2) or 1
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
  for _,row in ipairs(storage.selection) do
    local recipe=row.machine.get_recipe()
    check((recipe~=nil)==row.allowed,row.name.." surface selection at "..row.machine.surface.get_property("nullius-ambient-temperature"))
    if row.allowed then check(recipe.name==row.name,row.name.." selected on hot surface") end
  end
  helpers.write_file("factorio-tests/vulcanus-entity-recipes.json",helpers.table_to_json({
    schema=1,case="vulcanus-entity-recipes",status="pass",factorio_version=script.active_mods.base,
    tick=game.tick,assertions=assertions,recipes=#cases,crafts=#cases+(modern and 2 or 1),failure_count=0,failures={}
  }),false)
end)

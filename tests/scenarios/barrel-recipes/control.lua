-- given: one empty barrel and one finite fluid batch per case; void power
-- place: separate fill and empty machines with native recipe categories
-- act: fill, transfer the produced barrel, then empty it
-- run: 120 ticks
-- expect: exact round-trip amounts, one returned barrel, unchanged restrictions
local cases=require("__nullius-star__/scenarios/barrel-recipes/fixture")
local fluid_api=require("__nullius-star__/scenarios/fluid-api")
local modern=require("__nullius-star__/factorio-version").is_2_1
local function check(ok,message)
  storage.assertions=storage.assertions+1
  assert(ok,message)
end
local function parts(actual,expected,label)
  check(#actual==#expected,label.." count")
  for i,part in ipairs(expected) do
    local found=false
    for _,value in ipairs(actual) do
      if value.name==part.name and value.type==part.type and value.amount==part.amount then found=true end
    end
    check(found,label.." "..part.name)
  end
end
script.on_nth_tick(1,function()
  script.on_nth_tick(1,nil)
  storage.assertions=0
  storage.rows={}
  local surface=game.create_surface("barrel-test",{width=64,height=64,autoplace_controls={}})
  surface.request_to_generate_chunks({0,0},1)
  surface.force_generate_chunk_requests()
  for _,entity in pairs(surface.find_entities()) do entity.destroy() end
  check(prototypes.item["water-barrel"].subgroup.name=="hidden","foreign barrel hidden")
  for i,case in ipairs(cases) do
    local barrel=case.name.."-barrel"
    check(prototypes.item[barrel].stack_size==20,barrel.." stack size")
    local row={}
    for _,kind in ipairs({"barrel","unbarrel"}) do
      local name=kind=="barrel" and barrel or "empty-"..barrel
      local recipe=prototypes.recipe[name]
      local categories=modern and recipe.categories or {recipe.category}
      check(#categories==1 and categories[1]=="nullius-"..kind,name.." exclusive category")
      check(recipe.energy==case.seconds,name.." duration")
      check(game.forces.player.recipes[name].enabled==case.enabled,name.." enabled")
      check(recipe.hidden_from_player_crafting,name.." hidden from hand crafting")
      local filled={{type="item",name=barrel,amount=1}}
      local loose={{type="fluid",name=case.name,amount=case.amount},{type="item",name="barrel",amount=1}}
      parts(recipe.ingredients,kind=="barrel" and loose or filled,name.." ingredients")
      parts(recipe.products,kind=="barrel" and filled or loose,name.." products")
      -- Disabled recipes are enabled only after their original state is checked.
      game.forces.player.recipes[name].enabled=true
      local machine=surface.create_entity{name="factorio-test-"..kind,position={i*8-20,kind=="barrel" and 0 or 8},force="player"}
      machine.set_recipe(kind=="barrel" and "empty-"..barrel or barrel)
      check(machine.get_recipe()==nil,name.." rejects opposite category")
      machine.set_recipe(name)
      check(machine.get_recipe().name==name,name.." selected")
      row[kind]=machine
    end
    check(row.barrel.insert{name="barrel",count=1}==1,barrel.." empty barrel stock")
    fluid_api.set(row.barrel,1,{name=case.name,amount=case.amount,temperature=case.temperature})
    check(row.barrel.get_fluid_count(case.name)==case.amount,barrel.." fluid stock")
    storage.rows[i]=row
  end
end)
script.on_nth_tick(60,function(event)
  if event.tick==0 then return end
  script.on_nth_tick(60,nil)
  for i,case in ipairs(cases) do
    local row=storage.rows[i]
    local barrel=case.name.."-barrel"
    check(row.barrel.products_finished==1,barrel.." filled once")
    check(row.barrel.get_fluid_count(case.name)==0,barrel.." consumed fluid")
    check(row.barrel.get_output_inventory().get_item_count(barrel)==1,barrel.." produced barrel")
    check(row.barrel.get_output_inventory().remove{name=barrel,count=1}==1,barrel.." transfer source")
    check(row.unbarrel.insert{name=barrel,count=1}==1,barrel.." transfer destination")
  end
end)
script.on_nth_tick(120,function(event)
  if event.tick==0 then return end
  script.on_nth_tick(120,nil)
  for i,case in ipairs(cases) do
    local row=storage.rows[i]
    check(row.unbarrel.products_finished==1,case.name.." emptied once")
    check(row.unbarrel.get_fluid_count(case.name)==case.amount,case.name.." round-trip fluid")
    check(row.unbarrel.get_output_inventory().get_item_count("barrel")==1,case.name.." returned empty barrel")
    check(row.unbarrel.get_item_count(case.name.."-barrel")==0,case.name.." consumed filled barrel")
    check(fluid_api.get(row.unbarrel,1).temperature==case.temperature,case.name.." output temperature")
  end
  helpers.write_file("factorio-tests/barrel-recipes.json",helpers.table_to_json({
    schema=1,case="barrel-recipes",status="pass",factorio_version=script.active_mods.base,
    tick=game.tick,assertions=storage.assertions,recipes=8,failure_count=0,failures={}
  }),false)
end)

-- given: four material units per material and void power
-- place: nine small-plate and nine large-plate executors
-- act: craft four small plates, transfer them, and craft one large plate
-- run: 420 ticks
-- expect: all 18 contracts, exact consumption, category rejection, naming and guards
local cases=require("__nullius-star__/scenarios/textplate-recipes/fixture")
local modern=require("__nullius-star__/factorio-version").is_2_1
local function check(ok,message)
  storage.assertions=storage.assertions+1
  assert(ok,message)
end
local function finish()
  helpers.write_file("factorio-tests/textplate-recipes.json",helpers.table_to_json({
    schema=1,case="textplate-recipes",status="pass",factorio_version=script.active_mods.base,
    tick=game.tick,assertions=storage.assertions,active=storage.active,
    failure_count=0,failures={}
  }),false)
end
local function unchanged(name)
  local recipe=prototypes.recipe[name]
  local categories=modern and recipe.categories or {recipe.category}
  check(#categories==(modern and 2 or 1) and categories[1]=="crafting",name.." original categories")
  check(recipe.energy==7 and recipe.order=="probe",name.." original duration/order")
  check(game.forces.player.recipes[name].enabled,name.." original enabled state")
  check(#recipe.ingredients==1 and recipe.ingredients[1].name=="iron-plate" and recipe.ingredients[1].amount==2,name.." original inputs")
  check(prototypes.item[name].localised_name[1]=="fixture.original",name.." original item name")
  check(prototypes.entity[name].localised_name[1]=="fixture.original",name.." original entity name")
end
script.on_nth_tick(1,function()
  script.on_nth_tick(1,nil)
  storage.assertions=0
  storage.active=script.active_mods.textplates~=nil
  if not prototypes.recipe["textplate-small-stone"] then
    check(not storage.active,"absent textplates integration")
    finish()
    return
  end
  for _,size in ipairs({"small","large"}) do unchanged("textplate-"..size.."-brass") end
  for i,name in ipairs({"nullius-mechanical-separation","nullius-empiricism-1","nullius-empiricism-2","nullius-miniaturization-2"}) do
    local prerequisites=game.forces.player.technologies[name].prerequisites
    local count=0
    for _ in pairs(prerequisites) do count=count+1 end
    check(count==(storage.active and 2 or 1),name.." prerequisite count")
    check(prerequisites.automation~=nil,name.." retains original prerequisite")
    check((prerequisites["nullius-typesetting-"..i]~=nil)==storage.active,name.." typesetting prerequisite")
  end
  if not storage.active then
    for _,case in ipairs(cases) do
      for _,size in ipairs({"small","large"}) do unchanged("textplate-"..size.."-"..case.material) end
    end
    finish()
    return
  end
  storage.rows={}
  local surface=game.create_surface("textplate-test",{width=128,height=64,autoplace_controls={}})
  surface.request_to_generate_chunks({0,0},2)
  surface.force_generate_chunk_requests()
  for _,entity in pairs(surface.find_entities()) do entity.destroy() end
  local wrong=surface.create_entity{name="factorio-test-textplate-crafting",position={0,20},force="player"}
  for i,case in ipairs(cases) do
    local row={}
    for _,size in ipairs({"small","large"}) do
      local name="textplate-"..size.."-"..case.material
      local recipe=prototypes.recipe[name]
      local categories=modern and recipe.categories or {recipe.category}
      check(#categories==1 and categories[1]=="medium-crafting",name.." exclusive category")
      check(recipe.energy==1,name.." one-second craft")
      check(not game.forces.player.recipes[name].enabled,name.." disabled initially")
      check(recipe.order=="nullius-"..case.order..(size=="small" and "b" or "c"),name.." order")
      local input=size=="small" and case.input or "textplate-small-"..case.material
      check(#recipe.ingredients==1 and recipe.ingredients[1].type=="item" and recipe.ingredients[1].name==input and recipe.ingredients[1].amount==(size=="small" and 1 or 4),name.." exact input")
      check(#recipe.products==1 and recipe.products[1].name==name and recipe.products[1].amount==1,name.." inherited yield")
      for _,kind in ipairs({"item","entity"}) do
        local locale=prototypes[kind][name].localised_name
        if case.material=="gold" then
          check(locale[1]==kind.."-name.textplate" and locale[2][1]=="textplates."..size and locale[3][1]=="textplates.aluminum",name.." aluminum "..kind.." name")
        else
          check(locale[1]=="fixture.original",name.." unchanged "..kind.." name")
        end
      end
      game.forces.player.recipes[name].enabled=true
      wrong.set_recipe(name)
      check(wrong.get_recipe()==nil,name.." rejects inherited category")
      local machine=surface.create_entity{name="factorio-test-textplate-medium-crafting",position={i*8-40,size=="small" and 0 or 8},force="player"}
      machine.set_recipe(name)
      check(machine.get_recipe().name==name,name.." selected")
      row[size]=machine
    end
    check(row.small.insert{name=case.input,count=4}==4,case.material.." material stock")
    storage.rows[i]=row
  end
end)
script.on_nth_tick(300,function(event)
  if event.tick==0 then return end
  script.on_nth_tick(300,nil)
  if not storage.active then return end
  for i,case in ipairs(cases) do
    local row=storage.rows[i]
    local name="textplate-small-"..case.material
    check(row.small.products_finished==4,name.." four crafts")
    check(row.small.get_item_count(case.input)==0,name.." material consumed")
    check(row.small.get_output_inventory().get_item_count(name)==4,name.." four produced plates")
    check(row.small.get_output_inventory().remove{name=name,count=4}==4,name.." transfer source")
    check(row.large.insert{name=name,count=4}==4,name.." transfer destination")
  end
end)
script.on_nth_tick(420,function(event)
  if event.tick==0 then return end
  script.on_nth_tick(420,nil)
  if not storage.active then return end
  for i,case in ipairs(cases) do
    local machine=storage.rows[i].large
    check(machine.products_finished==1,case.material.." one large craft")
    check(machine.get_item_count("textplate-small-"..case.material)==0,case.material.." four small plates consumed")
    check(machine.get_output_inventory().get_item_count("textplate-large-"..case.material)==1,case.material.." one large output")
  end
  finish()
end)

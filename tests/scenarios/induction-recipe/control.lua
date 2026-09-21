-- given: one exact input batch, an external recipe yielding two coils, and void power
-- place: a small-crafting executor and an ordinary crafting executor
-- act: research induction technology 1 and craft once
-- run: 360 ticks
-- expect: native category replacement, unchanged output/unlock, exact research contracts
local modern=require("__nullius-star__/factorio-version").is_2_1
local contracts=require("__nullius-star__/scenarios/induction-recipe/fixture")
local packs={"geology","climatology","mechanical","electrical","chemical","physics"}
local function check(ok,message)
  storage.assertions=storage.assertions+1
  assert(ok,message)
end
local function finish()
  helpers.write_file("factorio-tests/induction-recipe.json",helpers.table_to_json({
    schema=1,case="induction-recipe",status="pass",factorio_version=script.active_mods.base,
    tick=game.tick,assertions=storage.assertions,active=storage.active,
    failure_count=0,failures={}
  }),false)
end
script.on_nth_tick(1,function()
  script.on_nth_tick(1,nil)
  storage.assertions=0
  storage.active=script.active_mods["Induction Charging"]~=nil
  local recipe=prototypes.recipe["induction-coil"]
  if not storage.active then
    if recipe then
      local categories=modern and recipe.categories or {recipe.category}
      check(categories[1]=="crafting" and #categories==(modern and 2 or 1),"absent mod preserves categories")
      check(recipe.energy==7,"absent mod preserves duration")
      check(#recipe.ingredients==1 and recipe.ingredients[1].name=="iron-plate" and recipe.ingredients[1].amount==2,"absent mod preserves inputs")
      check(prototypes.item["induction-coil"].stack_size==100,"absent mod preserves stack")
      check(prototypes.item["induction-coil"].subgroup.name=="other","absent mod preserves subgroup")
      check(prototypes.item["induction-coil"].order=="probe","absent mod preserves order")
      for i=1,5 do
        local tech=game.forces.player.technologies["induction-technology"..i]
        check(next(tech.prerequisites)==nil,"absent mod preserves prerequisites")
      end
    else
      check(prototypes.item["induction-coil"]==nil,"no induction prototypes without mod")
    end
    finish()
    return
  end
  local categories=modern and recipe.categories or {recipe.category}
  check(#categories==1 and categories[1]=="small-crafting","exclusive small-crafting category")
  check(recipe.energy==5,"five-second craft")
  check(not game.forces.player.recipes["induction-coil"].enabled,"preserved locked state")
  check(#recipe.products==1 and recipe.products[1].name=="induction-coil" and recipe.products[1].amount==2,"inherited two-coil output")
  check(prototypes.item["induction-coil"].stack_size==50,"stack size")
  check(prototypes.item["induction-coil"].subgroup.name=="solar","solar subgroup")
  check(prototypes.item["induction-coil"].order=="nullius-ib" and recipe.order=="nullius-ib","item and recipe order")
  for i,expected in ipairs(contracts) do
    local tech=game.forces.player.technologies["induction-technology"..i]
    check(tech.research_unit_count==expected.count,"research count "..i)
    check(tech.research_unit_energy==expected.seconds*60,"research duration "..i)
    check(tech.prototype.order==expected.order,"research order "..i)
    local actual=tech.prototype.research_unit_ingredients
    check(#actual==#expected.packs,"pack count "..i)
    local amounts={}
    for _,part in ipairs(actual) do amounts[part.name]=part.amount end
    for index,amount in ipairs(expected.packs) do check(amounts["nullius-"..packs[index].."-pack"]==amount,"science cost "..i..":"..index) end
    local count=0
    for _ in pairs(tech.prerequisites) do count=count+1 end
    check(count==#expected.prerequisites,"prerequisite count "..i)
    for _,name in ipairs(expected.prerequisites) do check(tech.prerequisites[name]~=nil,"prerequisite "..name) end
  end
  game.forces.player.technologies["induction-technology1"].researched=true
  check(game.forces.player.recipes["induction-coil"].enabled,"inherited unlock preserved")
  local expected={["nullius-capacitor"]=5,["decider-combinator"]=3,["copper-cable"]=12,["nullius-aluminum-rod"]=8}
  check(#recipe.ingredients==4,"four ingredients")
  for _,part in ipairs(recipe.ingredients) do check(part.type=="item" and expected[part.name]==part.amount,"exact input "..part.name) end
  local surface=game.create_surface("induction-test",{width=64,height=64,autoplace_controls={}})
  surface.request_to_generate_chunks({0,0},1)
  surface.force_generate_chunk_requests()
  for _,entity in pairs(surface.find_entities()) do entity.destroy() end
  local wrong=surface.create_entity{name="factorio-test-induction-crafting",position={8,0},force="player"}
  wrong.set_recipe("induction-coil")
  check(wrong.get_recipe()==nil,"original crafting category rejected")
  local machine=surface.create_entity{name="factorio-test-induction-small-crafting",position={0,0},force="player"}
  machine.set_recipe("induction-coil")
  check(machine.get_recipe().name=="induction-coil","small crafting accepts coil")
  for name,amount in pairs(expected) do check(machine.insert{name=name,count=amount}==amount,"input stock "..name) end
  storage.machine=machine
end)
script.on_nth_tick(360,function(event)
  if event.tick==0 then return end
  script.on_nth_tick(360,nil)
  if not storage.active then return end
  local machine=storage.machine
  check(machine.products_finished==1,"one completed craft")
  check(machine.get_output_inventory().get_item_count("induction-coil")==2,"two produced coils")
  for _,part in ipairs(prototypes.recipe["induction-coil"].ingredients) do
    check(machine.get_item_count(part.name)==0,"consumed "..part.name)
  end
  finish()
end)

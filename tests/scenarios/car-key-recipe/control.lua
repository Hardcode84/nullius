-- given: one programmable speaker, one arithmetic combinator, and void power
-- place: one small-crafting machine and one machine with the wrong category
-- act: research broadcasting, select the recipe, and insert the input batch
-- run: 240 ticks
-- expect: one key, exact costs and time, native unlock, and optional-mod guards
local modern=require("__nullius-star__/factorio-version").is_2_1
local NAME="nullius-car-key"
local function check(ok,message)
  storage.assertions=storage.assertions+1
  assert(ok,message)
end
local function finish()
  helpers.write_file("factorio-tests/car-key-recipe.json",helpers.table_to_json({
    schema=1,case="car-key-recipe",status="pass",factorio_version=script.active_mods.base,
    tick=game.tick,assertions=storage.assertions,active=storage.active,
    failure_count=0,failures={}
  }),false)
end
script.on_nth_tick(1,function()
  script.on_nth_tick(1,nil)
  storage.assertions=0
  storage.active=script.active_mods.GCKI~=nil and prototypes.item["car-key"]~=nil
  local recipe=prototypes.recipe[NAME]
  check((recipe~=nil)==storage.active,"recipe follows mod and item guards")
  local unlocks=0
  for _,effect in ipairs(prototypes.technology["nullius-broadcasting-1"].effects) do
    if effect.type=="unlock-recipe" and effect.recipe==NAME then unlocks=unlocks+1 end
  end
  check(unlocks==(storage.active and 1 or 0),"broadcasting unlock follows guards")
  if not storage.active then
    if prototypes.item["car-key"] then
      check(prototypes.item["car-key"].subgroup.name=="other","inactive integration preserves item subgroup")
      check(prototypes.item["car-key"].order=="probe","inactive integration preserves item order")
    end
    finish()
    return
  end
  local categories=modern and recipe.categories or {recipe.category}
  check(#categories==1 and categories[1]=="small-crafting","exclusive small-crafting category")
  check(recipe.energy==3,"three-second craft")
  check(not game.forces.player.recipes[NAME].enabled,"recipe starts locked")
  check(#recipe.ingredients==2,"two ingredients")
  local amounts={}
  for _,part in ipairs(recipe.ingredients) do
    check(part.type=="item","item input")
    amounts[part.name]=part.amount
  end
  check(amounts["programmable-speaker"]==1,"one programmable speaker")
  check(amounts["arithmetic-combinator"]==1,"one arithmetic combinator")
  check(#recipe.products==1 and recipe.products[1].name=="car-key" and recipe.products[1].amount==1,"one key output")
  check(prototypes.item["car-key"].subgroup.name=="vehicle","key vehicle subgroup")
  check(prototypes.item["car-key"].order=="nullius-g","key order")
  game.forces.player.technologies["nullius-broadcasting-1"].researched=true
  check(game.forces.player.recipes[NAME].enabled,"broadcasting enables recipe")
  local surface=game.create_surface("car-key-test",{width=64,height=64,autoplace_controls={}})
  surface.request_to_generate_chunks({0,0},1)
  surface.force_generate_chunk_requests()
  for _,entity in pairs(surface.find_entities()) do entity.destroy() end
  local wrong=surface.create_entity{name="factorio-test-car-key-crafting",position={8,0},force="player"}
  wrong.set_recipe(NAME)
  check(wrong.get_recipe()==nil,"ordinary crafting rejects key")
  local machine=surface.create_entity{name="factorio-test-car-key-small-crafting",position={0,0},force="player"}
  machine.set_recipe(NAME)
  check(machine.get_recipe().name==NAME,"small crafting accepts key")
  for name,amount in pairs(amounts) do check(machine.insert{name=name,count=amount}==amount,"input stock "..name) end
  storage.machine=machine
end)
script.on_nth_tick(240,function(event)
  if event.tick==0 then return end
  script.on_nth_tick(240,nil)
  if not storage.active then return end
  local machine=storage.machine
  check(machine.products_finished==1,"one completed craft")
  check(machine.get_output_inventory().get_item_count("car-key")==1,"one produced key")
  check(machine.get_item_count("programmable-speaker")==0,"speaker consumed")
  check(machine.get_item_count("arithmetic-combinator")==0,"combinator consumed")
  finish()
end)

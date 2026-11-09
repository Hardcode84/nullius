-- given: one real admin, a second player, finite crafting inputs and debug item creation.
-- place/connect: personal request and trash slots in a real multiplayer session.
-- act: enable through the command handler after a native console command; request gears.
-- run: production logistics checks, including autocraft and remote view.
-- expect: admin and achievement gates, free supply, trash removal, per-player isolation,
--   inventory capacity, disabled sections and admin revocation.
local join=require("__nullius-star__/scenarios/multiplayer-join")
local CASE="debug-logistics"
local GEAR="nullius-iron-gear"
local function check(value,message)
  storage.assertions=storage.assertions+1
  assert(value,message)
end
local function command(player,parameter)
  remote.call("nullius-test-autocraft","debug_command",{player_index=player.index,parameter=parameter})
end
local function action(operation,fields)
  storage.action=(storage.action or 0)+1
  fields=fields or {};fields.id=storage.action;fields.action=operation
  helpers.write_file("factorio-tests/multiplayer-action.json",helpers.table_to_json(fields),false)
end
local function phase(name) storage.phase=name;storage.since=game.tick end
local function request(player,count)
  local point=player.character.get_requester_point()
  local section=point.get_section(1) or point.add_section()
  section.set_slot(1,{value={type="item",name=GEAR,quality="normal"},min=count,max=count})
  return section
end
script.on_init(function() storage.assertions=0 end)
script.on_event(defines.events.on_player_joined_game,function(event)
  local p=game.get_player(event.player_index)
  if p.name=="nullius-test-a" and not storage.player then
    storage.player=p.index;p.admin=false
    check(commands.commands["nullius-debug-logistics"]~=nil,"console command registered")
    check(not game.console_command_used,"clean console baseline")
    command(p,"on")
    check(not p.force.character_logistic_requests,"non-admin cannot unlock requests")
    p.admin=true
    command(p,"on")
    check(not p.force.character_logistic_requests,"achievements gate blocks unlock")
    action("console",{command='/c game.print("Debug logistics test")'})
    phase("console")
  elseif p.name=="nullius-test-b" then
    storage.other=p.index
    check(join.joined(),"second client ends the join wait")
    phase("supply")
  end
end)
script.on_nth_tick(1,function()
  if not storage.player or storage.finished then return end
  local p=game.get_player(storage.player)
  local age=game.tick-storage.since
  if age >= 180 then error("phase timeout: "..storage.phase) end
  if storage.phase=="console" and game.console_command_used then
    command(p,"on")
    check(p.force.character_logistic_requests,"requests unlocked")
    check(#p.character.get_inventory(defines.inventory.character_trash)>0,"usable trash slot")
    p.character.get_main_inventory().clear()
    request(p,5)
    command(p,"on")
    check(p.character.get_item_count(GEAR)==5,"immediate free supply")
    p.force.recipes[GEAR].enabled=true
    p.character.get_main_inventory().insert{name="nullius-iron-plate",count=4}
    p.character.get_main_inventory().insert{name="nullius-iron-rod",count=2}
    remote.call("nullius-test-autocraft","shortcut",{player_index=p.index,prototype_name="nullius-autocraft"})
    p.character.get_main_inventory().remove{name=GEAR,count=5}
    p.character.get_inventory(defines.inventory.character_trash).insert{name="nullius-iron-plate",count=2}
    action("join",{player="nullius-test-b"})
    join.await({"nullius-test-b"})
    phase("join")
  elseif storage.phase=="supply" and age>=35 then
    check(p.character.get_item_count(GEAR)==5,"poll supplies missing items")
    check(p.character.crafting_queue_size==0,"debug supply runs before autocraft")
    check(p.character.get_item_count("nullius-iron-plate")==4,"no crafting resources consumed")
    check(p.character.get_inventory(defines.inventory.character_trash).is_empty(),"trash destroyed")
    local other=game.get_player(storage.other)
    other.character.get_main_inventory().clear();request(other,5)
    other.admin=false;command(other,"on")
    other.admin=true
    p.set_controller{type=defines.controllers.remote}
    p.character.get_main_inventory().remove{name=GEAR,count=5}
    phase("remote")
  elseif storage.phase=="remote" and age>=35 then
    check(p.character.get_item_count(GEAR)==5,"physical inventory supplied in remote view")
    check(game.get_player(storage.other).character.get_item_count(GEAR)==0,"other player receives no free items")
    local section=request(p,8);section.active=false
    phase("section")
  elseif storage.phase=="section" and age>=35 then
    check(p.character.get_item_count(GEAR)==5,"disabled section ignored")
    request(p,8).active=true
    command(p,"off")
    remote.call("nullius-test-autocraft","shortcut",{player_index=p.index,prototype_name="nullius-autocraft"})
    phase("off")
  elseif storage.phase=="off" and age>=35 then
    check(p.character.get_item_count(GEAR)==5,"off stops free supply")
    command(p,"on")
    check(p.character.get_item_count(GEAR)==8,"reenable supplies immediately")
    local inv=p.character.get_main_inventory()
    inv.clear()
    inv.insert{name="nullius-iron-plate",count=1000000}
    command(p,"on")
    check(inv.get_item_count(GEAR)==0,"full inventory neither spills nor deletes stock")
    inv.clear();p.admin=false
    phase("demoted")
  elseif storage.phase=="demoted" and age>=35 then
    check(p.character.get_item_count(GEAR)==0,"demotion stops debug logistics")
    p.admin=true
    phase("promoted")
  elseif storage.phase=="promoted" and age>=35 then
    check(p.character.get_item_count(GEAR)==0,"promotion does not restore old authorization")
    check(game.console_command_used,"achievement disable flag stays set")
    storage.finished=true
    helpers.write_file("factorio-tests/"..CASE..".json",helpers.table_to_json{
      schema=1,case=CASE,status="pass",assertions=storage.assertions,failure_count=0,tick=game.tick},false)
  end
end)

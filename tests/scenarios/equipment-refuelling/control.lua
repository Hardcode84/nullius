-- given: a real player, chassis 6, three mechas, generators, reactors, refuelers,
-- declared normal/rare fuel and spent items. No external fuel supply.
-- act: run production refuelling, empty and refill inventories, remove equipment
-- and mechas, then save/reload through a native configuration change.
-- expect: five stored fuels, quality and item conservation, retained selections,
-- safe cleanup, and working refuelling after reload.
local CASE="equipment-refuelling"
local API="nullius-test-refuelers"
local function check(ok,msg) storage.assertions=storage.assertions+1;assert(ok,msg) end
local function call(name,...) return remote.call(API,name,...) end
local function count(entity,name,quality)
  return entity.get_item_count{name=name,quality=quality or "normal"}
end
local function equip(grid,name)
  return assert(grid.put{name=name},"equipment did not fit: "..name)
end
local function return_fuel(owner,equipment)
  for _,stack in pairs(equipment.burner.inventory.get_contents()) do
    check(owner.insert(stack)==stack.count,"return declared fuel")
  end
  equipment.burner.inventory.clear()
end
local function total(owner,equipment,fuel,quality)
  local result=prototypes.item[fuel].burnt_result.name
  local burner=equipment.burner
  local burning=burner.currently_burning
  return count(owner,fuel,quality)+count(owner,result,quality)+
    count(burner.inventory,fuel,quality)+count(burner.burnt_result_inventory,result,quality)+
    ((burning and burning.name.name==fuel and burning.quality.name==quality) and 1 or 0)
end
script.on_init(function() storage.assertions=0;storage.stage="setup";storage.joins=0 end)
script.on_event(defines.events.on_player_joined_game,function(event)
  if game.get_player(event.player_index).name=="nullius-test-a" then storage.joins=storage.joins+1 end
end)
script.on_nth_tick(30,function()
  local player=game.get_player("nullius-test-a")
  if not player or not player.connected then return end
  if storage.stage=="setup" then
    local surface=game.surfaces.nauvis
    surface.request_to_generate_chunks({100,100},2);surface.force_generate_chunk_requests()
    for _,entity in pairs(surface.find_entities_filtered{area={{80,80},{140,140}}}) do entity.destroy() end
    check(player.character~=nil,"player character")
    player.teleport({100,100},surface)
    local armor=player.get_inventory(defines.inventory.character_armor)
    armor.clear();armor.insert{name="nullius-chassis-6",count=1}
    player.get_main_inventory().clear()
    local grid=armor[1].grid
    equip(grid,"nullius-refueler")
    local generator=equip(grid,"nullius-portable-generator-1")
    player.insert{name="processed-fuel",quality="rare",count=20}
    call("player",player.index)
    call("update")
    check(generator.burner.inventory.is_empty(),"unselected generator remains empty")
    generator.burner.inventory.insert{name="processed-fuel",quality="rare",count=2}
    call("update")
    check(count(generator.burner.inventory,"processed-fuel","rare")==5,"character fuel limit")
    check(total(player,generator,"processed-fuel","rare")==22,"character fuel conservation")
    check(count(generator.burner.inventory,"processed-fuel")==0,"fuel quality")
    return_fuel(player,generator)
    call("player",player.index)
    call("update")
    check(count(generator.burner.inventory,"processed-fuel","rare")==5,"character remembers empty fuel after refresh")
    generator.burner.burnt_result_inventory.insert{name="nullius-canister",quality="rare",count=2}
    call("update")
    check(count(player,"nullius-canister","rare")==2,"spent fuel quality")
    check(generator.burner.burnt_result_inventory.is_empty(),"spent fuel moved once")
    storage.player_generator=generator
    storage.player_total=24

    storage.mechs={}
    for i=1,3 do
      local mech=assert(surface.create_entity{name="nullius-mecha",position={105+i*8,110},force="player",raise_built=true})
      local g=equip(mech.grid,"nullius-portable-generator-1")
      equip(mech.grid,"nullius-refueler")
      mech.insert{name="processed-fuel",count=20}
      g.burner.inventory.insert{name="processed-fuel",count=2}
      storage.mechs[i]={entity=mech,generator=g,unit=mech.unit_number}
    end
    call("refresh");call("update")
    for _,row in ipairs(storage.mechs) do
      check(row.generator.burner.inventory.get_item_count()==5,"mecha fuel limit")
      check(total(row.entity,row.generator,"processed-fuel","normal")==22,"mecha fuel conservation")
    end

    local row=storage.mechs[1]
    return_fuel(row.entity,row.generator)
    row.generator.burner.inventory.insert{name="processed-fuel",count=2}
    row.entity.remove_item{name="processed-fuel",count=2}
    row.entity.insert{name="processed-fuel",quality="rare",count=20}
    row.generator.burner.inventory.insert{name="processed-fuel",quality="rare",count=1}
    call("update")
    check(row.generator.burner.inventory.get_item_count()==5,"mixed quality total cap")
    check(total(row.entity,row.generator,"processed-fuel","normal")==22,"mixed normal conserved")
    check(total(row.entity,row.generator,"processed-fuel","rare")==21,"mixed rare conserved")

    local reactor=equip(row.entity.grid,"nullius-portable-reactor")
    reactor.burner.inventory.insert{name="nullius-fission-cell",count=8}
    row.entity.insert{name="nullius-fission-cell",count=20}
    call("refresh");call("update")
    check(reactor.burner.inventory.get_item_count()==8,"manual overfill retained")
    return_fuel(row.entity,reactor)
    call("update")
    check(reactor.burner.inventory.get_item_count()==5,"reactor remembered separately")
    check(total(row.entity,reactor,"nullius-fission-cell","normal")==28,"reactor conserved")

    local removed=storage.mechs[2]
    removed.entity.grid.take{equipment=removed.generator}
    call("update")
    check(removed.entity.valid,"removed equipment cleanup")
    storage.mechs[2].entity.destroy()
    storage.mechs[3].entity.destroy()
    call("update")
    check(not call("tracked",storage.mechs[3].unit),"destroyed mecha removed from refuelers")
    return_fuel(row.entity,row.generator)
    call("update")
    check(row.generator.burner.inventory.get_item_count()==5,"remaining mecha still refuels")

    -- The released storage schema remembered normal-quality fuel names.
    return_fuel(row.entity,row.generator)
    row.generator.burner.inventory.insert{name="processed-fuel",count=1}
    row.entity.remove_item{name="processed-fuel",count=1}
    call("update")
    return_fuel(row.entity,row.generator)
    game.tick_paused=true
    call("legacy_memory",row.entity,"generator","processed-fuel")
    storage.reload_mech=row
    storage.stage="reload"
    helpers.write_file("factorio-tests/multiplayer-action.json",helpers.table_to_json{
      id=1,action="reload",configuration_change=true},false)
  elseif storage.stage=="reload" and storage.joins>=2 and
      game.get_player("nullius-test-b") and game.get_player("nullius-test-b").connected then
    check(script.active_mods["nullius-star"]=="999.0.0","native configuration change ran")
    call("update")
    check(storage.reload_mech.generator.burner.inventory.get_item_count()<=5,"post-reload cap "..helpers.table_to_json{equipment=storage.reload_mech.generator.name,contents=storage.reload_mech.generator.burner.inventory.get_contents()})
    check(count(storage.reload_mech.generator.burner.inventory,"processed-fuel")>0,"legacy fuel memory restored")
    check(total(player,storage.player_generator,"processed-fuel","rare")==storage.player_total,"reload preserves player fuel and quality")
    local last=storage.reload_mech
    last.entity.destroy();call("update")
    check(not call("tracked",last.unit),"last mecha removed")
    helpers.write_file("factorio-tests/"..CASE..".json",helpers.table_to_json{
      schema=1,case=CASE,status="pass",assertions=storage.assertions,failure_count=0,
      tick=game.tick,factorio_version=script.active_mods.base},false)
    storage.stage="done"
  end
end)

script.on_configuration_changed(function() game.tick_paused=false end)

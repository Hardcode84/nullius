-- given: native Fulgora storms, poles, ten salt, crusher, empty electric receiver.
-- Robot fixture: roboport, construction robots, pole stock, and debug power.
-- place: isolated patches on sand and island; no generator at the crusher.
-- act: raised build, ghost revival, clone, upgrade, move, mine, destroy, merge forces.
-- run: scheduled lifecycle checks and native robot construction through tick 3600.
-- expect: one invisible collector per pole, native energy delivery, no orphans.
local NAME='nullius-pole-lightning-collector'
local function check(ok,message) storage.assertions=storage.assertions+1; assert(ok,message) end
local function helper(pole)
  local list=pole.surface.find_entities_filtered{name=NAME,position=pole.position,radius=0.1}
  check(#list==1,'one helper for '..pole.name)
  check(not list[1].destructible and not list[1].operable,'helper exposed')
  return list[1]
end
local function build(name,x,y,raise)
  return assert(storage.surface.create_entity{name=name,position={x,y},force='player',raise_built=raise})
end
local function patch(surface,x,y,tile)
  surface.request_to_generate_chunks({x,y},1); surface.force_generate_chunk_requests()
  for _,e in pairs(surface.find_entities_filtered{area={{x-16,y-16},{x+16,y+16}}}) do e.destroy() end
  local tiles={}
  for dx=-16,16 do for dy=-16,16 do tiles[#tiles+1]={name=tile,position={x+dx,y+dy}} end end
  surface.set_tiles(tiles,true)
end
script.on_nth_tick(1,function()
  if game.tick==0 then return end
  script.on_nth_tick(1,nil)
  storage.assertions=0
  storage.surface=game.planets['nullius-fulgora'].create_surface()
  local surface=storage.surface
  surface.freeze_daytime=true; surface.daytime=0
  for _,x in ipairs({0,100,200,300,400,500,600}) do patch(surface,x,0,'fulgoran-rock') end
  patch(surface,0,100,'nullius-fulgora-sediment')
  storage.pole=build('small-electric-pole',0,0,true)
  storage.collector=helper(storage.pole)
  storage.receiver=build('factorio-test-lightning-receiver',1,1,false)
  storage.crusher=build('nullius-crusher-1',2,-1,false)
  game.forces.player.technologies['nullius-primitive-filtration'].researched=true
  storage.crusher.set_recipe('nullius-salt-disposal'); storage.crusher.insert{name='nullius-salt',count=10}
  surface.execute_lightning{name='nullius-fulgora-lightning',position={0,0}}
  storage.sand=build('small-electric-pole',0,100,true); helper(storage.sand)
  local ghost=surface.create_entity{name='entity-ghost',inner_name='small-electric-pole',position={100,0},force='player'}
  local _,revived=ghost.revive{raise_revive=true}; check(revived~=nil,'revive pole'); storage.revived=revived; helper(revived)
  storage.clone=storage.pole.clone{position={200,0},surface=surface,force='player'}; helper(storage.clone)
  surface.clone_area{source_area={{-1,-1},{1,1}},destination_area={{299,-1},{301,1}},destination_surface=surface,
    clone_tiles=false,clone_entities=true,clone_decoratives=false,clear_destination_entities=true,expand_map=true}
  storage.area_clone=surface.find_entities_filtered{type='electric-pole',position={300,0},radius=1}[1]
  check(storage.area_clone~=nil,'area cloned pole'); helper(storage.area_clone)
  storage.hand=build('small-electric-pole',400,0,true); helper(storage.hand)
  storage.inventory=game.create_inventory(10)
  storage.robot_pole=build('small-electric-pole',500,0,true)
  storage.port=build('roboport',503,0,false)
  storage.port.insert{name='construction-robot',count=5}
  local chest=build('passive-provider-chest',505,4,false)
  chest.insert{name='small-electric-pole',count=5}
  local grid=build('factorio-test-planner-grid',500,4,false)
  grid.power_production=100000000; grid.electric_buffer_size=100000000
  surface.create_entity{name='entity-ghost',inner_name='small-electric-pole',position={508,0},force='player'}
  local nauvis=game.surfaces[1]
  patch(nauvis,500,500,'grass-1')
  local other=nauvis.create_entity{name='small-electric-pole',position={500,500},force='player',raise_built=true}
  check(nauvis.count_entities_filtered{name=NAME}==0,'collector outside Fulgora')
end)
script.on_nth_tick(60,function()
  if game.tick==0 then return end
  if game.tick==60 then
    check(storage.receiver.energy>0,'native collector did not power receiver')
    check(storage.collector.energy>0,'strike did not charge collector')
    local foreign=game.create_force('collector-foreign')
    storage.pole.force=foreign
    check(helper(storage.pole)==storage.collector,'force change duplicated helper')
    storage.receiver.energy=0
    storage.revived.destroy()
    storage.clone.die()
    storage.hand.mine{inventory=storage.inventory,raise_destroyed=true}
    storage.area_clone.teleport({320,0},nil,true)
    helper(storage.area_clone)
  elseif game.tick==120 then
    check(storage.receiver.energy>0,'force change broke native delivery')
    check(storage.crusher.crafting_progress>0 or storage.crusher.products_finished>0,'lightning did not power real recipe')
    check(storage.surface.count_entities_filtered{name=NAME,area={{90,-10},{210,10}}}==0,'mined/dead orphan')
    check(storage.surface.count_entities_filtered{name=NAME,position={400,0},radius=1}==0,'mined orphan')
    game.merge_forces('collector-foreign','player')
    storage.collector.destroy()
    storage.sand.destroy()
  elseif game.tick==180 then
    storage.collector=helper(storage.pole)
    check(storage.surface.count_entities_filtered{name=NAME,position={0,100},radius=1}==0,'sand orphan')
    storage.pole=assert(storage.surface.create_entity{name='medium-electric-pole',position={0,0},
      force='player',fast_replace=true,spill=false,raise_built=true})
    helper(storage.pole)
    storage.surface.execute_lightning{name='nullius-fulgora-lightning',position=storage.pole.position}
  elseif game.tick==240 then
    helper(storage.pole)
    check(storage.surface.count_entities_filtered{name=NAME,position={0,0},radius=1}==1,'replacement duplicates')
    local clone=storage.area_clone.clone{position={500,510},surface=game.surfaces[1],force='player'}
    check(clone~=nil,'cross-surface clone')
    storage.area_clone.destroy()
  elseif game.tick==300 then
    check(storage.surface.count_entities_filtered{name=NAME,position={320,0},radius=1}==0,'moved pole orphan')
    check(game.surfaces[1].count_entities_filtered{name=NAME}==0,'cloned collector outside Fulgora')
  elseif game.tick==3600 then
    check(storage.crusher.products_finished==10,'lightning-powered salt batches incomplete')
    local robot=storage.surface.find_entities_filtered{type='electric-pole',position={508,0},radius=1}[1]
    check(robot~=nil,'robot did not build pole'); helper(robot)
    local poles=storage.surface.find_entities_filtered{type='electric-pole'}
    for _,pole in ipairs(poles) do helper(pole) end
    check(storage.surface.count_entities_filtered{name=NAME}==#poles,'orphan collector')
    storage.surface.clear()
  end
end)
script.on_nth_tick(3605,function()
  if game.tick==0 then return end
  check(storage.surface.count_entities_filtered{name=NAME}==0,'surface clear orphan')
  storage.deleted_surface=storage.surface.index
  build('small-electric-pole',0,0,true)
  check(game.delete_surface(storage.surface),'delete collector surface')
  script.on_nth_tick(3605,nil)
end)
script.on_nth_tick(3610,function()
  if game.tick==0 then return end
  check(game.get_surface(storage.deleted_surface)==nil,'collector surface survived deletion')
  helpers.write_file('factorio-tests/fulgora-pole-collectors.json',helpers.table_to_json{
    schema=1,case='fulgora-pole-collectors',status='pass',failure_count=0,
    assertions=storage.assertions,tick=game.tick,factorio_version=script.active_mods.base},false)
  script.on_nth_tick(60,nil); script.on_nth_tick(3610,nil)
end)

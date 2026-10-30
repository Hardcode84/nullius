-- given: a Fulgora sand fixture, hydrocarbon vents, 20 units per sink cell,
-- 500 sludge for magnetic recovery, one efficiency module, independent debug power,
-- three construction robots, and one extractor item of each tier for robot jobs.
-- place/connect: both extractor tiers in all rotations, connected input pipes;
-- a hydro plant on island ground, with product removal for ten recovery batches.
-- act: switch modes, build/clone/revive ghosts, apply research and upgrade rules.
-- run: 3600 ticks; expect: exact fluid consumption, no vent yield change,
-- restricted placement, unchanged pipe geometry, and bounded mineral outputs.
local fluids=require('__nullius-star__/scenarios/fluid-api')
local function check(ok,message)
  storage.assertions=storage.assertions+1
  assert(ok,message)
end
local function create(surface,name,x,y,extra)
  local args={name=name,position={x,y},force=game.forces.player}
  for k,v in pairs(extra or {}) do args[k]=v end
  local result=surface.create_entity(args)
  if not args.raise_built then assert(result,name) end
  return result
end
local function vent(surface,x,y)
  return create(surface,'nullius-hydrocarbon-vent',x,y,{amount=100000})
end
local function toggle(entity,name)
  local surface,p=entity.surface,entity.position
  check(remote.call('nullius-test-transitions','execute',entity),'missing toggle')
  return assert(surface.find_entity(name,p),'missing replacement '..name)
end
local function power(surface,x,y)
  local grid=create(surface,'factorio-test-planner-grid',x+6,y+5)
  grid.power_production=100000000
  grid.electric_buffer_size=100000000
  create(surface,'substation',x+5,y+2)
end
script.on_nth_tick(1,function()
  script.on_nth_tick(1,nil)
  storage.assertions=0
  storage.rows={}
  local surface=game.planets['nullius-fulgora'].create_surface()
  surface.request_to_generate_chunks({0,0},5); surface.force_generate_chunk_requests()
  for _,e in pairs(surface.find_entities_filtered{area={{-20,-20},{140,65}}}) do e.destroy() end
  local tiles={}
  for x=-20,140 do for y=-20,65 do
    tiles[#tiles+1]={name=y>=30 and 'fulgoran-rock' or 'nullius-fulgora-sediment',position={x,y}}
  end end
  surface.set_tiles(tiles,true)
  local force=game.forces.player
  local tech=force.technologies['nullius-primitive-filtration']
  check(not tech.researched,'research fixture')
  check(not force.recipes['nullius-magnetic-sludge-filtration'].enabled,'magnetic enabled early')
  check(not force.recipes['nullius-reinject-sludge'].enabled,'reinjection enabled early')
  local base='nullius-extractor-1'
  local mode=base..'-reinjection'
  vent(surface,0,40)
  local drill=create(surface,base,0,40)
  check(not remote.call('nullius-test-transitions','execute',drill),'locked transition')
  drill.destroy()
  create(surface,mode,0,40,{raise_built=true})
  check(surface.find_entity(base,{0,40})~=nil,'locked placement not downgraded')
  surface.find_entity(base,{0,40}).destroy()
  local ghost=create(surface,'entity-ghost',0,40,{inner_name=mode,raise_built=true})
  local ghosts=surface.find_entities_filtered{position={0,40},type='entity-ghost'}
  check(#ghosts==1 and ghosts[1].ghost_name==base,'locked ghost not downgraded')
  ghosts[1].destroy()
  tech.researched=true
  check(force.recipes['nullius-magnetic-sludge-filtration'].enabled,'magnetic unlock')
  check(not prototypes.recipe['nullius-boxed-magnetic-sludge-filtration'],'unexpected boxed random recovery')
  for _,fluid in ipairs({'filtered-hydrocarbons','sludge','wastewater','brine'}) do
    local name='nullius-reinject-'..fluid
    check(force.recipes[name].enabled,'reinjection unlock '..fluid)
    local product=prototypes.recipe[name].products[1]
    check(product.name=='nullius-gas-void' and product.independent_probability==0,'sink output probability')
    check(not prototypes.recipe['nullius-boxed-reinject-'..fluid],'unexpected boxed reinjection')
  end
  -- Invalid real and ghost placements refund exactly one item or remove the ghost.
  create(surface,mode,10,40,{raise_built=true})
  check(not surface.find_entity(mode,{10,40}),'off-vent machine survived')
  local dropped=surface.find_entities_filtered{type='item-entity',position={10,40},radius=6}
  check(#dropped==1 and dropped[1].stack.name==base and dropped[1].stack.count==1,'refund')
  create(surface,'entity-ghost',20,40,{inner_name=mode,raise_built=true})
  check(#surface.find_entities_filtered{position={20,40},type='entity-ghost'}==0,'off-vent ghost survived')
  -- Clone destinations use the same checks.
  local source=create(surface,mode,0,40,{raise_built=true})
  source.clone{position={25,40},surface=surface,force=force}
  check(not surface.find_entity(mode,{25,40}),'off-vent clone survived')
  vent(surface,30,40)
  source.clone{position={30,40},surface=surface,force=force}
  check(surface.find_entity(mode,{30,40})~=nil,'valid clone removed')
  local inventory=game.create_inventory(1)
  inventory[1].set_stack{name='blueprint'}
  inventory[1].create_blueprint{surface=surface,force=force,area={{-2,38},{2,42}}}
  local bp=inventory[1].get_blueprint_entities()
  check(#bp==1 and bp[1].name==mode,'blueprint lost mode')
  inventory.destroy()
  vent(surface,40,40)
  local revive=create(surface,'entity-ghost',40,40,{inner_name=mode,raise_built=true})
  revive.revive{raise_revive=true}
  check(surface.find_entity(mode,{40,40})~=nil,'revive lost mode')
  vent(surface,50,40)
  local tagged=create(surface,'entity-ghost',50,40,{inner_name=base,raise_built=true})
  tagged.tags={reinjection_test='keep'}
  check(remote.call('nullius-test-transitions','execute',tagged),'ghost switch')
  local switched=surface.find_entities_filtered{position={50,40},type='entity-ghost'}[1]
  check(switched.ghost_name==mode and switched.tags.reinjection_test=='keep','ghost lost mode or tags')
  switched.destroy()
  check(prototypes.entity[mode].next_upgrade.name=='nullius-extractor-2-reinjection','upgrade path')
  local upgraded=create(surface,'nullius-extractor-2-reinjection',40,40,{fast_replace=true,raise_built=true})
  check(upgraded.valid,'fast replacement failed')
  -- A vent on Nauvis must not admit the Fulgora mode.
  local nauvis=game.surfaces.nauvis
  vent(nauvis,0,0)
  create(nauvis,mode,0,0,{raise_built=true})
  check(not nauvis.find_entity(mode,{0,0}),'reinjection on Nauvis')
  local names={'filtered-hydrocarbons','sludge','wastewater','brine'}
  local directions={defines.direction.north,defines.direction.east,defines.direction.south,defines.direction.west}
  for tier=1,2 do for i,fluid in ipairs(names) do
    local x=(i-1)*30
    local y=(tier-1)*15
    local resource=vent(surface,x,y)
    local b='nullius-extractor-'..tier
    local name=b..'-reinjection'
    check(surface.can_place_entity{name=name,position={x,y},force=force,
      build_check_type=defines.build_check_type.manual_ghost},'sand placement')
    local d=create(surface,b,x,y,{direction=directions[i]})
    d.health=100
    if tier==1 and i==1 then
      check(d.get_module_inventory().insert{name='nullius-efficiency-module-1',count=1}==1,'module fixture')
      local pole=create(surface,'small-electric-pole',x-3,y)
      check(d.get_wire_connector(defines.wire_connector_id.circuit_red,true).connect_to(
        pole.get_wire_connector(defines.wire_connector_id.circuit_red,true)),'wire fixture')
    end
    local connection=fluids.connections(d,1)[1].target_position
    local m=toggle(d,name)
    check(m.health==100,'health changed')
    if tier==1 and i==1 then
      check(m.get_wire_connector(defines.wire_connector_id.circuit_red,false).connection_count==1,'lost circuit wire')
      local refunds=surface.find_entities_filtered{type='item-entity',position={x,y},radius=5}
      check(#refunds==1 and refunds[1].stack.name=='nullius-efficiency-module-1' and refunds[1].stack.count==1,'lost installed module')
    end
    check(m.direction==directions[i],'direction changed')
    local target=fluids.connections(m,1)[1].target_position
    check(target.x==connection.x and target.y==connection.y,'pipe moved')
    m.set_recipe('nullius-reinject-'..fluid)
    check(m.get_recipe().name=='nullius-reinject-'..fluid,'recipe unavailable')
    check(m.insert_fluid{name='nullius-benzene',amount=20}==0,'sink accepted benzene')
    local pipe=create(surface,'pipe',target.x,target.y)
    check(pipe.insert_fluid{name='nullius-'..fluid,amount=20}==20,'input fixture')
    power(surface,x,y)
    storage.rows[#storage.rows+1]={machine=m,pipe=pipe,resource=resource,amount=resource.amount}
    local recipe=prototypes.recipe['nullius-reinject-'..fluid]
    check(recipe.energy==2 and recipe.ingredients[1].amount==20,'sink recipe rate')
    check(not recipe.allowed_effects.productivity,'sink productivity')
    check(m.crafting_speed==1,'tier changed sink speed')
    check(m.get_module_inventory()==nil or #m.get_module_inventory()==0,'module slots')
  end end
  local hydro=create(surface,'nullius-hydro-plant-1',70,45)
  hydro.set_recipe('nullius-magnetic-sludge-filtration')
  local recipe=prototypes.recipe['nullius-magnetic-sludge-filtration']
  check(not recipe.allowed_effects.productivity,'magnetic productivity')
  check(#recipe.products==6,'magnetic products')
  for _,p in pairs(recipe.products) do
    local expected=(p.name=='nullius-crushed-iron-ore' or p.name=='nullius-crushed-bauxite') and 1/3 or 1/6
    check(p.amount==3 and math.abs(p.independent_probability-expected)<1e-6,'magnetic probability '..p.name)
  end
  storage.sludge=500
  power(surface,70,45)
  storage.hydro=hydro
  -- Given: one extractor item and a powered roboport with construction robots.
  local port=create(surface,'roboport',100,50)
  port.insert{name='construction-robot',count=3}
  local chest=create(surface,'passive-provider-chest',104,54)
  chest.insert{name='nullius-extractor-1',count=1}
  chest.insert{name='nullius-extractor-2',count=1}
  power(surface,100,50)
  vent(surface,120,45)
  create(surface,'entity-ghost',120,45,{inner_name=mode,raise_built=true})
  storage.surface=surface
end)
script.on_nth_tick(60,function()
  if not storage.rows then return end
  if game.tick==60 then
    for _,row in ipairs(storage.rows) do check(row.machine.products_finished==0,'sink faster than two seconds') end
  end
  if storage.hydro and storage.hydro.valid then
    storage.hydro.get_output_inventory().clear()
    if storage.sludge>0 then
      storage.sludge=storage.sludge-storage.hydro.insert_fluid{name='nullius-sludge',amount=storage.sludge}
    end
  end
  if game.tick==2400 then
    local built=storage.surface.find_entity('nullius-extractor-1-reinjection',{120,45})
    check(built~=nil,'robot did not build reinjector')
    local planner=game.create_inventory(1)
    planner[1].set_stack{name='upgrade-planner'}
    storage.surface.upgrade_area{area={{118,43},{122,47}},force=game.forces.player,item=planner[1]}
    local target=built.get_upgrade_target()
    check(target and target.name=='nullius-extractor-2-reinjection','robot upgrade target')
    planner.destroy()
  end
  if game.tick~=3600 then return end
  for _,row in ipairs(storage.rows) do
    check(row.machine.products_finished==1,'sink batch count')
    check(row.pipe.get_fluid_count()==0 and row.machine.get_fluid_count()==0,'unconsumed fluid')
    check(row.resource.amount==row.amount,'reinjection changed vent yield')
    check(row.machine.get_output_inventory().is_empty(),'sink produced items')
    local base=row.machine.name:gsub('%-reinjection$','')
    local drill=toggle(row.machine,base)
    check(drill.valid and drill.health==100,'return to extraction')
  end
  check(storage.hydro.products_finished==10,'magnetic batch count')
  check(storage.surface.find_entity('nullius-extractor-2-reinjection',{120,45})~=nil,'robot did not upgrade reinjector')
  helpers.write_file('factorio-tests/fulgora-reinjection.json',helpers.table_to_json{
    schema=1,case='fulgora-reinjection',status='pass',failure_count=0,assertions=storage.assertions,
    tick=game.tick,factorio_version=script.active_mods.base},false)
end)

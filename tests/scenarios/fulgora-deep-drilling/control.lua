-- given: Fulgora vents, debug electricity, oxygen and sulfuric acid; no copper.
-- place/connect: both extractor tiers in four rotations with output pipes;
-- ordinary and boxed processing lines, and robots supplied with extractor items.
-- act: switch, blueprint, clone, revive and upgrade deep extractors. Transfer
-- only measured intermediate output between the declared processing machines.
-- run: 7200 ticks; boxed batches cross four tier-1 machines. Expect copper production, fixed vent rates and lifecycle parity.
local fluids=require('__nullius-star__/scenarios/fluid-api')
local function check(ok,message)
  storage.assertions=storage.assertions+1
  assert(ok,message)
end
local function create(surface,name,x,y,extra)
  local args={name=name,position={x,y},force=game.forces.player}
  for k,v in pairs(extra or {}) do args[k]=v end
  local entity=surface.create_entity(args)
  if not args.raise_built then assert(entity,name) end
  return entity
end
local function vent(s,x,y,amount)
  return create(s,'nullius-hydrocarbon-vent',x,y,{amount=amount or 100000})
end
local function toggle(entity,name)
  local s,p=entity.surface,entity.position
  check(remote.call('nullius-test-transitions','execute',entity),'transition rejected')
  return assert(s.find_entity(name,p),'missing '..name)
end
local function power(s,x,y)
  local grid=create(s,'factorio-test-planner-grid',x+6,y+5)
  grid.power_production=100000000
  grid.electric_buffer_size=100000000
  create(s,'substation',x+5,y+2)
end
script.on_nth_tick(1,function(event)
  if event.tick==0 then return end
  script.on_nth_tick(1,nil)
  storage.assertions=0
  storage.rows={}
  local s=game.planets['nullius-fulgora'].create_surface()
  s.request_to_generate_chunks({0,0},5);s.force_generate_chunk_requests()
  for _,e in pairs(s.find_entities_filtered{area={{-20,-20},{150,130}}}) do e.destroy() end
  local tiles={}
  for x=-20,150 do for y=-20,130 do
    tiles[#tiles+1]={name=y<30 and 'nullius-fulgora-sediment' or 'fulgoran-rock',position={x,y}}
  end end
  s.set_tiles(tiles,true)
  storage.surface=s
  local force=game.forces.player
  force.technologies['nullius-primitive-filtration'].researched=true
  local base='nullius-extractor-1'
  local inject,deep=base..'-reinjection',base..'-deep'
  vent(s,0,45)
  local drill=create(s,base,0,45)
  drill=toggle(toggle(drill,inject),base)
  drill.destroy()
  create(s,deep,0,45,{raise_built=true})
  check(s.find_entity(base,{0,45})~=nil,'locked placement not extraction')
  s.find_entity(base,{0,45}).destroy()
  create(s,'entity-ghost',0,45,{inner_name=deep,raise_built=true})
  local ghost=s.find_entities_filtered{position={0,45},type='entity-ghost'}[1]
  check(ghost.ghost_name==base,'locked ghost not extraction');ghost.destroy()
  force.technologies['nullius-copper-production'].researched=true
  check(not force.recipes['nullius-copper-solution'].enabled,'ore flotation unlocked without ore')
  for _,name in ipairs({'deep-drilling','deep-slurry-filtration','copper-roasting','copper-leaching',
      'boxed-deep-slurry-filtration','boxed-copper-roasting','boxed-copper-leaching'}) do
    check(force.recipes['nullius-'..name].enabled,'missing unlock '..name)
  end
  create(s,deep,10,45,{raise_built=true})
  check(not s.find_entity(deep,{10,45}),'off-vent placement')
  create(s,'entity-ghost',20,45,{inner_name=deep,raise_built=true})
  check(#s.find_entities_filtered{position={20,45},type='entity-ghost'}==0,'off-vent ghost')
  local source=create(s,deep,0,45,{raise_built=true})
  source.clone{position={25,45},surface=s,force=force}
  check(not s.find_entity(deep,{25,45}),'off-vent clone')
  vent(s,30,45)
  source.clone{position={30,45},surface=s,force=force}
  check(s.find_entity(deep,{30,45})~=nil,'valid clone')
  local inventory=game.create_inventory(1)
  inventory[1].set_stack{name='blueprint'}
  inventory[1].create_blueprint{surface=s,force=force,area={{-2,43},{2,47}}}
  check(inventory[1].get_blueprint_entities()[1].name==deep,'blueprint lost mode')
  inventory.destroy()
  vent(s,40,45)
  create(s,'entity-ghost',40,45,{inner_name=deep,raise_built=true}).revive{raise_revive=true}
  check(s.find_entity(deep,{40,45})~=nil,'revive lost mode')
  vent(s,50,45)
  local g=create(s,'entity-ghost',50,45,{inner_name=inject,raise_built=true})
  g.tags={deep_test='keep'}
  check(remote.call('nullius-test-transitions','execute',g),'ghost transition')
  g=s.find_entities_filtered{position={50,45},type='entity-ghost'}[1]
  check(g.ghost_name==deep and g.tags.deep_test=='keep','ghost lost tags');g.destroy()
  check(prototypes.entity[deep].next_upgrade.name=='nullius-extractor-2-deep','upgrade path')
  create(s,'nullius-extractor-2-deep',40,45,{fast_replace=true,raise_built=true})
  local other=game.surfaces.nauvis
  vent(other,0,0)
  create(other,deep,0,0,{raise_built=true})
  check(not other.find_entity(deep,{0,0}),'mode on Nauvis')
  local vulcanus=game.planets['nullius-vulcanus'].create_surface()
  create(vulcanus,'sulfuric-acid-geyser',0,0,{amount=100000})
  local gas_drill=create(vulcanus,base,0,0)
  check(not remote.call('nullius-test-transitions','execute',gas_drill),'mode on Vulcanus gas vent')
  local directions={defines.direction.north,defines.direction.east,defines.direction.south,defines.direction.west}
  for tier=1,2 do for i,direction in ipairs(directions) do
    local x,y=(i-1)*30,(tier-1)*15
    local resource=vent(s,x,y,tier*100000)
    local b='nullius-extractor-'..tier
    check(s.can_place_entity{name=b..'-deep',position={x,y},force=force,
      build_check_type=defines.build_check_type.manual_ghost},'sand placement')
    local d=create(s,b,x,y,{direction=direction})
    local pos=fluids.connections(d,1)[1].target_position
    d=toggle(toggle(d,b..'-reinjection'),b..'-deep')
    local target=fluids.connections(d,1)[1].target_position
    check(target.x==pos.x and target.y==pos.y,'pipe moved')
    check(d.direction==direction,'direction moved')
    check(d.get_recipe().name=='nullius-deep-drilling','missing fixed recipe')
    check(d.crafting_speed==1,'tier changed speed')
    check(not d.get_module_inventory() or #d.get_module_inventory()==0,'module slots')
    local pipe=create(s,'pipe',target.x,target.y)
    power(s,x,y)
    storage.rows[#storage.rows+1]={machine=d,pipe=pipe,resource=resource,amount=resource.amount}
  end end
  -- Each line consumes deep slurry measured from the connected output pipes.
  storage.lines={}
  for i,boxed in ipairs({false,true}) do
    local x=(i-1)*70
    local prefix=boxed and 'boxed-' or ''
    local line={boxed=boxed}
    for j,spec in ipairs({{'filter','nullius-hydro-plant-1','deep-slurry-filtration'},
        {'roast','nullius-chemical-plant-1','copper-roasting'},
        {'leach','nullius-flotation-cell-1','copper-leaching'},
        {'electrolysis','nullius-priority-electrolyzer-1','copper-ingot'}}) do
      local machine=create(s,spec[2],x+(j-1)*15,80)
      machine.set_recipe('nullius-'..prefix..spec[3])
      check(machine.get_recipe()~=nil,'recipe rejected '..spec[3])
      power(s,x+(j-1)*15,80)
      line[spec[1]]=machine
    end
    storage.lines[#storage.lines+1]=line
  end
  local port=create(s,'roboport',100,50)
  port.insert{name='construction-robot',count=3}
  local chest=create(s,'passive-provider-chest',104,54)
  chest.insert{name=base,count=1};chest.insert{name='nullius-extractor-2',count=1}
  power(s,100,50)
  vent(s,120,45)
  create(s,'entity-ghost',120,45,{inner_name=deep,raise_built=true})
end)
local function move_fluid(from,to,name)
  local available=from.get_fluid_count(name)
  if available<=0 then return end
  local amount=to.insert_fluid{name=name,amount=available}
  if amount<=0 then return end
  local removed=from.extract_fluid{name=name,amount=amount}
  check(math.abs(removed-amount)<0.001,'fluid transfer lost output')
end
local function move_item(from,to,name)
  local output=from.get_output_inventory()
  local count=output.get_item_count(name)
  if count==0 then return end
  local n=to.insert{name=name,count=count}
  check(output.remove{name=name,count=n}==n,'item transfer lost output')
end
script.on_nth_tick(60,function(event)
  if event.tick==0 then return end
  for _,row in ipairs(storage.rows) do
    local target=storage.lines[_<=4 and 1 or 2].filter
    move_fluid(row.pipe,target,'nullius-deep-slurry')
    -- Surplus measured slurry is discarded to keep the rate witness unblocked.
    row.pipe.clear_fluid_inside()
  end
  for _,line in ipairs(storage.lines) do
    local prefix=line.boxed and 'box-' or ''
    line.roast.insert_fluid{name='nullius-'..(line.boxed and 'compressed-oxygen' or 'oxygen'),amount=100}
    line.leach.insert_fluid{name='nullius-acid-sulfuric',amount=100}
    move_item(line.filter,line.roast,'nullius-'..prefix..'copper-concentrate')
    move_item(line.roast,line.leach,'nullius-'..prefix..'copper-calcine')
    move_fluid(line.leach,line.electrolysis,'nullius-copper-solution')
    line.filter.extract_fluid{name='nullius-sludge',amount=10000}
    line.filter.extract_fluid{name='nullius-filtered-hydrocarbons',amount=10000}
    line.filter.get_output_inventory().remove{name='nullius-'..prefix..'salt',count=1000}
    line.roast.extract_fluid{name='nullius-sulfur-dioxide',amount=10000}
    line.leach.extract_fluid{name='nullius-sludge',amount=10000}
    line.leach.get_output_inventory().remove{name='nullius-'..prefix..'iron-oxide',count=1000}
    line.electrolysis.extract_fluid{name='nullius-wastewater',amount=10000}
  end
  if event.tick==2400 then
    local built=storage.surface.find_entity('nullius-extractor-1-deep',{120,45})
    check(built~=nil,'robot did not build deep mode')
    local planner=game.create_inventory(1);planner[1].set_stack{name='upgrade-planner'}
    storage.surface.upgrade_area{area={{118,43},{122,47}},force=game.forces.player,item=planner[1]}
    check(built.get_upgrade_target().name=='nullius-extractor-2-deep','robot upgrade target')
    planner.destroy()
  end
  if event.tick~=7200 then return end
  local count=storage.rows[1].machine.products_finished
  check(count>=118,'deep extraction rate')
  for _,row in ipairs(storage.rows) do
    check(row.machine.products_finished==count,'tier, rotation or yield changed output')
    check(row.resource.amount==row.amount,'deep drilling changed vent yield')
    check(toggle(row.machine,row.machine.name:gsub('%-deep$','')).type=='mining-drill','return to extraction')
  end
  for _,line in ipairs(storage.lines) do
    local product='nullius-'..(line.boxed and 'box-' or '')..'copper-ingot'
    log(helpers.table_to_json{boxed=line.boxed,filter=line.filter.products_finished,roast=line.roast.products_finished,leach=line.leach.products_finished,electrolysis=line.electrolysis.products_finished})
    check(line.electrolysis.get_output_inventory().get_item_count(product)>0,'no '..product)
    check(game.forces.player.get_item_production_statistics(storage.surface).get_input_count(product)>0,'no copper production statistics')
  end
  check(storage.surface.find_entity('nullius-extractor-2-deep',{120,45})~=nil,'robot did not upgrade deep mode')
  helpers.write_file('factorio-tests/fulgora-deep-drilling.json',helpers.table_to_json{
    schema=1,case='fulgora-deep-drilling',status='pass',failure_count=0,assertions=storage.assertions,
    tick=event.tick,factorio_version=script.active_mods.base},false)
end)

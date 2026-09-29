-- given: 32 starter poles, four coils, four batteries, 500 kW debug load;
-- 20 bricks, 20 aluminum wire, 10 aluminum plate, assembler and isolated 2 MW debug source.
-- place/connect: four coils 42 tiles apart, 32 poles around them; real wind spacing comparison.
-- act: seed each collector with 200 MJ, remove protection, reset, clone/move/mine coils, revive a ghost.
-- expect: native protection, sand-only placement, wind spacing parity, no orphan fields, craft one coil.
local NAME='nullius-grounding-coil'
local PREFIX='nullius-grounding-collision-'
local function check(ok,msg) storage.assertions=storage.assertions+1;assert(ok,msg) end
local function tiles(x,y,r,name)
  local list={};for dx=-r,r do for dy=-r,r do list[#list+1]={name=name,position={x+dx,y+dy}} end end
  storage.surface.set_tiles(list,true)
end
local function place(name,x,y,raised)
  return assert(storage.surface.create_entity{name=name,position={x,y},force='player',raise_built=raised})
end
local function can(name,x,y)
  return storage.surface.can_place_entity{name=name,position={x,y},force='player'}
end
local function field_count(x,y)
  return storage.surface.count_entities_filtered{name={PREFIX..'horizontal',PREFIX..'vertical'},
    area={{x-32,y-32},{x+32,y+32}}}
end
script.on_nth_tick(1,function()
  if game.tick==0 then return end
  script.on_nth_tick(1,nil)
  if storage.surface then storage.observations.reload_tick=game.tick;return end
  storage.assertions=0;storage.observations={}
  local s=game.planets['nullius-fulgora'].create_surface();storage.surface=s
  s.request_to_generate_chunks({300,0},13);s.force_generate_chunk_requests()
  for _,e in pairs(s.find_entities()) do e.destroy() end
  for x=-32,650,32 do tiles(x,0,40,'nullius-fulgora-sediment') end
  storage.coils={}
  for _,p in ipairs({{0,0},{42,0},{0,42},{42,42}}) do
    tiles(p[1],p[2],3,'nullius-fulgora-sediment')
    check(can(NAME,p[1],p[2]),'starter coil placement')
    storage.coils[#storage.coils+1]=place(NAME,p[1],p[2],true)
  end
  storage.poles={}
  for i=0,7 do
    for _,p in ipairs({{2+i*6,2},{2+i*6,44},{-4,2+i*6},{50,2+i*6}}) do
      storage.poles[#storage.poles+1]=place('small-electric-pole',p[1],p[2],true)
    end
  end
  local network=storage.poles[1].electric_network_id
  for _,pole in ipairs(storage.poles) do
    check(pole.electric_network_id==network,'starter pole disconnected')
    local collector=s.find_entities_filtered{name='nullius-pole-lightning-collector',position=pole.position,radius=0.1}[1]
    check(collector~=nil,'collector missing')
    collector.energy=collector.electric_buffer_size
  end
  storage.load=place('factorio-test-trip-load',2,1,false)
  for i=1,4 do place('factorio-test-trip-load',2,1,false) end
  storage.batteries={}
  for i=0,3 do
    local x=8+i*6
    tiles(x,5,2,'fulgoran-rock')
    check(can('nullius-grid-battery-1',x,5),'battery placement is not legal')
    storage.batteries[#storage.batteries+1]=place('nullius-grid-battery-1',x,5,false)
  end
  storage.spacing=place(NAME,200,0,true)
  check(field_count(200,0)==4,'coil spacing field count')
  tiles(400,0,40,'fulgoran-rock')
  s.create_entity{name='nullius-wind-build-1',position={400,0},force='player',raise_built=true}
  check(s.count_entities_filtered{name='nullius-wind-base-1',position={400,0},radius=1}==1,'wind turbine not built')
  for _,offset in ipairs({{16,0},{31,0},{32,0},{0,31},{0,32},{31,31},{32,32}}) do
    check(can(NAME,200+offset[1],offset[2])==can('nullius-wind-build-1',400+offset[1],offset[2]),
      'wind spacing differs')
  end
  check(not can(NAME,216,0) and can(NAME,232,0),'spacing boundary')
  tiles(216,0,2,'fulgoran-rock')
  check(not can('nullius-wind-build-1',216,0),'coil must exclude wind turbine')
  tiles(416,0,2,'nullius-fulgora-sediment')
  check(not can(NAME,416,0),'wind turbine must exclude coil')
  tiles(450,0,3,'fulgoran-rock')
  check(not can(NAME,450,0),'coil allowed on island')
  check(can('small-electric-pole',205,0) and can('pipe',206,0),'field blocks ordinary logistics')
  storage.moved=storage.spacing.clone{position={300,0},surface=s,force='player'}
  check(field_count(300,0)==4,'clone fields missing')
  tiles(300,70,3,'nullius-fulgora-sediment')
  storage.moved.teleport({300,70},nil,true)
  check(field_count(300,0)==0 and field_count(300,70)==4,'moved field remained')
  storage.moved.destroy()
  -- Actual recipe execution and boxed parity.
  game.forces.player.technologies['nullius-primitive-filtration'].researched=true
  check(game.forces.player.recipes[NAME].enabled,'arrival unlock missing')
  tiles(550,0,12,'fulgoran-rock')
  storage.assembler=place('nullius-small-assembler-1',550,0,false)
  storage.assembler.set_recipe(NAME)
  for _,stack in ipairs({{'stone-brick',20},{'nullius-aluminum-wire',20},{'nullius-aluminum-plate',10}}) do
    storage.assembler.insert{name=stack[1],count=stack[2]}
  end
  place('factorio-test-trip-pole',550,3,false);place('factorio-test-trip-source-2000000',551,2,false)
  local bulk=prototypes.recipe['nullius-boxed-grounding-coil']
  local ordinary=prototypes.recipe[NAME]
  local ordinary_amounts={}
  for _,ingredient in ipairs(ordinary.ingredients) do ordinary_amounts[ingredient.name]=ingredient.amount end
  for _,ingredient in ipairs(bulk.ingredients) do
    local product=prototypes.recipe[ingredient.name:gsub('^nullius%-box%-','nullius-unbox-')].products[1]
    assert(ordinary_amounts[product.name], 'unexpected unboxed material: '..product.name)
    check(product.amount*ingredient.amount==ordinary_amounts[product.name]*5,'boxed material parity: '..product.name)
  end
end)
script.on_nth_tick(30,function()
  if game.tick==0 then return end
  if game.tick==60 then
    check(not remote.call('nullius-test-overload','offline',storage.poles[1]),'protected starter tripped')
    check(storage.load.energy>0,'protected starter unpowered')
    check(field_count(300,70)==0,'destroyed coil fields remained')
    storage.surface.clone_area{source_area={{168,-32},{232,32}},destination_area={{568,68},{632,132}},
      destination_surface=storage.surface,clone_tiles=true,clone_entities=true,clone_decoratives=false,expand_map=true}
    check(field_count(600,100)==4,'area clone duplicated fields')
  elseif game.tick==600 then
    for _,battery in ipairs(storage.batteries) do check(battery.energy>0,'starter battery did not charge') end
    check(storage.assembler.crafting_progress>0 or storage.assembler.products_finished==1,'grounding recipe did not start')
    check(not remote.call('nullius-test-overload','offline',storage.poles[1]),'protected grid tripped later')
    storage.inventory=game.create_inventory(10)
    for _,coil in ipairs(storage.coils) do check(coil.mine{inventory=storage.inventory,raise_destroyed=true},'mine coil') end
    check(storage.inventory.get_item_count(NAME)==4,'mining did not return four coils')
  elseif game.tick==660 then
    check(remote.call('nullius-test-overload','offline',storage.poles[1]),'removing protection did not trip')
    local ghost=storage.surface.create_entity{name='entity-ghost',inner_name=NAME,position={0,0},force='player'}
    local _,coil=ghost.revive{raise_revive=true};check(coil~=nil,'coil ghost revival')
    check(field_count(0,0)==4,'revived fields missing')
  elseif game.tick==1290 then
    check(storage.assembler.products_finished==1,'grounding recipe did not craft')
    helpers.write_file('factorio-tests/fulgora-grounding-coils.json',helpers.table_to_json{
      schema=1,case='fulgora-grounding-coils',status='pass',failure_count=0,assertions=storage.assertions,
      tick=game.tick,observations=storage.observations,factorio_version=script.active_mods.base},false)
    script.on_nth_tick(30,nil)
  end
end)

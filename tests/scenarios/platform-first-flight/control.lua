-- given: a starter platform; 160 loose foundations, 4 foundation boxes,
-- 64 hydrogen-canister boxes, 10 iron plates, one thruster, chemical plant,
-- boxer, two solar panels, two inserters, and four pipes as finite cargo.
-- place: tile and entity ghosts; the platform builds them from hub cargo.
-- connect: solar-powered mirrored chemistry to both thruster fluids; inserters
-- carry canisters from the hub and return empties. A powered boxer unpacks cargo.
-- act: fly to Vulcanus, drop the plates without a landing pad, return to Nauvis,
-- and drop the empty canister boxes. No propellant is supplied on Vulcanus.
-- expect: real construction, packaging, conditioning, solar power, both trips,
-- and cargo pods on both destination surfaces with conserved cargo.
local CASE='platform-first-flight'
local function check(ok,msg) storage.assertions=storage.assertions+1;assert(ok,msg) end
local function entity(name,x,y)
 return storage.platform.surface.find_entity(name,{x,y})
end
local function drop(name,count,surface)
 local inv=storage.hub.get_inventory(defines.inventory.hub_main)
 check(inv.remove{name=name,count=count}==count,'remove cargo '..name)
 local pod=assert(storage.hub.create_cargo_pod())
 check(pod.get_inventory(defines.inventory.cargo_unit).insert{name=name,count=count}==count,'load cargo pod')
 pod.cargo_pod_destination={type=defines.cargo_destination.surface,surface=surface,position={0,0}}
 return pod
end
script.on_init(function()
 storage.assertions=0
 local force=game.create_force(CASE)
 force.technologies['nullius-orbital-construction'].researched=true
 check(force.is_space_platforms_unlocked(),'platform creation enabled')
 force.unlock_space_location('nullius-vulcanus')
 local platform=assert(force.create_space_platform{name=CASE,planet='nauvis',starter_pack='space-platform-starter-pack'})
 storage.platform=platform;storage.hub=assert(platform.apply_starter_pack(true))
 local inv=storage.hub.get_inventory(defines.inventory.hub_main)
 for name,count in pairs{['space-platform-foundation']=160,['nullius-box-space-platform-foundation']=4,
  ['nullius-box-hydrogen-canister']=64,['iron-plate']=10,['thruster']=1,['nullius-chemical-plant-1']=1,
  ['nullius-boxer']=1,['nullius-solar-panel-1']=2,['inserter']=2,['pipe']=4} do
  check(inv.insert{name=name,count=count}==count,'finite cargo '..name)
 end
 for x=-13,4 do for y=-5,8 do
  if platform.surface.get_tile(x,y).name~='space-platform-foundation' then
  assert(platform.surface.create_entity{name='tile-ghost',inner_name='space-platform-foundation',position={x,y},force=force})
  end
 end end
 local specs={
  {'thruster',0,6.5}, {'nullius-chemical-plant-1',-5.5,5.5,defines.direction.west,true},
  {'nullius-solar-panel-1',-11,-3}, {'nullius-solar-panel-1',-11,2},
  {'nullius-boxer',-5.5,2.5}, {'inserter',-4.5,3.5}, {'inserter',-5.5,3.5},
  {'pipe',-3.5,4.5}, {'pipe',-2.5,4.5}, {'pipe',-3.5,6.5}, {'pipe',-2.5,6.5},
 }
 storage.specs=specs
 for _,s in ipairs(specs) do
  assert(platform.surface.create_entity{name='entity-ghost',inner_name=s[1],position={s[2],s[3]},force=force,
   direction=s[4],mirror=s[5]})
 end
 storage.phase='build'
end)
script.on_nth_tick(30,function()
 local platform=storage.platform
 local inv=storage.hub.get_inventory(defines.inventory.hub_main)
 if storage.phase=='build' then
  for _,s in ipairs(storage.specs) do if not entity(s[1],s[2],s[3]) then
   if game.tick>=2400 then error(helpers.table_to_json{unbuilt=s,hub_position=storage.hub.position,hub_box=storage.hub.bounding_box,inventory=inv.get_contents(),ghosts=platform.surface.count_entities_filtered{type='entity-ghost'},tiles=platform.surface.count_entities_filtered{type='tile-ghost'}}) end
   return
  end end
  local placement={name='nullius-air-filter-1',position={-7.5,-2.5},force=storage.hub.force}
  platform.surface.ignore_surface_conditions=true
  local clear_site=platform.surface.can_place_entity(placement)
  platform.surface.ignore_surface_conditions=false
  check(clear_site,'air filter site has no collision')
  check(not platform.surface.can_place_entity(placement),'native vacuum placement rejection')
  storage.plant=entity('nullius-chemical-plant-1',-5.5,5.5)
  check(storage.plant.set_recipe('nullius-boxed-canister-propellant'),'condition boxed canisters')
  local input=entity('inserter',-4.5,3.5)
  input.pickup_position={-3.5,2.5};input.drop_position={-4.5,4.5}
  local output=entity('inserter',-5.5,3.5)
  output.pickup_position={-5.5,4.5};output.drop_position={-3.5,2.5}
  storage.boxer=entity('nullius-boxer',-5.5,2.5)
  check(inv.remove{name='nullius-box-space-platform-foundation',count=4}==4,'foundation boxes from cargo')
  check(storage.boxer.insert{name='nullius-box-space-platform-foundation',count=4}==4,'unpacking input')
  storage.thruster=entity('thruster',0,6.5)
  storage.phase='fuel'
 elseif storage.phase=='fuel' then
  if storage.thruster.get_fluid_count('thruster-fuel')<800 or storage.thruster.get_fluid_count('thruster-oxidizer')<800 then
   if game.tick>=3600 then error(helpers.table_to_json{plant=storage.plant.status,energy=storage.plant.energy,
    recipe=storage.plant.get_recipe().name,inputs=storage.plant.get_inventory(defines.inventory.crafter_input).get_contents(),
    fuel=storage.thruster.get_fluid_count('thruster-fuel'),oxidizer=storage.thruster.get_fluid_count('thruster-oxidizer')}) end
   return
  end
  check(storage.boxer.get_item_count('space-platform-foundation')==20,'boxed foundation output')
  platform.schedule={current=1,records={{station='nullius-vulcanus'}}};platform.paused=false
  storage.phase='outbound'
 elseif storage.phase=='outbound' and platform.space_location and platform.space_location.name=='nullius-vulcanus' then
  storage.arrival=game.tick
  local planet=game.planets['nullius-vulcanus'];storage.destination=planet.surface or planet.create_surface()
  storage.destination.request_to_generate_chunks({0,0},1);storage.destination.force_generate_chunk_requests()
  check(storage.destination.count_entities_filtered{name='cargo-landing-pad'}==0,'no landing pad')
  storage.delivery=drop('iron-plate',10,storage.destination)
  storage.phase='delivery'
 elseif storage.phase=='delivery' then
  if storage.delivery.valid and storage.delivery.surface==storage.destination then
   check(storage.delivery.get_inventory(defines.inventory.cargo_unit).get_item_count('iron-plate')==10,'delivered plates')
   platform.schedule={current=1,records={{station='nauvis'}}};platform.paused=false
   storage.phase='return'
  end
 elseif storage.phase=='return' and platform.space_location and platform.space_location.name=='nauvis' then
  -- Stop feeding after the trip, then return only the empty boxes already in the hub.
  entity('inserter',-4.5,3.5).disabled_by_script=true
  storage.empties=inv.get_item_count('nullius-box-canister')
  check(storage.empties>0,'empty canisters returned by inserter')
  storage.return_pod=drop('nullius-box-canister',storage.empties,game.surfaces.nauvis)
  storage.phase='drop-empties'
 elseif storage.phase=='drop-empties' and storage.return_pod.valid and storage.return_pod.surface==game.surfaces.nauvis then
  check(storage.return_pod.get_inventory(defines.inventory.cargo_unit).get_item_count('nullius-box-canister')==storage.empties,'empty canister drop')
  check(storage.plant.products_finished>0,'real propellant crafts')
  check(storage.plant.products_finished==storage.empties,'all completed batches return their empty canister boxes')
  check(platform.surface.count_entities_filtered{type='solar-panel'}==2,'solar power only')
  helpers.write_file('factorio-tests/'..CASE..'.json',helpers.table_to_json{schema=1,case=CASE,status='pass',assertions=storage.assertions,
   failure_count=0,tick=game.tick,factorio_version=script.active_mods.base,
   observations={outbound_arrival=storage.arrival,canister_boxes=storage.plant.products_finished,empty_boxes_returned=storage.empties}},false)
  script.on_nth_tick(30,nil)
 end
 if game.tick>=14970 then error(helpers.table_to_json{phase=storage.phase,speed=platform.speed,state=platform.state,paused=platform.paused,location=platform.space_location and platform.space_location.name,arrival=storage.arrival,plant_status=storage.plant.status,plant_crafts=storage.plant.products_finished,energy=storage.plant.energy,fuel=storage.thruster.get_fluid_count('thruster-fuel'),oxidizer=storage.thruster.get_fluid_count('thruster-oxidizer'),hub=inv.get_contents(),nauvis_unlocked=storage.hub.force.is_space_location_unlocked('nauvis')}) end
end)

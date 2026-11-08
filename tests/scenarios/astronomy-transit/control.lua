-- given: two starter platforms, each with finite 128 hydrogen-canister boxes.
-- place/connect: the Orbital Construction reference cell (two solar panels,
-- chemical plant, two inserters, four pipes, one thruster) on an 18x14 foundation.
-- act: fly from each remote planet to the other through Nauvis.
-- run: sample every 30 ticks; no stops, refuelling, infinity inputs, or extra cargo.
-- expect: both reference transits finish; recording lifetime covers the measured route.
local astronomy=require('__nullius-star__/shared/astronomy')
local CASE='astronomy-transit'
local function check(ok,msg) storage.assertions=storage.assertions+1;assert(ok,msg) end
script.on_init(function()
 storage.assertions=0;storage.rows={}
 local force=game.create_force(CASE)
 force.technologies['nullius-orbital-construction'].researched=true
 for _,planet in ipairs{'nauvis','nullius-vulcanus','nullius-fulgora'} do force.unlock_space_location(planet) end
 for _,from in ipairs{'nullius-vulcanus','nullius-fulgora'} do
  local target=from=='nullius-vulcanus' and 'nullius-fulgora' or 'nullius-vulcanus'
  local p=assert(force.create_space_platform{name=CASE..from,planet=from,starter_pack='space-platform-starter-pack'})
  local hub=p.apply_starter_pack(true);local inv=hub.get_inventory(defines.inventory.hub_main)
  check(inv.insert{name='nullius-box-hydrogen-canister',count=128}==128,'finite fuel')
  local surface=p.surface;local tiles={}
  for x=-13,4 do for y=-5,8 do tiles[#tiles+1]={name='space-platform-foundation',position={x,y}} end end
  surface.set_tiles(tiles)
  local entities={}
  for _,s in ipairs{{'thruster',0,6.5},{'nullius-chemical-plant-1',-5.5,5.5,defines.direction.west,true},
   {'nullius-solar-panel-1',-11,-3},{'nullius-solar-panel-1',-11,2},
   {'inserter',-4.5,3.5},{'inserter',-5.5,3.5},
   {'pipe',-3.5,4.5},{'pipe',-2.5,4.5},{'pipe',-3.5,6.5},{'pipe',-2.5,6.5}} do
   check(surface.can_place_entity{name=s[1],position={s[2],s[3]},direction=s[4],force=force},'reference placement '..s[1])
   entities[#entities+1]=assert(surface.create_entity{name=s[1],position={s[2],s[3]},direction=s[4],mirror=s[5],force=force})
  end
  entities[2].set_recipe('nullius-boxed-canister-propellant')
  entities[5].pickup_position={-3.5,2.5};entities[5].drop_position={-4.5,4.5}
  entities[6].pickup_position={-5.5,4.5};entities[6].drop_position={-3.5,2.5}
  storage.rows[#storage.rows+1]={platform=p,thruster=entities[1],plant=entities[2],target=target,from=from}
 end
end)
script.on_nth_tick(30,function()
 if game.tick==0 then return end
 local done=true
 for _,row in ipairs(storage.rows) do
  local p=row.platform
  if not row.departure and row.thruster.get_fluid_count('thruster-fuel')>=800 and row.thruster.get_fluid_count('thruster-oxidizer')>=800 then
   row.departure=game.tick;p.schedule={current=1,records={{station=row.target}}};p.paused=false
  end
  if row.departure and not row.duration and p.space_location and p.space_location.name==row.target then row.duration=game.tick-row.departure end
  done=done and row.duration~=nil
 end
 if done then
  local times={};local longest=0
  for _,row in ipairs(storage.rows) do
   times[row.from]=row.duration;longest=math.max(longest,row.duration)
   check(row.plant.products_finished>0,'onboard propellant')
  end
  local expected=math.ceil(longest*1.5)
  check(expected==astronomy.spoil_ticks,"reference transit sets recording lifetime")
  helpers.write_file('factorio-tests/'..CASE..'.json',helpers.table_to_json{schema=1,case=CASE,status='pass',tick=game.tick,
   failure_count=0,assertions=storage.assertions,factorio_version=script.active_mods.base,
   observations={transit_ticks=times,spoil_ticks=expected}},false)
  script.on_nth_tick(30,nil)
 end
 if game.tick>=12480 then
  local state={};for _,row in ipairs(storage.rows) do state[#state+1]={from=row.from,departure=row.departure,duration=row.duration,speed=row.platform.speed,state=row.platform.state,crafts=row.plant.products_finished} end
  error(helpers.table_to_json(state))
 end
end)

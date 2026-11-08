-- given: finite blanks, hydrogen, and pneumatic fuel; declared electric grids.
-- place/connect: production dishes, hydrogen pipes, and grid poles on three planets.
-- act: research, build four dishes, remove three, merge forces, and cross storm edges.
-- run: four short native crafting windows.
-- expect: locked planet recipes, spacing, proportional work and power, and media conservation.
local CASE='astronomy-array'
local spec=require('__nullius-star__/shared/astronomy')
local function check(ok,msg) storage.assertions=storage.assertions+1;assert(ok,msg) end
local function near(a,b,msg) check(math.abs(a-b)<0.04,msg..': '..a..' expected '..b) end
local function work(e) return e.products_finished+e.crafting_progress end
local function energy(e) return storage.poles[e.unit_number].electric_network_statistics.get_input_count(e.name) end
local function fuel() return storage.force.get_fluid_production_statistics(storage.pneumatic.surface).output_counts['nullius-compressed-volcanic-gas'] or 0 end
local function ground(name)
 local s=name=='nauvis' and game.surfaces.nauvis or game.planets['nullius-'..name].create_surface()
 s.request_to_generate_chunks({0,0},4);s.force_generate_chunk_requests()
 for _,e in pairs(s.find_entities()) do e.destroy() end
 local tiles={};for x=-120,120 do for y=-80,80 do tiles[#tiles+1]={name='grass-1',position={x,y}} end end
 s.set_tiles(tiles);s.freeze_daytime=true;s.daytime=0
 return s
end
local function dish(surface,x,y,force,pneumatic)
 local name=spec.dishes[pneumatic and 2 or 1]
 check(surface.can_place_entity{name=name,position={x,y},force=force},'legal dish site')
 local e=assert(surface.create_entity{name=name,position={x,y},force=force,raise_built=true})
 if e.get_recipe() then
  check(e.insert{name='nullius-blank-recording-module',count=50}==50,'finite media')
  local pipe=assert(surface.create_entity{name='pipe',position={x-1,y-2},force=force})
  check(pipe.insert_fluid{name='nullius-hydrogen',amount=50}==50,'finite maser hydrogen')
  if pneumatic then
   local gas=assert(surface.create_entity{name='pipe',position={x+1,y-2},force=force})
   check(gas.insert_fluid{name='nullius-compressed-volcanic-gas',amount=100}==100,'finite pneumatic fuel')
   check(e.insert_fluid{name='nullius-compressed-volcanic-gas',amount=900}==900,'finite machine fuel')
  else
   local grid=assert(surface.create_entity{name='factorio-test-planner-grid',position={x+7,y},force=force})
   grid.power_production=10000000;grid.electric_buffer_size=10000000
   local pole=assert(surface.create_entity{name='substation',position={x+4,y+4},force=force})
   storage.poles[e.unit_number]=pole
  end
 end
 return e
end
script.on_nth_tick(1,function()
 if game.tick~=1 then return end
 script.on_nth_tick(1,nil)
 storage.assertions=0;storage.surfaces={};storage.poles={};storage.observations={}
 for _,name in ipairs(spec.planets) do storage.surfaces[name]=ground(name) end
 local force=game.create_force('astronomy-array')
 storage.force=force
 storage.locked=dish(storage.surfaces.nauvis,0,0,force)
 check(storage.locked.get_recipe()==nil and storage.locked.recipe_locked,'locked before research '..tostring(storage.locked.get_recipe() and storage.locked.get_recipe().name)..' locked='..tostring(storage.locked.recipe_locked)..' enabled='..tostring(force.recipes[spec.recording('nauvis')].enabled))
 force.technologies['nullius-astronomy'].researched=true
 check(storage.locked.get_recipe().name==spec.recording('nauvis'),'research selects recipe')
 storage.locked.destroy{raise_destroy=true}
 storage.one=dish(storage.surfaces.nauvis,0,0,force)
 check(not storage.surfaces.nauvis.can_place_entity{name=spec.dishes[1],position={20,0},force=force},'dish spacing')
 check(storage.surfaces.nauvis.can_place_entity{name='nullius-small-assembler-1',position={20,0},force=force},'other buildings in gaps')
 check(storage.one.get_module_inventory()==nil or #storage.one.get_module_inventory()==0,'no modules')
 check(storage.one.recipe_locked,'recipe locked')
 force.technologies['nullius-vulcanus-radio-astronomy'].researched=true
 force.technologies['nullius-fulgora-radio-astronomy'].researched=true
 storage.pneumatic=dish(storage.surfaces.vulcanus,0,0,force,true)
 storage.storm=dish(storage.surfaces.fulgora,0,0,force)
 local platform=assert(force.create_space_platform{name=CASE,planet='nauvis',starter_pack='space-platform-starter-pack'})
 platform.apply_starter_pack(true)
 local tiles={};for x=10,15 do for y=0,5 do tiles[#tiles+1]={name='space-platform-foundation',position={x,y}} end end
 platform.surface.set_tiles(tiles)
 local orbital=assert(platform.surface.create_entity{name=spec.dishes[1],position={12.5,2.5},force=force,raise_built=true})
 check(not orbital.get_recipe() and orbital.recipe_locked and orbital.disabled_by_script,'no orbital recording')
end)
script.on_nth_tick(300,function()
 if game.tick==0 then return end
 local e=storage.one;local storm=storage.storm
 if game.tick==300 then
  near(work(e)-storage.baseline,4,'single dish work');near(work(storage.pneumatic)-storage.gasbaseline,4,'pneumatic work')
  near(storm.crafting_speed,0.75,'day interference')
  local watts=(energy(e)-storage.electric_start)/4
  local storm_watts=(energy(storm)-storage.storm_start)/4
  local gas=(fuel()-storage.fuel_start)/4
  storage.observations={full_power=watts,day_power=storm_watts,gas_per_second=gas}
  check(math.abs(watts-505000)<1000,'full operating power plus drain: '..watts)
  check(math.abs(storm_watts-380000)<1000,'day operating power plus drain: '..storm_watts)
  check(math.abs(gas-25)<0.1,'pneumatic fuel follows work: '..gas)
  storage.electric_start=energy(e)
  storage.start=work(e);storage.extra={};storage.pneumatic_extra={};storage.fuel_start=fuel()
  for _,p in ipairs{{64,0},{0,64},{64,64}} do
   storage.extra[#storage.extra+1]=dish(storage.surfaces.nauvis,p[1],p[2],storage.force)
   storage.pneumatic_extra[#storage.pneumatic_extra+1]=dish(storage.surfaces.vulcanus,p[1],p[2],storage.force,true)
  end
  near(e.crafting_speed,0.5,'four dishes share')
  near(e.consumption_bonus,-0.5,'power follows share')
  storage.surfaces.fulgora.daytime=0.5
 elseif game.tick==600 then
  local total=work(e)-storage.start;for _,v in ipairs(storage.extra) do total=total+work(v) end
  check(math.abs(total-10)<0.12,'four dishes twice one throughput: '..total)
  check(storm.disabled_by_script,'full interference stops');storage.stopped=work(storm)
  storage.storm_start=energy(storm)
  local gas=(fuel()-storage.fuel_start)/5
  check(math.abs(gas-50)<0.5,'four pneumatic dishes consume twice the fuel: '..gas)
  near(storage.pneumatic.consumption_bonus,-0.5,'pneumatic consumption effect')
  for _,v in ipairs(storage.pneumatic_extra) do v.destroy{raise_destroy=true} end
  local watts=(energy(e)-storage.electric_start)/5
  check(math.abs(watts-255000)<1000,'half-share operating power: '..watts)
  for _,v in ipairs(storage.extra) do v.destroy{raise_destroy=true} end
  storage.start=work(e)
 elseif game.tick==900 then
  near(work(storm),storage.stopped,'storm holds progress')
  local drain=(energy(storm)-storage.storm_start)/5
  storage.observations.stopped_drain=drain
  check(math.abs(drain-5000)<1,'stopped electrical drain: '..drain)
  near(e.crafting_speed,1,'removal restores share')
  near(work(e)-storage.start,5,'removed dishes no longer throttle')
  storage.surfaces.fulgora.daytime=0
  local other=game.create_force('radio-other');other.technologies['nullius-astronomy'].researched=true
  local otherdish=dish(storage.surfaces.nauvis,64,0,other)
  near(e.crafting_speed,1,'independent force');near(otherdish.crafting_speed,1,'other owner share')
  game.merge_forces(other,storage.force)
  storage.merge_pending=true
 else
  near(e.crafting_speed,1/math.sqrt(2),'merged array')
  check(not storm.disabled_by_script and work(storm)>storage.stopped,'day resumes progress')
  storage.force.technologies['nullius-fulgora-radio-astronomy'].researched=false
  check(storm.get_recipe()==nil and storm.disabled_by_script,'research reversal locks dish')
  remote.call('nullius-test-astronomy','rebuild')
  check(storage.surfaces.nauvis.count_entities_filtered{name='nullius-dish-collision-horizontal'}==4,'one field set per dish after rebuild')
  helpers.write_file('factorio-tests/'..CASE..'.json',helpers.table_to_json{schema=1,case=CASE,status='pass',tick=game.tick,
   failure_count=0,assertions=storage.assertions,factorio_version=script.active_mods.base,observations=storage.observations},false)
  script.on_nth_tick(300,nil)
 end
end)

script.on_nth_tick(60,function()
 if game.tick~=60 then return end
 storage.baseline=work(storage.one);storage.gasbaseline=work(storage.pneumatic)
 storage.electric_start=energy(storage.one);storage.storm_start=energy(storage.storm);storage.fuel_start=fuel()
 script.on_nth_tick(60,nil)
end)

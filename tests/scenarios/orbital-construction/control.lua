-- given: one exact ingredient batch per component, packaging, and propellant
-- recipe; electric test grids. No target products are supplied except the
-- declared foundation packaging and unpacking inputs.
-- place/connect: electric assemblers and chemical plants with output pipes.
-- act: research Orbital Construction; craft each recipe once.
-- expect: exact products; only Orbital Construction unlocks the components;
-- vanilla propellant and asteroid recipes stay disabled; conversion has no productivity.
local CASE='orbital-construction'
local fluids=require('__nullius-star__/scenarios/fluid-api')
local names={'space-platform-foundation','space-platform-starter-pack','cargo-bay','thruster',
 'nullius-box-space-platform-foundation','nullius-unbox-space-platform-foundation',
 'nullius-canister-propellant','nullius-boxed-canister-propellant','nullius-hydrogen-propellant','nullius-oxygen-propellant'}
local function check(ok,msg) storage.assertions=storage.assertions+1;assert(ok,msg) end
script.on_init(function()
 storage.assertions=0;storage.rows={}
 local force=game.create_force(CASE)
 local surface=game.surfaces.nauvis
 surface.request_to_generate_chunks({50,0},5);surface.force_generate_chunk_requests()
 for _,e in pairs(surface.find_entities_filtered{area={{-10,-10},{230,10}}}) do e.destroy() end
 local tiles={};for x=-10,230 do for y=-10,10 do tiles[#tiles+1]={name='grass-1',position={x,y}} end end
 surface.set_tiles(tiles)
 for _,name in ipairs(names) do check(not force.recipes[name].enabled,'locked '..name) end
 check(not force.is_space_platforms_unlocked(),'platform button locked')
 force.technologies['nullius-orbital-construction'].researched=true
 check(force.is_space_platforms_unlocked(),'platform button unlocked')
 check(force.is_space_location_unlocked('nauvis'),'home route unlocked')
 for index,name in ipairs(names) do
  check(force.recipes[name].enabled,'unlocked '..name)
  local owners={}
  for tn,t in pairs(prototypes.technology) do
   for _,effect in pairs(t.effects or {}) do
    if effect.type=='unlock-recipe' and effect.recipe==name then owners[#owners+1]=tn end
   end
  end
  check(#owners==1 and owners[1]=='nullius-orbital-construction','single unlock owner '..name)
  local recipe=prototypes.recipe[name]
  local chemistry=index>=7
  local x=(index-1)*24+0.5
  local function build(n,dx,dy) return assert(surface.create_entity{name=n,position={x+dx,0.5+dy},force=force}) end
  local machine=build(chemistry and 'nullius-chemical-plant-1' or (index>=5 and 'nullius-small-assembler-1' or 'nullius-large-assembler-1'),0,0)
  check(machine.set_recipe(name),'recipe '..name)
  local grid=build('factorio-test-planner-grid',7,0);grid.power_production=1e8;grid.electric_buffer_size=1e8
  build('substation',4,5)
  local row={machine=machine,recipe=name,outputs={}}
  for _,input in pairs(recipe.ingredients) do
   if input.type=='item' then check(machine.insert{name=input.name,count=input.amount}==input.amount,'input '..input.name)
   else check(machine.insert_fluid{name=input.name,amount=input.amount}==input.amount,'fluid input '..input.name) end
  end
  local oi=0
  for _,output in pairs(recipe.products) do
   if output.type=='fluid' then
    oi=oi+1
    for y=2,4 do local pipe=build('pipe',oi==1 and -1 or 1,y);row.outputs[output.name]=pipe end
   end
  end
  if index<=4 then check(recipe.maximum_productivity>0 and recipe.allowed_effects.productivity,'component productivity')
  else check(recipe.maximum_productivity==0,'conversion productivity') end
  storage.rows[#storage.rows+1]=row
 end
 for _,name in ipairs{'thruster-fuel','thruster-oxidizer'} do check(not prototypes.fluid[name].hidden,'visible '..name) end
 for _,name in ipairs{'thruster-fuel','thruster-oxidizer','advanced-thruster-fuel','advanced-thruster-oxidizer','asteroid-collector','crusher'} do
  check(not force.recipes[name].enabled and prototypes.recipe[name].hidden,'disabled vanilla '..name)
 end
end)
script.on_nth_tick(30,function()
 local done=true;for _,row in ipairs(storage.rows) do if row.machine.products_finished<1 then done=false end end
 if not done then return end
 for _,row in ipairs(storage.rows) do
  check(row.machine.products_finished==1,'one batch '..row.recipe)
  for _,output in pairs(prototypes.recipe[row.recipe].products) do
   local count=output.type=='fluid' and (fluids.segment_contents(row.outputs[output.name],1)[output.name] or 0) or row.machine.get_item_count(output.name)
   check(math.abs(count-output.amount)<0.001,'exact output '..row.recipe..' '..output.name..' '..count)
  end
 end
 helpers.write_file('factorio-tests/'..CASE..'.json',helpers.table_to_json{schema=1,case=CASE,status='pass',assertions=storage.assertions,
 failure_count=0,tick=game.tick,factorio_version=script.active_mods.base},false)
 script.on_nth_tick(30,nil)
end)

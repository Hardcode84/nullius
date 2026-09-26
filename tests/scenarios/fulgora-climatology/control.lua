-- given: each ordinary/boxed cell has 5000/25000 air and 100/500 slurry;
-- declared debug electricity and finite medium-tank-2 input fixtures.
-- place/connect: native hydro plants with separate piped fluid supplies.
-- act: research Primitive Filtration; run one batch on Nauvis and Fulgora.
-- run: at most 20400 ticks.
-- expect: one pack/box, no remaining inputs or byproducts, correct unlock.
local fluids=require('__nullius-star__/scenarios/fluid-api')
local function check(ok,message) storage.assertions=storage.assertions+1; assert(ok,message) end
script.on_nth_tick(1,function()
  if game.tick==0 then return end
  script.on_nth_tick(1,nil)
  storage.rows={}; storage.assertions=0
  local force=game.create_force('slurry-climatology')
  local tech=force.technologies['nullius-primitive-filtration']
  check(tech.prerequisites['nullius-geology-2']~=nil,'Geology 2 preparation')
  for _,surface in ipairs({game.surfaces.nauvis,game.planets['nullius-fulgora'].create_surface()}) do
    surface.ignore_surface_conditions=false
    surface.request_to_generate_chunks({0,0},2); surface.force_generate_chunk_requests()
    for _,e in pairs(surface.find_entities_filtered{area={{-16,-16},{48,16}}}) do e.destroy() end
    local tiles={}
    for x=-16,48 do for y=-16,16 do tiles[#tiles+1]={name='fulgoran-rock',position={x,y}} end end
    surface.set_tiles(tiles,true)
    for _,boxed in ipairs({false,true}) do
      local x=boxed and 32 or 0
      local scale=boxed and 5 or 1
      local name='nullius-'..(boxed and 'boxed-' or '')..'climatology-pack-fulgora'
      local product=boxed and 'nullius-box-climatology-pack' or 'nullius-climatology-pack'
      local proto=prototypes.recipe[name]
      check(not force.recipes[name].enabled,'early unlock')
      check(not proto.allowed_effects.productivity,'productivity')
      check(proto.energy==60*scale,'crafting time')
      check(#proto.products==1 and proto.products[1].name==product and proto.products[1].amount==1,'outputs')
      local function place(entity,dx,y)
        return assert(surface.create_entity{name=entity,position={x+dx,y},force=force})
      end
      local plant=place('nullius-hydro-plant-1',0,0)
      plant.set_recipe(name)
      check(plant.get_recipe().name==name,'hydro plant recipe')
      local entities={plant}
      local air=place('nullius-medium-tank-2',-6,-5)
      local slurry=place('nullius-medium-tank-2',6,-3)
      entities[#entities+1]=air; entities[#entities+1]=slurry
      check(air.insert_fluid{name='nullius-air',amount=5000*scale}==5000*scale,'air fixture')
      check(slurry.insert_fluid{name='nullius-hydrocarbon-slurry',amount=100*scale}==100*scale,'slurry fixture')
      for _,sign in ipairs({-1,1}) do
        for dx=1,4 do entities[#entities+1]=place('pipe',dx*sign,-4) end
        entities[#entities+1]=place('pipe',sign,-3)
      end
      local grid=place('factorio-test-planner-grid',0,8)
      grid.power_production=100000000; grid.electric_buffer_size=100000000
      place('substation',0,5)
      storage.rows[#storage.rows+1]={plant=plant,entities=entities,product=product,name=name}
    end
  end
  tech.researched=true
  for _,row in ipairs(storage.rows) do check(force.recipes[row.name].enabled,'Primitive Filtration unlock') end
end)
script.on_nth_tick(600,function()
  if game.tick==0 then return end
  for _,row in ipairs(storage.rows) do
    if row.plant.products_finished<1 then
      check(game.tick<20400,'stalled '..row.name..' on '..row.plant.surface.name)
      return
    end
  end
  for _,row in ipairs(storage.rows) do
    check(row.plant.products_finished==1,'one batch')
    check(row.plant.get_output_inventory().get_item_count(row.product)==1,'one output')
    for _,e in ipairs(row.entities) do for i=1,fluids.count(e) do
      local f=fluids.get(e,i); check(not f or f.amount<0.01,'remaining input or byproduct')
    end end
  end
  helpers.write_file('factorio-tests/fulgora-climatology.json',helpers.table_to_json{
    schema=1,case='fulgora-climatology',status='pass',failure_count=0,
    assertions=storage.assertions,tick=game.tick,factorio_version=script.active_mods.base},false)
  script.on_nth_tick(600,nil)
end)

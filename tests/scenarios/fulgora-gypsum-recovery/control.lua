-- given: one ordinary/boxed batch: 200/1000 sludge and 180/900 oxygen.
-- place/connect: flotation cell 1, two input pipes and a wastewater pipe bank per cell.
-- act: unlock Waste Reclamation; connect oxygen at tick 600 on Fulgora.
-- run: finite reagent feeds and explicit 10 MW electric grids.
-- expect: 8 gypsum and 4 sand items/boxes, 150/750 wastewater, no early craft.
local CASE='fulgora-gypsum-recovery'
local fluids=require('__nullius-star__/scenarios/fluid-api')
local function check(ok,message)
  storage.assertions=storage.assertions+1
  assert(ok,message)
end
local function build(surface,force,name,x,y)
  return assert(surface.create_entity{name=name,position={x,y},force=force})
end
script.on_nth_tick(30,function()
  if not storage.rows then
    storage.assertions=0;storage.rows={}
    local force=game.create_force(CASE)
    force.technologies['nullius-primitive-filtration'].researched=true
    for _,prefix in ipairs({'nullius-','nullius-boxed-'}) do
      check(not force.recipes[prefix..'gypsum-recovery'].enabled,'primitive filtration must not unlock recovery')
    end
    force.technologies['nullius-waste-reclamation'].researched=true
    local planet=game.planets['nullius-fulgora']
    local surface=planet.surface or planet.create_surface()
    surface.request_to_generate_chunks({0,0},3);surface.force_generate_chunk_requests()
    storage.surface=surface;storage.force=force
    for i,boxed in ipairs({false,true}) do
      local scale=boxed and 5 or 1
      local name='nullius-'..(boxed and 'boxed-' or '')..'gypsum-recovery'
      local recipe=prototypes.recipe[name]
      check(force.recipes[name].enabled,'Waste Reclamation unlock '..name)
      check(recipe.energy==20*scale,'craft duration '..name)
      check(not recipe.allowed_effects.productivity,'no productivity '..name)
      check(not recipe.surface_conditions or #recipe.surface_conditions==0,'no planet restriction '..name)
      check(#recipe.ingredients==2 and #recipe.products==3,'two inputs and three outputs '..name)
      local x=i*24
      for _,e in pairs(surface.find_entities_filtered{area={{x-8,-8},{x+10,9}}}) do e.destroy() end
      local tiles={}
      for dx=-8,10 do for y=-8,9 do tiles[#tiles+1]={name='fulgoran-rock',position={x+dx,y}} end end
      surface.set_tiles(tiles,true)
      local machine=build(surface,force,'nullius-flotation-cell-1',x,0)
      machine.set_recipe(name)
      check(machine.get_recipe().name==name,'flotation cell 1 selects '..name)
      local grid=build(surface,force,'factorio-test-planner-grid',x+7,0)
      grid.power_production=10000000;grid.electric_buffer_size=10000000
      build(surface,force,'substation',x+5,4)
      local row={machine=machine,x=x,scale=scale,prefix=boxed and 'nullius-box-' or 'nullius-',feeds={}}
      for j,input in ipairs({{'sludge',200,-0.5,2.5}}) do
        row.feeds[j]={pipe=build(surface,force,'pipe',x+input[3],input[4]),name='nullius-'..input[1],left=input[2]*scale}
      end
      for y=-6.5,-2.5 do
        local pipe=build(surface,force,'pipe',x+0.5,y)
        row.output=row.output or pipe
      end
      storage.rows[#storage.rows+1]=row
    end
  end
  for _,row in ipairs(storage.rows) do
    if game.tick==600 then
      check(row.machine.products_finished==0,'must wait for oxygen connection')
      row.feeds[#row.feeds+1]={pipe=build(storage.surface,storage.force,'pipe',row.x-2.5,-0.5),name='nullius-oxygen',left=180*row.scale}
    end
    for _,feed in ipairs(row.feeds) do
      if feed.left>0 then feed.left=feed.left-feed.pipe.insert_fluid{name=feed.name,amount=feed.left} end
    end
  end
  if game.tick==8400 then
    for _,row in ipairs(storage.rows) do
      check(row.machine.products_finished==1,'exactly one recovery batch')
      check(row.machine.get_item_count(row.prefix..'sand')==4,'sand output')
      check(row.machine.get_item_count(row.prefix..'gypsum')==8,'gypsum output')
      local waste=fluids.segment_contents(row.output,1)['nullius-wastewater'] or 0
      check(math.abs(waste-150*row.scale)<0.001,'connected wastewater output: '..waste)
      for _,feed in ipairs(row.feeds) do
        check(feed.left==0,'finite supply delivered')
        check((fluids.segment_contents(feed.pipe,1)[feed.name] or 0)<0.001,'all reagent consumed')
      end
    end
    helpers.write_file('factorio-tests/'..CASE..'.json',helpers.table_to_json{
      schema=1,case=CASE,status='pass',failure_count=0,assertions=storage.assertions,tick=game.tick,
      factorio_version=script.active_mods.base},false)
    script.on_nth_tick(30,nil)
  end
end)

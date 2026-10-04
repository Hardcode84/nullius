-- given: per ordinary/boxed batch, limestone uses 200/1000 sludge, 250/1250 water,
-- and 5 soda ash items/boxes; stone uses 250/1250 sludge, 200/1000 water,
-- and 4 cement items/boxes. Supply 10 MW per cell, no freshwater.
-- place/connect: four flotation cells on Fulgora with pipes for both inputs and waste.
-- act: unlock Waste Reclamation, delay water connection until tick 600.
-- run: finite reagent feeds until tick 12000.
-- expect: exact ordinary/boxed outputs, complete consumption, no early craft.
local CASE='fulgora-water-recovery'
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
      for _,kind in ipairs({'limestone','stone'}) do
        local name=(prefix=='nullius-' and kind=='stone') and 'stone' or prefix..kind..'-recovery'
        check(not force.recipes[name].enabled,'primitive filtration must not unlock recovery')
      end
    end
    force.technologies['nullius-waste-reclamation'].researched=true
    local planet=game.planets['nullius-fulgora']
    local surface=planet.surface or planet.create_surface()
    surface.request_to_generate_chunks({0,0},3);surface.force_generate_chunk_requests()
    storage.surface=surface;storage.force=force
    local cell=0
    for _,kind in ipairs({'limestone','stone'}) do
    for _,boxed in ipairs({false,true}) do
      cell=cell+1
      local stone=kind=='stone'
      local scale=boxed and 5 or 1
      local name='nullius-'..(boxed and 'boxed-' or '')..kind..'-recovery'
      if not boxed and stone then name='stone' end
      local recipe=prototypes.recipe[name]
      check(force.recipes[name].enabled,'Waste Reclamation unlock '..name)
      check(recipe.energy==(stone and 30 or 20)*scale,'craft duration '..name)
      check(recipe.allowed_effects.productivity==prototypes.recipe[stone and 'stone' or 'nullius-limestone-recovery'].allowed_effects.productivity,'productivity parity '..name)
      check(not recipe.surface_conditions or #recipe.surface_conditions==0,'no planet restriction '..name)
      check(#recipe.ingredients==3 and #recipe.products==(stone and 2 or 3),'recipe input/output count '..name)
      local x=cell*24
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
      local row={machine=machine,x=x,scale=scale,prefix=boxed and 'nullius-box-' or 'nullius-',kind=kind,water=stone and 200 or 250,waste=stone and 150 or 200,feeds={}}
      check(machine.insert{name=row.prefix..(stone and 'cement' or 'soda-ash'),count=stone and 4 or 5}==(stone and 4 or 5),'solid reagent supplied')
      for j,input in ipairs({{'sludge',stone and 250 or 200,-0.5,2.5}}) do
        row.feeds[j]={pipe=build(surface,force,'pipe',x+input[3],input[4]),name='nullius-'..input[1],left=input[2]*scale}
      end
      for y=-6.5,-2.5 do
        local pipe=build(surface,force,'pipe',x+0.5,y)
        row.output=row.output or pipe
      end
      storage.rows[#storage.rows+1]=row
    end
    end
  end
  for _,row in ipairs(storage.rows) do
    if game.tick==600 then
      check(row.machine.products_finished==0,'must wait for water connection')
      row.feeds[#row.feeds+1]={pipe=build(storage.surface,storage.force,'pipe',row.x-2.5,-0.5),name='nullius-water',left=row.water*row.scale}
    end
    for _,feed in ipairs(row.feeds) do
      if feed.left>0 then feed.left=feed.left-feed.pipe.insert_fluid{name=feed.name,amount=feed.left} end
    end
  end
  if game.tick==12000 then
    for _,row in ipairs(storage.rows) do
      check(row.machine.products_finished==1,'exactly one recovery batch')
      if row.kind=='stone' then
        check(row.machine.get_item_count(row.prefix=='nullius-' and 'stone' or 'nullius-box-stone')==15,'stone output')
      else
        check(row.machine.get_item_count(row.prefix..'crushed-limestone')==8,'limestone output')
        check(row.machine.get_item_count(row.prefix..'crushed-bauxite')==4,'bauxite output')
      end
      check(row.machine.get_item_count(row.prefix..(row.kind=='stone' and 'cement' or 'soda-ash'))==0,'solid reagent consumed')
      local waste=fluids.segment_contents(row.output,1)['nullius-wastewater'] or 0
      check(math.abs(waste-row.waste*row.scale)<0.001,'connected wastewater output: '..waste)
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

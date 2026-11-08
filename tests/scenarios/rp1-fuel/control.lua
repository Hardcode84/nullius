-- given: one finite recipe batch per plant, supplied through input pipes;
-- an explicit electric grid, and RP-1 research.
-- place/connect: three chemical plants on Nauvis with separate fluid feeds.
-- act/run: craft kerosene, ordinary fuel, and boxed fuel.
-- expect: research gates all recipes; exact outputs, no fuel productivity,
-- and no surface restrictions.
local CASE='rp1-fuel'
local fluids=require('__nullius-star__/scenarios/fluid-api')
local function check(ok,message)
  storage.assertions=storage.assertions+1
  assert(ok,message)
end
script.on_init(function()
  storage.assertions=0;storage.rows={}
  local force=game.create_force(CASE)
  local surface=game.surfaces.nauvis
  surface.request_to_generate_chunks({0,0},3);surface.force_generate_chunk_requests()
  for _,entity in pairs(surface.find_entities_filtered{area={{-10,-10},{70,10}}}) do entity.destroy() end
  local tiles={}
  for x=-10,70 do for y=-10,10 do tiles[#tiles+1]={name='grass-1',position={x,y}} end end
  surface.set_tiles(tiles)
  local names={'nullius-olefin-oligomerization','nullius-rp1-rocket-fuel','nullius-boxed-rp1-rocket-fuel'}
  for _,name in ipairs(names) do check(not force.recipes[name].enabled,'research gate '..name) end
  force.technologies['nullius-rp1-fuel'].researched=true
  force.technologies['nullius-hydrocarbon-productivity-1'].researched=true
  check(force.recipes['nullius-olefin-oligomerization'].productivity_bonus>0,'hydrocarbon bonus applies to kerosene')
  for _,name in ipairs{'nullius-rp1-rocket-fuel','nullius-boxed-rp1-rocket-fuel'} do
    check(force.recipes[name].productivity_bonus==0,'fuel excluded from hydrocarbon bonus')
  end
  for index,name in ipairs(names) do
    local x=(index-1)*24
    local function build(entity,dx,dy)
      return assert(surface.create_entity{name=entity,position={x+dx+0.5,dy+0.5},force=force})
    end
    local machine=build('nullius-chemical-plant-1',0,0)
    check(force.recipes[name].enabled,'research unlock '..name)
    check(machine.set_recipe(name),'recipe selection '..name)
    local recipe=prototypes.recipe[name]
    check(not recipe.surface_conditions or #recipe.surface_conditions==0,'surface restriction '..name)
    local grid=build('factorio-test-planner-grid',7,0)
    grid.power_production=10000000;grid.electric_buffer_size=10000000
    build('substation',4,4)
    local row={machine=machine,recipe=name,feeds={}}
    local fluid_index=0
    for _,ingredient in pairs(recipe.ingredients) do
      if ingredient.type=='fluid' then
        fluid_index=fluid_index+1
        local pipe=build('pipe',fluid_index==1 and -1 or -2,fluid_index==1 and -2 or 0)
        row.feeds[#row.feeds+1]={pipe=pipe,name=ingredient.name,left=ingredient.amount}
      else
        check(machine.insert{name=ingredient.name,count=ingredient.amount}==ingredient.amount,'finite item input '..ingredient.name)
      end
    end
    if index==1 then row.output=build('pipe',-1,2) end
    storage.rows[#storage.rows+1]=row
  end
end)
script.on_nth_tick(30,function()
  local done=true
  for _,row in ipairs(storage.rows) do
    for _,feed in ipairs(row.feeds) do
      if feed.left>0 then feed.left=feed.left-feed.pipe.insert_fluid{name=feed.name,amount=feed.left} end
    end
    if row.machine.products_finished<1 then done=false end
  end
  if not done then
    if game.tick>=12480 then
      local rows={}
      for _,row in ipairs(storage.rows) do
        local feeds={}
        for _,feed in ipairs(row.feeds) do feeds[#feeds+1]={name=feed.name,left=feed.left,contents=fluids.segment_contents(feed.pipe,1)} end
        local boxes={}
        for i=1,fluids.count(row.machine) do boxes[#boxes+1]={filter=fluids.filter(row.machine,i),contents=fluids.get(row.machine,i),index=fluids.prototype(row.machine,i).index} end
        rows[#rows+1]={boxes=boxes,recipe=row.recipe,status=row.machine.status,energy=row.machine.energy,finished=row.machine.products_finished,feeds=feeds}
      end
      error(helpers.table_to_json(rows))
    end
    return
  end
  for _,row in ipairs(storage.rows) do
    check(row.machine.products_finished==1,'one paid batch '..row.recipe)
    for _,product in pairs(prototypes.recipe[row.recipe].products) do
      local count=product.type=='fluid' and (fluids.segment_contents(row.output,1)[product.name] or 0) or row.machine.get_item_count(product.name)
      check(math.abs(count-product.amount)<0.001,'exact product '..product.name..' '..count)
    end
    if row.recipe~='nullius-olefin-oligomerization' then
      check(row.machine.bonus_progress==0,'fuel productivity')
    end
    for _,feed in ipairs(row.feeds) do
      check(feed.left==0,'finite fluid delivered')
      check((fluids.segment_contents(feed.pipe,1)[feed.name] or 0)<0.001,'finite fluid consumed')
    end
  end
  helpers.write_file('factorio-tests/'..CASE..'.json',helpers.table_to_json{
    schema=1,case=CASE,status='pass',failure_count=0,assertions=storage.assertions,tick=game.tick,
    factorio_version=script.active_mods.base},false)
  script.on_nth_tick(30,nil)
end)

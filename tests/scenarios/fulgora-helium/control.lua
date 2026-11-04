-- given: two cracking batches per cell, researched degassing, debug electricity.
-- place/connect: tier 1 ordinary and tier 3 bulk distilleries with separate output pipes.
-- act: craft, fill the helium outlet with declared debug helium, then drain it.
-- run: at most 2400 ticks.
-- expect: exact yields, separate research gates, full helium blocks further crafting.
local fluids=require('__nullius-star__/scenarios/fluid-api')
local function check(ok,message) storage.assertions=storage.assertions+1;assert(ok,message) end
local function amount(entities,name)
  local total=0
  for _,entity in ipairs(entities) do
    for i=1,fluids.count(entity) do
      local fluid=fluids.get(entity,i)
      if fluid and fluid.name==name then total=total+fluid.amount end
    end
  end
  return total
end
local function helium(row,fill)
  local found=false
  for _,entity in ipairs(row.entities) do
    for i=1,fluids.count(entity) do
      local fluid=fluids.get(entity,i)
      local filter=fluids.filter(entity,i)
      if (fluid and fluid.name==row.helium) or (filter and filter.name==row.helium) then
        found=true
        if entity==row.machine then
          fluids.set(entity,i,fill and {name=row.helium,amount=fluids.capacity(entity,i)} or nil)
        elseif fill then
          entity.set_fluid_segment_fluid(i,{name=row.helium,amount=entity.get_fluid_segment_capacity(i)})
        else entity.clear_fluid_segment_fluid(i) end
      end
    end
  end
  check(found,'Missing helium outlet')
end
script.on_nth_tick(60,function()
  if not storage.rows then
    storage.assertions=0;storage.rows={}
    local force=game.create_force('helium-test')
    local surface=game.surfaces.nauvis
    surface.request_to_generate_chunks({0,0},2);surface.force_generate_chunk_requests()
    for _,e in pairs(surface.find_entities_filtered{area={{-12,-12},{50,12}}}) do e.destroy() end
    local tiles={}
    for x=-12,50 do for y=-12,12 do tiles[#tiles+1]={name='grass-1',position={x,y}} end end
    surface.set_tiles(tiles,true)
    local ordinary='nullius-degassing-hydrocarbon-cracking'
    local bulk='nullius-boxed-degassing-hydrocarbon-cracking'
    for _,tech in ipairs({'nullius-primitive-filtration','nullius-air-separation-3','nullius-overcharged-assembly-2',
        'nullius-bulk-hydrocarbon-cracking'}) do force.technologies[tech].researched=true end
    check(not force.recipes[ordinary].enabled and not force.recipes[bulk].enabled,'early unlock')
    local tech=force.technologies['nullius-hydrocarbon-degassing']
    check(tech.prerequisites['nullius-air-separation-3']~=nil,'missing normal helium research')
    check(tech.prerequisites['nullius-overcharged-assembly-2']~=nil,'missing EM prerequisite')
    check(tech.prerequisites['nullius-checkpoint-helium']==nil,'circular helium checkpoint')
    tech.researched=true
    check(force.recipes[ordinary].enabled and not force.recipes[bulk].enabled,'ordinary gate')
    local bulk_tech=force.technologies['nullius-bulk-hydrocarbon-degassing']
    check(bulk_tech.prerequisites[tech.name]~=nil and
      bulk_tech.prerequisites['nullius-bulk-hydrocarbon-cracking']~=nil,'bulk prerequisites')
    bulk_tech.researched=true
    check(force.recipes[bulk].enabled,'bulk unlock')
    for _,boxed in ipairs({false,true}) do
      local x=boxed and 30 or 0
      local name=boxed and bulk or ordinary
      local recipe=prototypes.recipe[name]
      local base=prototypes.recipe[boxed and 'nullius-boxed-hydrocarbon-cracking' or 'nullius-hydrocarbon-cracking']
      check(recipe.energy==base.energy*2,'degassing time')
      check(not recipe.allowed_effects.productivity,'helium productivity')
      check(not recipe.surface_conditions or #recipe.surface_conditions==0,'surface restriction')
      local machine=assert(surface.create_entity{name=boxed and 'nullius-distillery-3' or 'nullius-distillery-1',position={x,0},force=force})
      machine.set_recipe(name)
      check(machine.get_recipe().name==name,'distillery recipe selection')
      local entities={machine}
      for _,dx in ipairs({-2,0,2}) do
        entities[#entities+1]=assert(surface.create_entity{name='pipe',position={x+dx,-3},force=force})
      end
      local grid=surface.create_entity{name='factorio-test-planner-grid',position={x+7,0},force=force}
      grid.power_production=100000000;grid.electric_buffer_size=100000000
      surface.create_entity{name='substation',position={x+5,4},force=force}
      local input=boxed and 250 or 50
      check(machine.insert_fluid{name='nullius-filtered-hydrocarbons',amount=input}==input,'feed')
      storage.rows[#storage.rows+1]={machine=machine,entities=entities,input=input,boxed=boxed,stage='first',
        blocked_wait=math.ceil(recipe.energy/machine.crafting_speed*60)+180,
        helium=boxed and 'nullius-compressed-helium' or 'nullius-helium'}
    end
  end
  local done=true
  for _,row in ipairs(storage.rows) do
    local m=row.machine
    if row.stage=='first' and m.products_finished==1 then
      local function equal(actual,expected,label) check(math.abs(actual-expected)<0.001,label..': '..actual) end
      equal(amount(row.entities,row.helium),row.boxed and 2 or 1,'helium yield')
      equal(amount(row.entities,row.boxed and 'nullius-compressed-methane' or 'nullius-methane'),row.boxed and 75 or 60,'methane yield')
      equal(amount(row.entities,'nullius-benzene'),row.boxed and 60 or 12,'benzene yield')
      equal(m.get_item_count(row.boxed and 'nullius-box-graphite' or 'nullius-graphite'),2,'graphite yield')
      for i=2,4 do check(amount({row.entities[i]},row.helium)+amount({row.entities[i]},'nullius-benzene')+
        amount({row.entities[i]},row.boxed and 'nullius-compressed-methane' or 'nullius-methane')>0,'disconnected output pipe') end
      helium(row,true)
      check(m.insert_fluid{name='nullius-filtered-hydrocarbons',amount=row.input}==row.input,'second feed')
      row.stage='blocked';row.blocked_tick=game.tick
    elseif row.stage=='blocked' and game.tick>=row.blocked_tick+row.blocked_wait then
      check(m.products_finished==1,'full helium outlet did not block: '..row.helium..
        ' cycles='..m.products_finished..' amount='..amount(row.entities,row.helium))
      helium(row,false);row.stage='resume'
    elseif row.stage=='resume' and m.products_finished==2 then
      check(amount(row.entities,row.helium)>0,'no helium after draining');row.stage='done'
    end
    if row.stage~='done' then done=false end
  end
  check(done or game.tick<2340,'degassing production stalled')
  if done then
    helpers.write_file('factorio-tests/fulgora-helium.json',helpers.table_to_json{
      schema=1,case='fulgora-helium',status='pass',failure_count=0,assertions=storage.assertions,
      tick=game.tick,factorio_version=script.active_mods.base},false)
    script.on_nth_tick(60,nil)
  end
end)

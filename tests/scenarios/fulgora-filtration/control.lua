-- given: basic hydro plants/crushers, pipes, substations and debug electric grids.
-- inputs per ordinary/boxed line: 100/500 slurry, 1000/5000 sludge, 1 salt/box salt.
-- place: six independent cells on Nauvis, fluid outputs connected to pipes;
-- crude recovery cells unload through powered inserters into wooden chests.
-- act: research probe access then Primitive Filtration; execute all six recipes.
-- run: scheduled input feeds every 60 ticks, exact 20-batch crude recovery budget.
-- expect: deterministic slurry/salt outputs, bounded random minerals, boxed parity,
-- research gates, no productivity, and no planet restrictions.
local fluids=require('__nullius-star__/scenarios/fluid-api')
local assertions=0
local function check(ok,message) assertions=assertions+1; assert(ok,message) end
local function result() helpers.write_file('factorio-tests/fulgora-filtration.json',helpers.table_to_json{
  schema=1,case='fulgora-filtration',status='pass',failure_count=0,assertions=assertions,
  tick=game.tick,factorio_version=script.active_mods.base},false) end
script.on_nth_tick(1,function()
  if game.tick==0 then return end
  script.on_nth_tick(1,nil)
  local force=game.create_force('filtration')
  local surface=game.surfaces.nauvis
  check(surface.get_property('pressure')==1000,'Nauvis pressure fixture')
  surface.request_to_generate_chunks({0,0},4); surface.force_generate_chunk_requests()
  for _,e in pairs(surface.find_entities_filtered{area={{-16,-16},{120,16}}}) do e.destroy() end
  local tiles={}
  for x=-16,119 do for y=-16,15 do tiles[#tiles+1]={name='fulgoran-rock',position={x,y}} end end
  surface.set_tiles(tiles,true)
  force.technologies['nullius-probe-fulgora'].researched=true
  local tech=force.technologies['nullius-primitive-filtration']
  check(tech.research_unit_count==5,'primitive research cost')
  check(tech.prerequisites['nullius-probe-fulgora']~=nil,'probe prerequisite')
  check(not force.recipes['nullius-crude-sludge-filtration'].enabled,'probe unlocked filtration')
  tech.researched=true
  storage.rows={}
  local cell=0
  for _,boxed in ipairs({false,true}) do
    local prefix=boxed and 'nullius-boxed-' or 'nullius-'
    local scale=boxed and 5 or 1
    local function item(name) return boxed and 'nullius-box-'..name or
      (name=='stone' and 'stone' or 'nullius-'..name) end
    for _,kind in ipairs({'hydrocarbon-slurry-filtration','crude-sludge-filtration','salt-disposal'}) do
      local name=prefix..kind
      check(force.recipes[name].enabled,'missing unlock '..name)
      local recipe=prototypes.recipe[name]
      check(not recipe.allowed_effects.productivity,'productivity enabled '..name)
      check(not recipe.surface_conditions or #recipe.surface_conditions==0,'planet restriction '..name)
      local x=cell*20; cell=cell+1
      local machine=surface.create_entity{name=kind=='salt-disposal' and 'nullius-crusher-1' or 'nullius-hydro-plant-1',position={x,0},force=force}
      machine.set_recipe(name)
      check(machine.get_recipe() and machine.get_recipe().name==name,'basic machine cannot execute '..name)
      local power=surface.create_entity{name='factorio-test-planner-grid',position={x+7,0},force=force}
      power.power_production=100000000; power.electric_buffer_size=100000000
      surface.create_entity{name='substation',position={x+5,4},force=force}
      local row={machine=machine,kind=kind,item_prefix=boxed and 'nullius-box-' or 'nullius-',boxed=boxed,scale=scale}
      if kind=='hydrocarbon-slurry-filtration' then
        check(machine.insert_fluid{name='nullius-hydrocarbon-slurry',amount=100*scale}==100*scale,'slurry fixture')
        row.pipes={}
        for _,dx in ipairs({-1,1}) do
          row.pipes[#row.pipes+1]=surface.create_entity{name='pipe',position={x+dx,3},force=force}
        end
      elseif kind=='crude-sludge-filtration' then
        row.remaining=1000*scale
        row.chest=surface.create_entity{name='wooden-chest',position={x,-3},force=force}
        row.inserter=surface.create_entity{name='inserter',position={x,-2},
          direction=defines.direction.south,force=force}
        check(#recipe.products==6,'crude product set')
        local gypsum=false
        for _,p in pairs(recipe.products) do
          if p.name==item('gypsum') then gypsum=true end
          check(p.name~=item('rutile'),'crude filtration must not recover rutile')
          local chance=p.independent_probability or p.probability
          check(chance==0.25,'crude product probability '..p.name)
          check(p.amount==3,'crude product drop size '..p.name)
        end
        check(gypsum,'crude filtration must recover gypsum')
      else
        check(machine.insert{name=item('salt'),count=1}==1,'salt fixture')
      end
      storage.rows[#storage.rows+1]=row
    end
  end
  storage.assertions=assertions
end)
script.on_nth_tick(60,function()
  if game.tick==0 then return end
  assertions=storage.assertions
  local done=true
  for _,row in ipairs(storage.rows) do
    local target=row.kind=='crude-sludge-filtration' and 20 or 1
    if row.remaining and row.remaining>0 then
      local added=row.machine.insert_fluid{name='nullius-sludge',amount=row.remaining}
      row.remaining=row.remaining-added
    end
    if row.machine.products_finished<target then done=false end
    if row.chest and (not row.machine.get_output_inventory().is_empty() or
      row.inserter.held_stack.valid_for_read) then done=false end
  end
  if not done then
    check(game.tick<14400,'filtration did not finish its declared batches')
    storage.assertions=assertions
    return
  end
  for _,row in ipairs(storage.rows) do
    local m=row.machine
    local function item(name) return row.boxed and 'nullius-box-'..name or
      (name=='stone' and 'stone' or 'nullius-'..name) end
    if row.kind=='hydrocarbon-slurry-filtration' then
      check(m.products_finished==1,'slurry batch count')
      check(m.get_item_count(item('ice'))==2,'ice yield')
      check(m.get_item_count(item('salt'))==1,'salt yield')
      check(m.get_item_count(item('gypsum'))==0,'slurry must not yield gypsum')
      local seen={}
      for _,pipe in ipairs(row.pipes) do local f=fluids.get(pipe,1); check(f and f.amount>0,'unconnected output'); seen[f.name]=true end
      check(seen['nullius-filtered-hydrocarbons'] and seen['nullius-sludge'],'two independent fluid outputs')
    elseif row.kind=='salt-disposal' then
      check(m.products_finished==1 and m.get_item_count(item('mineral-dust'))==1,'salt to dust yield')
    else
      check(m.products_finished==20 and row.remaining==0,'crude batch budget')
      local total=0
      for _,name in ipairs({'crushed-iron-ore','crushed-bauxite','sand','crushed-limestone','stone','gypsum'}) do
        local count=row.chest.get_item_count(item(name)); total=total+count
        check(count<=60 and count%3==0,'random output must contain three-item drops')
      end
      check(row.chest.get_item_count(item('rutile'))==0,'crude filtration produced rutile')
      check(total>0 and total<360,'crude filtration did not exercise random recovery')
    end
  end
  result(); script.on_nth_tick(60,nil)
end)

-- given: 100 air per basic cell; 100 air and 49 residual gas per advanced/compressed cell;
-- one recipe batch per generic-route cell; declared debug electricity.
-- place: production air filters and distilleries on Fulgora and Nauvis.
-- connect: Fulgora residual outputs to second-stage distilleries through pipes.
-- act: unlock Primitive Filtration, Air Separation 2, then High Pressure Chemistry.
-- run: 1200 ticks.
-- expect: 80 nitrogen, 19 CO2, 50 argon; no oxygen/water; planet restrictions.
local fluids=require('__nullius-star__/scenarios/fluid-api')
local generic={'air-separation-1','air-separation-2','pressure-air-separation',
  'oxygen-separation','pressure-oxygen-separation','residual-gas',
  'residual-separation','pressure-residual-separation'}
local function check(ok,message) storage.assertions=storage.assertions+1; assert(ok,message) end
local function total(entities,name)
  local n=0
  for _,e in ipairs(entities) do for i=1,fluids.count(e) do
    local f=fluids.get(e,i); if f and f.name==name then n=n+f.amount end
  end end
  return n
end
script.on_nth_tick(1,function()
  if game.tick==0 then return end
  script.on_nth_tick(1,nil)
  storage.assertions=0; storage.cells={}; storage.generic={}; storage.filters={}; storage.selection={}
  local force=game.create_force('atmosphere-test')
  for _,prefix in ipairs({'','pressure-'}) do
    for _,step in ipairs({'air','residual'}) do
      check(not force.recipes['nullius-'..prefix..step..'-separation-fulgora'].enabled,'premature unlock')
    end
  end
  force.technologies['nullius-primitive-filtration'].researched=true
  check(force.recipes['nullius-air-separation-fulgora'].enabled,'ordinary unlock')
  check(not force.recipes['nullius-air-separation-fulgora-2'].enabled,'premature advanced unlock')
  check(not force.recipes['nullius-residual-separation-fulgora'].enabled,'premature argon unlock')
  force.technologies['nullius-air-separation-2'].researched=true
  check(force.recipes['nullius-air-separation-fulgora-2'].enabled,'advanced unlock')
  check(force.recipes['nullius-residual-separation-fulgora'].enabled,'argon unlock')
  check(not force.recipes['nullius-pressure-air-separation-fulgora'].enabled,'premature pressure unlock')
  check(not force.recipes['nullius-pressure-residual-separation-fulgora'].enabled,'premature pressure argon unlock')
  force.technologies['nullius-high-pressure-chemistry'].researched=true
  check(force.recipes['nullius-pressure-air-separation-fulgora'].enabled,'pressure unlock')
  check(force.recipes['nullius-pressure-residual-separation-fulgora'].enabled,'pressure argon unlock')
  force.research_all_technologies()
  for _,surface in ipairs({game.surfaces.nauvis,game.planets['nullius-fulgora'].create_surface()}) do
    local fulgora=surface.name=='nullius-fulgora'
    surface.ignore_surface_conditions=false
    surface.request_to_generate_chunks({64,0},5); surface.force_generate_chunk_requests()
    for _,e in pairs(surface.find_entities_filtered{area={{-16,-20},{160,20}}}) do e.destroy() end
    local tiles={}
    for x=-16,160 do for y=-20,20 do tiles[#tiles+1]={name='fulgoran-rock',position={x,y}} end end
    surface.set_tiles(tiles,true)
    local function machine(name,x,y)
      return assert(surface.create_entity{name=name,position={x,y},force=force})
    end
    local function select_recipe(entity,name,allowed,stock)
      entity.get_or_create_control_behavior().circuit_set_recipe=true
      local signal=machine('constant-combinator',entity.position.x-4,entity.position.y)
      local behavior=signal.get_or_create_control_behavior()
      local section=behavior.get_section(1) or behavior.add_section()
      section.set_slot(1,{value={type='recipe',name=name,quality='normal'},min=1})
      local red=defines.wire_connector_id.circuit_red
      check(entity.get_wire_connector(red,true).connect_to(signal.get_wire_connector(red,true)),'recipe signal wire')
      storage.selection[#storage.selection+1]={entity=entity,name=name,allowed=allowed,stock=stock}
    end
    for x=0,144,16 do
      local grid=machine('factorio-test-planner-grid',x,10)
      grid.power_production=100000000; grid.electric_buffer_size=100000000
      machine('substation',x,5)
    end
    storage.filters[#storage.filters+1]=machine('nullius-air-filter-1',-8,0)
    for i,name in ipairs(generic) do
      local e=machine('nullius-distillery-1',i*12,0)
      select_recipe(e,'nullius-'..name,not fulgora)
      storage.generic[#storage.generic+1]={entity=e,allowed=not fulgora,name=name}
    end
    local basic=machine('nullius-distillery-1',112,16)
    select_recipe(basic,'nullius-air-separation-fulgora',fulgora,100)
    storage.cells[#storage.cells+1]={air=basic,entities={basic},gas='',allowed=fulgora,basic=true}
    for i,compressed in ipairs({false,true}) do
      local prefix=compressed and 'pressure-' or ''
      local gas=compressed and 'compressed-' or ''
      local x=112+(i-1)*24
      local air=machine('nullius-distillery-1',x,0)
      local residual=machine('nullius-distillery-1',x+3,-6)
      select_recipe(air,'nullius-'..prefix..'air-separation-fulgora'..(compressed and '' or '-2'),fulgora,100)
      select_recipe(residual,'nullius-'..prefix..'residual-separation-fulgora',fulgora,49)
      local entities={air,residual,machine('pipe',x+2,-3)}
      storage.cells[#storage.cells+1]={air=air,residual=residual,entities=entities,gas=gas,allowed=fulgora}
    end
  end
end)
-- Native circuit selection enforces surface conditions; Lua set_recipe bypasses them.
script.on_nth_tick(60,function()
  if game.tick==0 then return end
  for _,row in ipairs(storage.selection) do
    local recipe=row.entity.get_recipe()
    check((recipe~=nil)==row.allowed,'native selection '..row.name..' on '..row.entity.surface.name)
    if row.allowed then
      check(recipe.name==row.name,'selected wrong recipe')
      if row.stock then check(not prototypes.recipe[row.name].allowed_effects.productivity,'productivity changes composition') end
      for _,input in pairs(prototypes.recipe[row.name].ingredients) do
        local amount=row.stock or input.amount
        check(row.entity.insert_fluid{name=input.name,amount=amount}==amount,'input stock '..row.name)
      end
    end
  end
  script.on_nth_tick(60,nil)
end)
script.on_nth_tick(1200,function()
  if game.tick==0 then return end
  for _,filter in ipairs(storage.filters) do
    check(filter.products_finished>0,'native air capture stalled')
    check(total({filter},'nullius-air')>0,'native filter no longer captures shared air')
  end
  for _,row in ipairs(storage.generic) do
    check((row.entity.products_finished>0)==row.allowed,'generic surface gate '..row.name..' surface='..row.entity.surface.name..' finished='..row.entity.products_finished..' status='..row.entity.status..' energy='..row.entity.energy)
  end
  for _,row in ipairs(storage.cells) do
    check(row.air.products_finished==(row.allowed and 1 or 0),'air surface gate')
    if row.residual then check(row.residual.products_finished==(row.allowed and 1 or 0),'residual transfer or surface gate') end
    if row.allowed then
      for name,expected in pairs({nitrogen=80,['carbon-dioxide']=19,argon=row.basic and 0 or 50,['residual-gas']=0,air=0}) do
        check(math.abs(total(row.entities,'nullius-'..row.gas..name)-expected)<0.01,'yield '..row.gas..name)
      end
      for _,name in ipairs({'oxygen','water','steam','trace-gas'}) do
        check(total(row.entities,'nullius-'..name)==0,'unexpected '..name)
      end
    end
  end
  helpers.write_file('factorio-tests/fulgora-air-separation.json',helpers.table_to_json{
    schema=1,case='fulgora-air-separation',status='pass',failure_count=0,
    assertions=storage.assertions,tick=game.tick,factorio_version=script.active_mods.base},false)
  script.on_nth_tick(1200,nil)
end)

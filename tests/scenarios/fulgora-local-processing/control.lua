-- given: ordinary/boxed cells, 3 ice, 6 salt, 50/250 filtered hydrocarbons.
-- place: distilleries and hydro plants on Nauvis; declared debug electric power.
-- connect: ice melting outputs to salt dissolution inputs through real pipes.
-- act: research Primitive Filtration, Mass Production 4, and bulk cracking; execute one cracking and dissolution batch.
-- run: until both cells complete, at most 3900 ticks.
-- expect: exact ordinary/boxed yields, native fluid transfer, local research gate.
local fluids=require('__nullius-star__/scenarios/fluid-api')
local function check(ok,message) storage.assertions=storage.assertions+1; assert(ok,message) end
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
script.on_nth_tick(1,function()
  if game.tick==0 then return end
  script.on_nth_tick(1,nil)
  storage.assertions=0; storage.rows={}
  local surface=game.surfaces.nauvis
  check(surface.get_property('pressure')==1000,'Nauvis pressure fixture')
  surface.request_to_generate_chunks({0,0},3); surface.force_generate_chunk_requests()
  for _,entity in pairs(surface.find_entities_filtered{area={{-16,-24},{100,20}}}) do entity.destroy() end
  local tiles={}
  for x=-16,100 do for y=-24,20 do tiles[#tiles+1]={name='fulgoran-rock',position={x,y}} end end
  surface.set_tiles(tiles,true)
  local force=game.create_force('local-processing')
  force.technologies['nullius-probe-fulgora'].researched=true
  for _,boxed in ipairs({false,true}) do
    local x=boxed and 60 or 0
    local scale=boxed and 5 or 1
    local prefix=boxed and 'nullius-boxed-' or 'nullius-'
    local item=boxed and 'nullius-box-' or 'nullius-'
    local function machine(name,dx,dy,recipe,direction)
      local entity=assert(surface.create_entity{name=name,position={x+dx,dy},force=force,direction=direction})
      entity.set_recipe(prefix..recipe)
      check(entity.get_recipe().name==prefix..recipe,'starter machine cannot execute '..recipe)
      check(not force.recipes[prefix..recipe].enabled,'recipe available before Primitive Filtration')
      local prototype=prototypes.recipe[prefix..recipe]
      check(not prototype.allowed_effects.productivity,'productivity enabled '..recipe)
      check(not prototype.surface_conditions or #prototype.surface_conditions==0,'planet restriction '..recipe)
      return entity
    end
    local melt=machine('nullius-distillery-1',0,0,'ice-melting')
    local dissolve=machine('nullius-hydro-plant-1',-1,-6,'salt-dissolution',defines.direction.south)
    local crack=machine('nullius-distillery-1',16,0,'hydrocarbon-cracking')
    check(melt.insert{name=item..'ice',count=3}==3,'ice fixture')
    check(dissolve.insert{name=item..'salt',count=6}==6,'salt fixture')
    check(crack.insert_fluid{name='nullius-filtered-hydrocarbons',amount=50*scale}==50*scale,'hydrocarbon fixture')
    local water={melt,dissolve}
    for dx=-2,2 do water[#water+1]=assert(surface.create_entity{name='pipe',position={x+dx,-3},force=force}) end
    local products={crack}
    for _,dx in ipairs({-2,0,2}) do
      products[#products+1]=assert(surface.create_entity{name='pipe',position={x+16+dx,-3},force=force})
    end
    local grid=surface.create_entity{name='factorio-test-planner-grid',position={x+8,8},force=force}
    grid.power_production=100000000; grid.electric_buffer_size=100000000
    surface.create_entity{name='substation',position={x+7,0},force=force}
    storage.rows[#storage.rows+1]={melt=melt,dissolve=dissolve,crack=crack,scale=scale,item=item,
      water=water,products=products,prefix=prefix}
  end
  force.technologies['nullius-primitive-filtration'].researched=true
  for _,row in ipairs(storage.rows) do for _,name in ipairs({'ice-melting','salt-dissolution','hydrocarbon-cracking'}) do
    check(force.recipes[row.prefix..name].enabled==(row.scale==1),'incorrect primitive unlock '..row.prefix..name)
  end end
  force.technologies['nullius-mass-production-4'].researched=true
  check(not force.recipes['nullius-boxed-hydrocarbon-cracking'].enabled,'generic mass production unlocked cracking')
  local bulk=force.technologies['nullius-bulk-hydrocarbon-cracking']
  check(bulk.prerequisites['nullius-overcharged-assembly-2']~=nil,'cracking requires overcharged assembly')
  check(bulk.prerequisites['nullius-packaging-3']~=nil,'cracking requires packaging')
  local em=false
  for _,ingredient in pairs(bulk.research_unit_ingredients) do
    if ingredient.name=='nullius-electromagnetic-pack' then em=true end
  end
  check(em,'cracking requires EM science')
  bulk.researched=true
  for _,row in ipairs(storage.rows) do for _,name in ipairs({'ice-melting','salt-dissolution','hydrocarbon-cracking'}) do
    check(force.recipes[row.prefix..name].enabled,'missing bulk unlock '..name)
  end end
end)
script.on_nth_tick(60,function()
  if game.tick==0 then return end
  for _,row in ipairs(storage.rows) do
    if row.melt.products_finished<3 or row.dissolve.products_finished<1 or row.crack.products_finished<1 then
      check(game.tick<3900,'local processing stalled: '..row.prefix..' melt '..row.melt.products_finished..
        ' salt '..row.dissolve.products_finished..' hydrocarbons '..row.crack.products_finished)
      return
    end
  end
  for _,row in ipairs(storage.rows) do
    local function equal(actual,expected,message) check(math.abs(actual-expected)<0.01,message..': '..actual) end
    equal(amount(row.water,'nullius-water'),15*row.scale,'net melting water')
    equal(amount({row.dissolve},'nullius-brine'),65*row.scale,'brine yield')
    equal(amount(row.products,'nullius-methane'),60*row.scale,'methane yield')
    equal(amount(row.products,'nullius-benzene'),12*row.scale,'benzene yield')
    equal(row.crack.get_item_count(row.item..'graphite'),2,'graphite yield')
    check(row.melt.get_item_count(row.item..'ice')==0 and row.dissolve.get_item_count(row.item..'salt')==0,'unconsumed inputs')
  end
  helpers.write_file('factorio-tests/fulgora-local-processing.json',helpers.table_to_json{
    schema=1,case='fulgora-local-processing',status='pass',failure_count=0,
    assertions=storage.assertions,tick=game.tick,factorio_version=script.active_mods.base},false)
  script.on_nth_tick(60,nil)
end)

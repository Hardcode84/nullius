-- given: four sand or four boxes of sand per cell, declared debug electricity.
-- place/connect: production crushers on Nauvis, powered through a substation.
-- act: unlock Waste Management, then Mass Production 7; run one batch per cell.
-- run: 1200 ticks.
-- expect: three dust or three boxes of dust, exact research gates, no surface gate.
local function check(ok,message) storage.assertions=storage.assertions+1; assert(ok,message) end
script.on_nth_tick(1,function()
  if game.tick==0 then return end
  script.on_nth_tick(1,nil)
  storage.assertions=0; storage.rows={}
  local surface=game.surfaces.nauvis
  surface.request_to_generate_chunks({0,0},1); surface.force_generate_chunk_requests()
  for _,e in pairs(surface.find_entities_filtered{area={{-12,-12},{16,12}}}) do e.destroy() end
  local tiles={}
  for x=-12,16 do for y=-12,12 do tiles[#tiles+1]={name='fulgoran-rock',position={x,y}} end end
  surface.set_tiles(tiles,true)
  local force=game.create_force('sand-crushing')
  local ordinary='nullius-sand-crushing'
  local boxed='nullius-boxed-sand-crushing'
  check(not force.recipes[ordinary].enabled and not force.recipes[boxed].enabled,'initial unlock')
  force.technologies['nullius-waste-management'].researched=true
  check(force.recipes[ordinary].enabled,'Waste Management unlock')
  check(not force.recipes[boxed].enabled,'bulk unlocked early')
  force.technologies['nullius-mass-production-7'].researched=true
  check(force.recipes[boxed].enabled,'bulk unlock')
  for i,name in ipairs({ordinary,boxed}) do
    local item=i==1 and 'nullius-' or 'nullius-box-'
    local recipe=prototypes.recipe[name]
    check(not recipe.allowed_effects.productivity,'productivity changes disposal ratio')
    check(not recipe.surface_conditions or #recipe.surface_conditions==0,'planet restriction')
    check(recipe.energy==(i==1 and 2 or 10),'duration')
    local e=assert(surface.create_entity{name='nullius-crusher-1',position={(i-1)*8,0},force=force})
    e.set_recipe(name)
    check(e.get_recipe().name==name,'crusher recipe selection')
    check(e.insert{name=item..'sand',count=4}==4,'sand fixture')
    storage.rows[#storage.rows+1]={entity=e,item=item}
  end
  local grid=surface.create_entity{name='factorio-test-planner-grid',position={4,6},force=force}
  grid.power_production=100000000; grid.electric_buffer_size=100000000
  surface.create_entity{name='substation',position={4,3},force=force}
end)
script.on_nth_tick(1200,function()
  if game.tick==0 then return end
  for _,row in ipairs(storage.rows) do
    check(row.entity.products_finished==1,'one batch')
    check(row.entity.get_item_count(row.item..'sand')==0,'sand consumed')
    check(row.entity.get_output_inventory().get_item_count(row.item..'mineral-dust')==3,'dust yield')
  end
  helpers.write_file('factorio-tests/sand-crushing.json',helpers.table_to_json{
    schema=1,case='sand-crushing',status='pass',failure_count=0,
    assertions=storage.assertions,tick=game.tick,factorio_version=script.active_mods.base},false)
  script.on_nth_tick(1200,nil)
end)

-- given: 100 caustic solution, 50 carbon dioxide, and 900 kW debug electric power.
-- place/connect: a starter chemical plant and substation on Fulgora island ground.
-- act: research Inorganic Chemistry 1 and process one finite batch.
-- run: 600 ticks.
-- expect: wastewater only, no productivity, and net alkali loss in bootstrap recycling.
local count=0
local function check(ok,message) count=count+1; assert(ok,message) end
local name='nullius-caustic-carbonation'
local function amount(recipe,field,product)
  for _,part in pairs(prototypes.recipe[recipe][field]) do
    if part.name==product then return part.amount end
  end
  error(recipe..' has no '..product..' in '..field)
end
local function ratio(recipe,input,output)
  return amount(recipe,'products',output)/amount(recipe,'ingredients',input)
end
script.on_nth_tick(1,function()
  if game.tick==0 then return end
  script.on_nth_tick(1,nil)
  local surface=game.planets['nullius-fulgora'].create_surface()
  surface.request_to_generate_chunks({0,0},1); surface.force_generate_chunk_requests()
  for _,entity in pairs(surface.find_entities_filtered{area={{-12,-12},{12,12}}}) do entity.destroy() end
  local tiles={}
  for x=-12,12 do for y=-12,12 do tiles[#tiles+1]={name='fulgoran-rock',position={x,y}} end end
  surface.set_tiles(tiles,true)
  local force=game.forces.player
  check(not force.recipes[name].enabled,'carbonation unlocked before research')
  force.technologies['nullius-primitive-filtration'].researched=true
  check(not force.recipes[name].enabled,'primitive filtration must not unlock carbonation')
  force.technologies['nullius-primitive-filtration'].researched=false
  force.technologies['nullius-inorganic-chemistry-1'].researched=true
  check(force.recipes[name].enabled,'inorganic chemistry must unlock carbonation')
  check(not force.technologies['nullius-waste-reclamation'].researched,'bootstrap needs waste reclamation')
  local recipe=prototypes.recipe[name]
  check(not recipe.surface_conditions or #recipe.surface_conditions==0,'carbonation restricted to a planet')
  check(not recipe.allowed_effects.productivity,'carbonation allows productivity')
  check(#recipe.products==1 and recipe.products[1].name=='nullius-wastewater','unexpected carbonation product')
  check(not prototypes.recipe['nullius-boxed-caustic-carbonation'],'fluid-only recipe has a boxed variant')
  check(not prototypes.item['nullius-box-wastewater'],'wastewater has a boxed product')
  local caustic=amount(name,'ingredients','nullius-caustic-solution')
  local wastewater=amount(name,'products','nullius-wastewater')
  check(caustic==100 and wastewater==80,'carbonation fluid budget')
  check(amount(name,'ingredients','nullius-carbon-dioxide')==50,'carbon dioxide budget')
  local saline=wastewater*ratio('nullius-wastewater-filtration','nullius-wastewater','nullius-saline')
  -- Grant dilution water/saline for this upper bound, with no productivity at bootstrap.
  local dilution=math.max(
    ratio('nullius-caustic-solution','nullius-sodium-hydroxide','nullius-caustic-solution'),
    ratio('nullius-saline-caustic-solution','nullius-sodium-hydroxide','nullius-caustic-solution'))
  check(saline*ratio('nullius-saline-electrolysis','nullius-saline','nullius-sodium-hydroxide')*dilution<caustic,
    'saline electrolysis regenerates consumed alkali')
  for _,separation in ipairs({'nullius-water','nullius-boiling-saline'}) do
    check(saline*ratio(separation,'nullius-saline','nullius-brine')*
      ratio('nullius-brine-electrolysis','nullius-brine','nullius-sodium-hydroxide')*dilution<caustic,
      separation..' regenerates consumed alkali')
  end
  local machine=assert(surface.create_entity{name='nullius-chemical-plant-1',position={0,0},force=force})
  machine.set_recipe(name)
  check(machine.get_recipe() and machine.get_recipe().name==name,'starter chemical plant rejects recipe')
  check(machine.insert_fluid{name='nullius-caustic-solution',amount=100}==100,'caustic fixture')
  check(machine.insert_fluid{name='nullius-carbon-dioxide',amount=50}==50,'CO2 fixture')
  assert(surface.create_entity{name='factorio-test-trip-source-900000',position={5,0},force=force})
  surface.create_entity{name='substation',position={4,4},force=force}
  storage.machine=machine
  storage.assertions=count
end)
script.on_nth_tick(600,function()
  if game.tick==0 then return end
  count=storage.assertions
  local machine=storage.machine
  local status
  for key,value in pairs(defines.entity_status) do if value==machine.status then status=key end end
  check(machine.products_finished==1,'finite batch did not finish exactly once: '..helpers.table_to_json{
    status=status,energy=machine.energy,progress=machine.crafting_progress,
    speed=machine.crafting_speed,finished=machine.products_finished,fluids=machine.get_fluid_contents()})
  check(machine.get_fluid_count('nullius-wastewater')==80,'wastewater yield')
  check(machine.get_fluid_count('nullius-caustic-solution')==0,'caustic remains')
  check(machine.get_fluid_count('nullius-carbon-dioxide')==0,'CO2 remains')
  helpers.write_file('factorio-tests/fulgora-caustic-carbonation.json',helpers.table_to_json{
    schema=1,case='fulgora-caustic-carbonation',status='pass',failure_count=0,assertions=count,
    tick=game.tick,factorio_version=script.active_mods.base},false)
  script.on_nth_tick(600,nil)
end)

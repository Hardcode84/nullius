-- given: one finite input batch for each stage recipe, two productivity modules,
-- one probe, ten iron plates, a supplied electric grid, and an orbital starter pack.
-- place/connect: two overcharged assemblers and two ordinary silos on Nauvis.
-- act/run: craft both stages, transfer them to silos, launch cargo and a probe.
-- expect: stage productivity is zero; silo productivity works; cargo arrives;
-- the production mission counter records the probe.
local CASE = "launch-vehicle"
local function check(ok, message)
  storage.assertions = storage.assertions + 1
  assert(ok, message)
end
script.on_init(function()
  storage.assertions = 0
  storage.rows = {}
  local surface = game.surfaces.nauvis
  surface.request_to_generate_chunks({0,0}, 3)
  surface.force_generate_chunk_requests()
  for _, entity in pairs(surface.find_entities_filtered{area={{-25,-25},{65,25}}}) do entity.destroy() end
  local tiles = {}
  for x=-25,65 do for y=-25,25 do tiles[#tiles+1]={name="grass-1",position={x,y}} end end
  surface.set_tiles(tiles)
  local force = game.forces.player
  force.technologies["nullius-rocket-science-1"].researched = true
  force.technologies["nullius-rocket-science-2"].researched = true
  for _, name in ipairs{"nullius-rocket-stage", "nullius-titanium-rocket-stage", "nullius-rocket", "nullius-silo"} do
    check(force.recipes[name].enabled, "research unlock "..name)
  end
  local platform = assert(force.create_space_platform{
    name=CASE, planet="nauvis", starter_pack="space-platform-starter-pack"})
  storage.hub = assert(platform.apply_starter_pack(true))
  storage.probes_before = remote.call("nullius-test-launch-mission", "probes")
  for index, recipe in ipairs{"nullius-rocket-stage", "nullius-titanium-rocket-stage"} do
    local x=(index-1)*30
    local assembler=assert(surface.create_entity{name="nullius-large-assembler-1-overcharged",position={x,0},force=force})
    check(assembler.set_recipe(recipe), "stage recipe category")
    local silo=assert(surface.create_entity{name="nullius-silo",position={x,22},force=force})
    check(silo.prototype.launch_to_space_platforms, "silo can launch cargo")
    check(silo.get_module_inventory().insert{name="nullius-productivity-module-1",count=1}==1,"silo module")
    local power=assert(surface.create_entity{name="factorio-test-planner-grid",position={x,10},force=force})
    power.power_production=1e9;power.electric_buffer_size=1e9
    assert(surface.create_entity{name="substation",position={x,5},force=force})
    assert(surface.create_entity{name="substation",position={x,17},force=force})
    for _, input in pairs(prototypes.recipe[recipe].ingredients) do
      check(assembler.insert{name=input.name,count=input.amount}==input.amount,"finite input "..input.name)
    end
    storage.rows[index]={assembler=assembler,silo=silo,power=power}
  end
end)
script.on_nth_tick(60,function()
  if game.tick==0 then return end
  for index,row in ipairs(storage.rows) do
    if not row.transferred and row.assembler.get_output_inventory().get_item_count("nullius-rocket-stage")>0 then
      check(row.assembler.products_finished==1,"one paid stage")
      check(row.assembler.bonus_progress==0,"no stage productivity")
      check(row.assembler.get_output_inventory().remove{name="nullius-rocket-stage",count=1}==1,"remove stage")
      check(row.silo.insert{name="nullius-rocket-stage",count=1}==1,"transfer stage")
      row.transferred=true
    end
    if row.transferred and not row.launched and row.silo.rocket_silo_status==defines.rocket_silo_status.rocket_ready then
      check(row.silo.products_finished==1,"one native rocket")
      check(row.silo.bonus_progress>0,"silo productivity accrued")
      local inventory=assert(row.silo.get_inventory(defines.inventory.rocket_silo_rocket))
      if index==1 then
        check(inventory.insert{name="iron-plate",count=10}==10,"cargo payload")
        check(row.silo.launch_rocket{type=defines.cargo_destination.station,station=storage.hub},"cargo launch")
      else
        check(inventory.insert{name="nullius-probe",count=1}==1,"probe payload")
        row.silo.send_to_orbit_automatically=true
      end
      row.launched=true
    end
  end
  if storage.hub.get_inventory(defines.inventory.hub_main).get_item_count("iron-plate")==10 and
      remote.call("nullius-test-launch-mission","probes")==storage.probes_before+1 then
    for _,row in ipairs(storage.rows) do
      check(row.launched,"both launch paths")
      check(row.assembler.get_output_inventory().is_empty(),"no extra stage")
      check(row.silo.get_item_count("nullius-rocket-stage")==0,"stage consumed")
    end
    helpers.write_file("factorio-tests/"..CASE..".json",helpers.table_to_json{
      schema=1,case=CASE,status="pass",assertions=storage.assertions,failure_count=0,
      tick=game.tick,factorio_version=script.active_mods.base},false)
    script.on_nth_tick(60,nil)
  else
    if game.tick >= 15000 then
      local rows = {}
      for _, row in ipairs(storage.rows) do
        rows[#rows+1]={assembler_status=row.assembler.status, assembler_progress=row.assembler.crafting_progress,
          stages=row.assembler.products_finished, silo_status=row.silo.rocket_silo_status,
          rockets=row.silo.products_finished, transferred=row.transferred, launched=row.launched,
          power=row.assembler.energy, source_energy=row.power.energy,
          status_name=(function() for name,id in pairs(defines.entity_status) do if id==row.assembler.status then return name end end end)()}
      end
      error(helpers.table_to_json{rows=rows,hub=storage.hub.get_inventory(defines.inventory.hub_main).get_contents(),
        probes=remote.call("nullius-test-launch-mission","probes"), initial_probes=storage.probes_before})
    end
  end
end)

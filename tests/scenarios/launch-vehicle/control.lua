-- given: one finite input batch for each stage recipe, two productivity modules,
-- one probe, ten iron plates, a supplied electric grid, an orbital starter pack,
-- and a mission whose other required goals are complete with one probe left.
-- place/connect: two overcharged assemblers and two ordinary silos on Nauvis;
-- an inserter loads the probe from a chest into the second silo's rocket.
-- act/run: craft both stages, transfer them to silos, launch cargo and the probe.
-- expect: the titanium stage unlocks only with titanium rocket structures;
-- stage productivity is zero; silo productivity works; cargo arrives;
-- the probe launch completes the mission and wins the game.
local CASE = "launch-vehicle"
-- Every required mission goal but the probe, which the launch completes.
local OTHER_GOALS = {2, 3, 4, 5, 6, 7, 8, 9, 12, 13}
local PROBE_GOAL = 10
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
  for _, name in ipairs{"nullius-rocket-stage", "nullius-rocket", "nullius-silo"} do
    check(force.recipes[name].enabled, "research unlock "..name)
  end
  check(not force.recipes["nullius-titanium-rocket-stage"].enabled,
    "titanium stage waits for Vulcanus titanium research")
  force.technologies["nullius-titanium-rocket-structures"].researched = true
  check(force.recipes["nullius-titanium-rocket-stage"].enabled, "research unlock nullius-titanium-rocket-stage")
  local platform = assert(force.create_space_platform{
    name=CASE, planet="nauvis", starter_pack="space-platform-starter-pack"})
  storage.hub = assert(platform.apply_starter_pack(true))
  -- Victory pauses a single-player game, so this case runs as multiplayer; the
  -- server keeps real time unless sped up.
  game.speed = 8
  remote.call("nullius-test-mission", "create", force)
  for _, goal in ipairs(OTHER_GOALS) do
    remote.call("nullius-test-mission", "set_goal", goal, 1e12, force)
  end
  remote.call("nullius-test-mission", "set_goal", 1, PROBE_GOAL - 1, force)
  check(not remote.call("nullius-test-mission", "complete"), "mission finished before the last probe")
  storage.probes_before = remote.call("nullius-test-mission", "probes")
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
  -- The probe reaches the rocket the way a player's factory delivers it.
  local probe_silo = storage.rows[2].silo
  probe_silo.send_to_orbit_automatically = true
  -- The 9x9 silo's west edge is five tiles from its centre.
  local at = probe_silo.position
  local chest = assert(surface.create_entity{name="wooden-chest",position={at.x-6,at.y},force=force})
  check(chest.insert{name="nullius-probe",count=1}==1, "probe supply")
  local inserter = assert(surface.create_entity{name="inserter",position={at.x-5,at.y},
    direction=defines.direction.west,force=force})
  -- Targets resolve on the first update, so check the arm's geometry: it picks
  -- up over the chest and drops inside the silo.
  check(math.floor(inserter.pickup_position.x) == math.floor(chest.position.x) and
    inserter.drop_position.x > at.x - 4.5, "inserter feeds the probe silo")
  storage.probe_chest = chest
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
        row.launched=true
      end
    end
  end
  if remote.call("nullius-test-mission","probes")==storage.probes_before+1 then
    storage.rows[2].launched=true
  end
  if storage.hub.get_inventory(defines.inventory.hub_main).get_item_count("iron-plate")==10 and
      storage.rows[2].launched then
    check(storage.probe_chest.get_item_count("nullius-probe")==0, "the inserter loaded the probe")
    check(remote.call("nullius-test-mission","complete"), "the last probe did not complete the mission")
    check(game.finished or game.finished_but_continuing, "the last probe did not win the game")
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
        probes=remote.call("nullius-test-mission","probes"), initial_probes=storage.probes_before})
    end
  end
end)

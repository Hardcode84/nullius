-- given: finite rocket stages, probes, inventory plates and gas; an electric comparison grid.
-- place/connect: paired silos on Vulcanus, with tanks on the gas ports.
-- act/run: build and launch probes; remove and restore fuel during both phases.
-- expect: native fuel use and replacement observations decide the switch gate.
local CASE = "experiment-pneumatic-silo"
local function check(value,message)
  storage.assertions=storage.assertions+1
  assert(value,message)
  return value
end
local function fuel(row)
  local f = row.silo.get_fluid_segment_fluid(1)
  return f and f.amount or 0
end
local function setup()
  storage.assertions = 0
  storage.rows = {}
  storage.observations = {}
  local planet = game.planets["nullius-vulcanus"]
  local s = planet.surface or planet.create_surface()
  s.request_to_generate_chunks({0,0}, 3); s.force_generate_chunk_requests()
  for _, e in pairs(s.find_entities()) do e.destroy() end
  local tiles = {}
  for x=-30,80 do for y=-20,30 do tiles[#tiles+1]={name="volcanic-soil-dark",position={x,y}} end end
  s.set_tiles(tiles); s.daytime=0; s.freeze_daytime=true
  local f=game.forces.player
  f.technologies["nullius-rocket-science-2"].researched=true
  f.technologies["nullius-pneumatic-technology"].researched=true
  for i=1,3 do
    local e=check(s.create_entity{name="nullius-silo-pneumatic",position={(i-1)*25,0},force=f})
    local tank=check(s.create_entity{name="nullius-medium-tank-2",position={(i-1)*25+6,1},force=f})
    tank.set_fluid(1,{name="nullius-compressed-volcanic-gas",amount=30000,temperature=200})
    e.insert{name="nullius-rocket-stage",count=1}
    storage.rows[i]={silo=e,tank=tank}
  end
  local e=check(s.create_entity{name="nullius-silo",position={0,20},force=f})
  local grid=check(s.create_entity{name="factorio-test-planner-grid",position={10,20},force=f})
  grid.power_production=1e9; grid.electric_buffer_size=1e9
  storage.pole=check(s.create_entity{name="substation",position={7,20},force=f})
  e.insert{name="nullius-rocket-stage",count=1}
  storage.electric=e
  e=check(s.create_entity{name="nullius-silo",position={25,20},force=f})
  e.send_to_orbit_automatically=true
  e.use_transitional_requests=true
  e.get_or_create_control_behavior().read_mode=1
  for name,id in pairs(defines.inventory) do
    if name:find("rocket_silo") then
      local inv=e.get_inventory(id)
      if inv and name~="rocket_silo_input" and name~="rocket_silo_modules" then
        inv.insert{name="iron-plate",count=3}
      end
    end
  end
  local sections=e.get_logistic_sections()
  storage.observations.logistic_sections=sections~=nil
  if sections then
    sections.add_section("silo fixture").set_slot(1,{value={type="item",name="iron-plate",quality="normal"},min=5,max=5})
  end
  storage.idle=e
end
local function replace(e,name)
  return check(e.surface.create_entity{name=name,position=e.position,force=e.force,
    fast_replace=true,spill=false})
end
script.on_nth_tick(1,function()
  setup(); script.on_nth_tick(1,nil)
end)
script.on_nth_tick(60,function()
  local obs=storage.observations
  local a=storage.rows[1]
  if game.tick==120 then
    local e=storage.idle
    local function snapshot(entity)
      local result={automatic=entity.send_to_orbit_automatically,requests=entity.use_transitional_requests,
        circuit=entity.get_or_create_control_behavior().read_mode,inventories={}}
      for name,id in pairs(defines.inventory) do
        if name:find("rocket_silo") then
          local inv=entity.get_inventory(id)
          if inv then result.inventories[name]=inv.get_contents() end
        end
      end
      local sections=entity.get_logistic_sections()
      if sections then result.section_count=sections.sections_count; result.section=sections.get_section(2).filters end
      return result
    end
    obs.idle_before=snapshot(e)
    e=replace(e,"nullius-silo-pneumatic"); e=replace(e,"nullius-silo")
    storage.idle=e
    obs.idle_after=snapshot(e)
    obs.electric_craft_start=storage.pole.electric_network_statistics.get_input_count("nullius-silo")
    obs.craft_start=fuel(a)
    obs.progress_start=a.silo.crafting_progress
    local e=storage.rows[3].silo
    obs.partial_before={progress=e.crafting_progress,parts=e.rocket_parts}
    e=replace(e,"nullius-silo"); e=replace(e,"nullius-silo-pneumatic")
    storage.rows[3].silo=e
    obs.partial_after={progress=e.crafting_progress,parts=e.rocket_parts}
  elseif game.tick==180 then
    obs.craft_per_second=obs.craft_start-fuel(a)
    obs.electric_craft_per_second=storage.pole.electric_network_statistics.get_input_count("nullius-silo")-obs.electric_craft_start
    check(math.abs(obs.electric_craft_per_second-obs.craft_per_second*20000)<1,
      "craft gas energy matches total electric draw")
    obs.craft_progress_per_second=a.silo.crafting_progress-obs.progress_start
    check(math.abs(obs.craft_per_second-50)<0.001,"1000 kW crafting")
    check(math.abs(obs.craft_progress_per_second-1/60)<0.000001,"full crafting speed")
    a.silo.surface.daytime=0.5
    obs.night_start=fuel(a)
    obs.electric_night_start=storage.pole.electric_network_statistics.get_input_count("nullius-silo")
    local b=storage.rows[2]
    b.tank.destroy(); b.silo.clear_fluid(1)
  elseif game.tick==240 then
    obs.night_per_second=obs.night_start-fuel(a)
    obs.electric_night_per_second=storage.pole.electric_network_statistics.get_input_count("nullius-silo")-obs.electric_night_start
    check(math.abs(obs.electric_night_per_second-obs.night_per_second*20000)<1,
      "night lamp rating matches electric mode")
    a.silo.surface.daytime=0
    storage.rows[2].paused=storage.rows[2].silo.crafting_progress
  elseif game.tick==300 then
    obs.fuel_loss={before=storage.rows[2].paused,after=storage.rows[2].silo.crafting_progress,energy=storage.rows[2].silo.energy,gas=fuel(storage.rows[2])}
    check(storage.rows[2].silo.crafting_progress==storage.rows[2].paused,"fuel loss pauses craft")
    storage.rows[2].tank=check(storage.rows[2].silo.surface.create_entity{name="nullius-medium-tank-2",position={31,1},force=game.forces.player})
    storage.rows[2].tank.set_fluid(1,{name="nullius-compressed-volcanic-gas",amount=30000,temperature=200})
  end
  for i,row in ipairs(storage.rows) do
    local e=row.silo
    if not row.ready and e.rocket_silo_status==defines.rocket_silo_status.rocket_ready then
      row.ready=game.tick
      e.get_inventory(defines.inventory.rocket_silo_rocket).insert{name="nullius-probe",count=1}
      if i==3 then
        obs.ready_before={parts=e.rocket_parts,cargo=e.get_inventory(defines.inventory.rocket_silo_rocket).get_contents()}
        e=replace(e,"nullius-silo"); e=replace(e,"nullius-silo-pneumatic"); row.silo=e
        local inv=e.get_inventory(defines.inventory.rocket_silo_rocket)
        obs.ready_after={parts=e.rocket_parts,cargo=inv and inv.get_contents() or {}}
      else
        e.send_to_orbit_automatically=true
      end
    end
    if i==1 and row.ready then
      local status=e.rocket_silo_status
      obs["status_"..status]=obs["status_"..status] or {tick=game.tick,gas=fuel(row)}
      if row.previous_status==status then
        obs["rate_"..status]=row.previous_fuel-fuel(row)
      end
      row.previous_status=status; row.previous_fuel=fuel(row)
      if status~=defines.rocket_silo_status.building_rocket then
        check(remote.call("nullius-test-transitions","execute",e),"registered silo gate")
        check(e.valid,"assembled and launching silo must not switch")
      end
    end
    if i==2 and e.rocket_silo_status==defines.rocket_silo_status.engine_starting and not row.cut then
      row.cut=game.tick;row.tank.destroy();e.clear_fluid(1)
    end
    if i==2 and row.cut then
      if game.tick==row.cut+120 then row.stopped=e.rocket_silo_status end
      if game.tick==row.cut+180 then
        obs.launch_loss={before=row.stopped,after=e.rocket_silo_status,gas=fuel(row),energy=e.energy}
        row.tank=check(e.surface.create_entity{name="nullius-medium-tank-2",position={31,1},force=e.force})
        row.tank.set_fluid(1,{name="nullius-compressed-volcanic-gas",amount=10000,temperature=200})
      end
    end
  end
  local electric=storage.electric
  local status=electric.rocket_silo_status
  if status==defines.rocket_silo_status.rocket_ready and not storage.electric_launched then
    check(remote.call("nullius-test-transitions","execute",electric),"electric silo gate")
    check(electric.valid,"assembled electric silo cannot switch")
    check(electric.get_inventory(defines.inventory.rocket_silo_rocket).insert{name="nullius-probe",count=1}==1,
      "electric comparison probe")
    electric.send_to_orbit_automatically=true
    storage.electric_launched=true
  end
  local used=storage.pole.electric_network_statistics.get_input_count("nullius-silo")
  if storage.electric_status==status then obs["electric_rate_"..status]=used-storage.electric_used end
  storage.electric_status=status; storage.electric_used=used
  if game.tick==7200 then
    check(storage.rows[1].silo.products_finished==1,"gas rocket built")
    check(storage.rows[2].silo.products_finished==1,"fuel-loss rocket built")
    check(remote.call("nullius-test-mission","probes")==3,"three probes launched")
    check(math.abs(obs.night_per_second-60)<0.001,"night lamp adds 200 kW")
    check(math.abs(obs["rate_"..defines.rocket_silo_status.engine_starting]-140)<0.001,"launch draws 2800 kW")
    check(math.abs(obs["electric_rate_"..defines.rocket_silo_status.engine_starting]-
      obs["rate_"..defines.rocket_silo_status.engine_starting]*20000)<1,
      "launch gas energy matches total electric draw")
    check(obs.launch_loss.before==obs.launch_loss.after and obs.launch_loss.energy==0,"fuel loss pauses launch")
    check(storage.electric.products_finished==1,"electric comparison rocket built")
    local e=storage.rows[1].silo
    check(e.rocket_silo_status==defines.rocket_silo_status.building_rocket,"launch sequence completed")
    local surface=e.surface
    check(remote.call("nullius-test-transitions","execute",e),"post-launch switch")
    storage.rows[1].silo=check(surface.find_entity("nullius-silo",{0,0}))
    check(storage.rows[1].silo.products_finished==1,"launched rocket counter survives switch")
    obs.electric_products=storage.electric.products_finished
    for i,r in ipairs(storage.rows) do obs["row_"..i]={ready=r.ready,products=r.silo.products_finished,status=r.silo.rocket_silo_status} end
    helpers.write_file("factorio-tests/"..CASE..".json",helpers.table_to_json{
      schema=1,case=CASE,status="pass",assertions=storage.assertions,failure_count=0,observations=obs,tick=game.tick},false)
    script.on_nth_tick(60,nil)
  end
end)

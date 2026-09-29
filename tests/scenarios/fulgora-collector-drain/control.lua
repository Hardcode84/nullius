-- given: two empty production collectors, one 100 MW debug load, no ambient storms.
-- place/connect: native collectors on separate loaded and idle networks; omit overload registration.
-- act: one native production lightning strike per collector; no further energy input.
-- run: 3 seconds; measure native buffer energy and available output.
-- expect: 100 MW discharge under demand, eventual exhaustion, no idle leakage.
local function check(ok,message) storage.assertions=storage.assertions+1;assert(ok,message) end
script.on_nth_tick(1,function()
  if game.tick==0 then return end
  script.on_nth_tick(1,nil);storage.assertions=0;storage.samples={};storage.rows={}
  local surface=game.planets['nullius-fulgora'].create_surface()
  surface.request_to_generate_chunks({50,0},4);surface.force_generate_chunk_requests()
  for _,e in pairs(surface.find_entities()) do e.destroy() end
  for _,x in ipairs({0,100}) do
    local pole=assert(surface.create_entity{name='factorio-test-trip-pole',position={x,0},force='player'})
    local collector=assert(surface.create_entity{name='nullius-pole-lightning-collector',position=pole.position,force='player'})
    check(collector and collector.energy==0,'collector must start empty')
    local source=collector.prototype.electric_energy_source_prototype
    check(math.abs(source.buffer_capacity/source.get_output_flow_limit()-120)<1e-9,'buffer must discharge in 120 ticks')
    storage.rows[#storage.rows+1]={pole=pole,collector=collector}
    surface.execute_lightning{name='nullius-fulgora-lightning',position=pole.position}
  end
  storage.load=assert(surface.create_entity{name='factorio-test-power-dump-100',position={1,1},force='player'})
end)
script.on_nth_tick(30,function()
  if game.tick==0 then return end
  local sample={tick=game.tick,seconds=game.tick/60,networks={}}
  for _,row in ipairs(storage.rows) do
    local flow=row.pole.electric_network.parent_network.flow_last_tick
    sample.networks[#sample.networks+1]={energy_MJ=row.collector.energy/1e6,
      offered_MW=(flow.primary_output+flow.secondary_output+flow.solar_output)*60/1e6,
      demand_MW=(flow.primary_demand+flow.secondary_demand+flow.tertiary_demand)*60/1e6}
  end
  storage.samples[#storage.samples+1]=sample
  if game.tick==60 then
    local lost=storage.samples[1].networks[1].energy_MJ-sample.networks[1].energy_MJ
    check(math.abs(lost-50)<0.00001,'loaded collector did not discharge at 100 MW')
    check(math.abs(sample.networks[1].offered_MW-100)<1e-9,'unexpected available output')
    check(sample.networks[2].energy_MJ==200,'idle collector leaked energy')
  elseif game.tick==180 then
    check(sample.networks[1].energy_MJ==0,'collector never emptied')
    check(sample.networks[1].offered_MW==0,'empty collector still offers power')
    check(storage.load.energy==0,'load still powered after depletion')
    check(sample.networks[2].energy_MJ==200,'idle collector lost energy')
    helpers.write_file('factorio-tests/fulgora-collector-drain.json',helpers.table_to_json{
      schema=1,case='fulgora-collector-drain',status='pass',failure_count=0,assertions=storage.assertions,
      tick=game.tick,factorio_version=script.active_mods.base,observations={samples=storage.samples}},false)
    script.on_nth_tick(30,nil)
  end
end)

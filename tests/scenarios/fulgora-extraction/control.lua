-- given: production Fulgora seeds 0, 1, 8675309; one extractor and substation
-- per seed; declared debug electricity and a 6x6 firm patch for its source.
-- place: extractors on generated sand vents within 512 tiles of the origin.
-- connect: electricity through a production substation; fluid stays in extractor.
-- act/run: extract for 119 ticks.
-- expect: native extractors produce slurry without changing the vent's sand.
local fluids = require('__nullius-star__/scenarios/fluid-api')
local assertions = 0
local function check(ok, message)
  assertions = assertions+1
  assert(ok,message)
end
script.on_nth_tick(1,function()
  if game.tick==0 then return end
  script.on_nth_tick(1,nil)
  storage.rows = {}
  local settings = game.planets['nullius-fulgora'].create_surface().map_gen_settings
  for _,seed in ipairs({0,1,8675309}) do
    settings.seed = seed
    local surface = game.create_surface('fulgora-extraction-'..seed,settings)
    surface.request_to_generate_chunks({0,0},16)
    surface.force_generate_chunk_requests()
    local vents = surface.find_entities_filtered{name='nullius-hydrocarbon-vent',position={0,0},radius=512}
    table.sort(vents,function(a,b)
      return a.position.x^2+a.position.y^2 < b.position.x^2+b.position.y^2
    end)
    local vent, position
    for _,candidate in ipairs(vents) do
      local p = {x=math.floor(candidate.position.x),y=math.floor(candidate.position.y)}
      if surface.can_place_entity{name='nullius-extractor-1',position=p,force='player'} then
        vent,position = candidate,p
        break
      end
    end
    check(vent~=nil,'no usable starter vent within 512 tiles, seed '..seed..' deposits '..#vents)
    local tile = surface.get_tile(vent.position).name
    check(tile:find('nullius-fulgora-sediment',1,true)==1,'vent is not on sand')
    local patch = {}
    for x=position.x+6,position.x+11 do
      for y=position.y-3,position.y+2 do
        patch[#patch+1]={name='fulgoran-rock',position={x,y}}
      end
    end
    for _,entity in pairs(surface.find_entities_filtered{
        area={{position.x+3,position.y-4},{position.x+12,position.y+5}}}) do entity.destroy() end
    surface.set_tiles(patch,true)
    local power = surface.create_entity{name='factorio-test-planner-grid',
      position={position.x+8,position.y},force='player'}
    power.power_production = 100000000
    power.electric_buffer_size = 100000000
    local pole = {name='substation',position={position.x+4,position.y+3},force='player'}
    check(surface.can_place_entity(pole),'substation placement failed')
    check(surface.create_entity(pole)~=nil,'substation creation failed')
    local drill = surface.create_entity{name='nullius-extractor-1',position=position,force='player'}
    check(drill~=nil,'extractor creation failed')
    check(power.electric_network_id==drill.electric_network_id,'extractor is disconnected')
    storage.rows[#storage.rows+1]={drill=drill,vent=vent,tile=tile,seed=seed,power=power}
  end
  storage.assertions = assertions
end)
script.on_nth_tick(120,function()
  if game.tick==0 then return end
  script.on_nth_tick(120,nil)
  assertions = storage.assertions
  local observations = {}
  for _,row in ipairs(storage.rows) do
    local fluid = fluids.get(row.drill,1)
    local status
    for name,value in pairs(defines.entity_status) do
      if value==row.drill.status then status=name end
    end
    check(fluid and fluid.name=='nullius-hydrocarbon-slurry' and fluid.amount>0,
      'extractor did not produce slurry, seed '..row.seed..' status '..status..
      ' energy '..row.drill.energy..' source '..row.power.energy..
      ' target '..tostring(row.drill.mining_target))
    check(row.vent.surface.get_tile(row.vent.position).name==row.tile,'extraction changed sand')
    observations[#observations+1]={seed=row.seed,position=row.vent.position,amount=fluid.amount}
  end
  helpers.write_file('factorio-tests/fulgora-extraction.json',helpers.table_to_json{
    schema=1,case='fulgora-extraction',status='pass',failure_count=0,assertions=assertions,
    tick=game.tick,factorio_version=script.active_mods.base,observations=observations},false)
end)

-- given: Fulgora and its real tile prototypes; no supplied items or research.
-- place: cleared 64x64 patches of every sediment type and firm ground.
-- act: test native support, ramp, and ordinary building placement.
-- run: once at tick 1.
-- expect: supports can stand in sediment; ramps and factories need firm ground.
local assertions = 0
local function check(value, message)
  assertions = assertions + 1
  assert(value, message)
end
script.on_nth_tick(1, function()
  if game.tick==0 then return end
  script.on_nth_tick(1,nil)
  local surface = game.planets['nullius-fulgora'].create_surface()
  surface.request_to_generate_chunks({0,0},2)
  surface.force_generate_chunk_requests()
  for _,entity in pairs(surface.find_entities_filtered{area={{-32,-32},{32,32}}}) do
    entity.destroy()
  end
  local names = {'fulgoran-rock'}
  for name in pairs(prototypes.tile) do
    if name:find('nullius-fulgora-sediment',1,true)==1 then names[#names+1]=name end
  end
  for _,name in ipairs(names) do
    local tiles = {}
    for x=-32,31 do for y=-32,31 do tiles[#tiles+1]={name=name,position={x,y}} end end
    surface.set_tiles(tiles,true)
    local support = {name='rail-support',position={0,0},direction=defines.direction.north,force='player'}
    check(surface.can_place_entity(support),'support blocked on '..name)
    local entity = surface.create_entity(support)
    check(entity and entity.valid,'support creation failed on '..name)
    entity.destroy()
    local firm = name=='fulgoran-rock'
    check(surface.can_place_entity{name='rail-ramp',position={0,0},
      direction=defines.direction.north,force='player'}==firm,'ramp ground contract: '..name)
    check(surface.can_place_entity{name='nullius-small-assembler-1',position={0,0},force='player'}==firm,
      'factory ground contract: '..name)
    for _,building in ipairs({'pipe','pipe-to-ground','nullius-pump-1',
        'small-electric-pole','nullius-pylon-2'}) do
      for _,direction in ipairs({defines.direction.north,defines.direction.east,
          defines.direction.south,defines.direction.west}) do
        check(surface.can_place_entity{name=building,position={0,0},direction=direction,force='player'},
          building..' blocked on '..name)
      end
    end
    for _,building in ipairs({'transport-belt','wooden-chest','nullius-small-tank-1',
        'nullius-grid-battery-1','nullius-hydro-plant-1','nullius-geothermal-build-1'}) do
      check(surface.can_place_entity{name=building,position={0,0},force='player'}==firm,
        building..' ground contract: '..name)
    end
    local vent = surface.create_entity{name='nullius-hydrocarbon-vent',position={0,0},amount=300000}
    check(surface.get_tile(0,0).name==name,'vent changed terrain on '..name)
    for _,building in ipairs({'nullius-extractor-1','nullius-extractor-2'}) do
      check(surface.can_place_entity{name=building,position={0,0},force='player'},
        building..' blocked on '..name)
    end
    vent.destroy()
  end
  local water = {}
  for x=-32,31 do for y=-32,31 do
    water[#water+1]={name='water',position={x,y}}
  end end
  surface.set_tiles(water,true)
  for _,building in ipairs({'pipe','pipe-to-ground','nullius-pump-1','small-electric-pole'}) do
    check(not surface.can_place_entity{name=building,position={0,0},force='player'},
      building..' gained water placement')
  end
  helpers.write_file('factorio-tests/fulgora-rail-supports.json',helpers.table_to_json{
    schema=1,case='fulgora-rail-supports',status='pass',failure_count=0,
    assertions=assertions,tick=game.tick,factorio_version=script.active_mods.base},false)
end)

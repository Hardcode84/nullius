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
  end
  helpers.write_file('factorio-tests/fulgora-rail-supports.json',helpers.table_to_json{
    schema=1,case='fulgora-rail-supports',status='pass',failure_count=0,
    assertions=assertions,tick=game.tick,factorio_version=script.active_mods.base},false)
end)

-- given: powered wells on cleared ground on Nauvis, Vulcanus, and Fulgora.
-- place: every groundwater machine on Nauvis; check rejected placement on other planets.
-- act: query native placement and allow the fixed pumping recipe to run.
-- run: 600 ticks with declared 100 MW debug grids; no input materials.
-- expect: Fulgora and Vulcanus reject wells; Nauvis remains operational.
local CASE='fulgora-wells'
local function check(ok,message)
  storage.assertions=storage.assertions+1
  assert(ok,message)
end
script.on_nth_tick(1,function()
  if game.tick==0 then return end
  script.on_nth_tick(1,nil)
  storage.assertions=0;storage.rows={}
  local names={}
  for name,entity in pairs(prototypes.entity) do
    if entity.type=='assembling-machine' and entity.crafting_categories and
        entity.crafting_categories['water-pumping'] and not name:find('factorio-test-',1,true) then
      names[#names+1]=name
    end
  end
  table.sort(names)
  check(#names>=4,'both well tiers and legacy variants must be present')
  for _,planet in ipairs({'nauvis','nullius-vulcanus','nullius-fulgora'}) do
    local surface=planet=='nauvis' and game.surfaces.nauvis or
      (game.planets[planet].surface or game.planets[planet].create_surface())
    surface.ignore_surface_conditions=false
    surface.request_to_generate_chunks({0,0},4);surface.force_generate_chunk_requests()
    for _,entity in pairs(surface.find_entities_filtered{area={{-10,-10},{160,10}}}) do entity.destroy() end
    local tiles={}
    for x=-10,160 do for y=-10,10 do tiles[#tiles+1]={name='fulgoran-rock',position={x,y}} end end
    surface.set_tiles(tiles,true)
    for i,name in ipairs(names) do
      local spec={name=name,position={i*20,0},force='player'}
      check(surface.can_place_entity(spec)==(planet=='nauvis'),planet..' placement '..name)
      if planet=='nauvis' then
      local machine=assert(surface.create_entity(spec))
      local grid=assert(surface.create_entity{name='factorio-test-planner-grid',position={i*20+5,0},force='player'})
      grid.power_production=100000000;grid.electric_buffer_size=100000000
      assert(surface.create_entity{name='substation',position={i*20+3,3},force='player'})
      storage.rows[#storage.rows+1]={machine=machine,planet=planet}
      end
    end
  end
end)
script.on_nth_tick(600,function()
  if game.tick==0 then return end
  for _,row in ipairs(storage.rows) do
    check((row.machine.products_finished>0)==(row.planet=='nauvis'),
      row.planet..' groundwater extraction '..row.machine.name..' status='..row.machine.status..
      ' energy='..row.machine.energy..' recipe='..tostring(row.machine.get_recipe() and row.machine.get_recipe().name))
  end
  helpers.write_file('factorio-tests/'..CASE..'.json',helpers.table_to_json{
    schema=1,case=CASE,status='pass',failure_count=0,assertions=storage.assertions,
    tick=game.tick,factorio_version=script.active_mods.base},false)
  script.on_nth_tick(600,nil)
end)

-- given: twelve fixed seeds with production Fulgora map settings.
-- place: generate a 1024x1024 landing region; no injected entities or resources.
-- act/run: survey generated vents once at tick 1.
-- expect: at least three usable vents within 256 tiles for every declared seed.
local assertions=0
local function check(ok,message) assertions=assertions+1; assert(ok,message) end
script.on_nth_tick(1,function()
  if game.tick==0 then return end
  script.on_nth_tick(1,nil)
  local settings=game.planets['nullius-fulgora'].create_surface().map_gen_settings
  local rows={}
  for _,seed in ipairs({0,1,2,3,4,5,6,7,8,9,42,8675309}) do
    settings.seed=seed
    local surface=game.create_surface('fulgora-coverage-'..seed,settings)
    surface.request_to_generate_chunks({0,0},16)
    surface.force_generate_chunk_requests()
    local vents=surface.find_entities_filtered{name='nullius-hydrocarbon-vent',position={0,0},radius=512}
    local near,usable,closest=0,0,nil
    local usable_vents={}
    for _,vent in ipairs(vents) do
      local p=vent.position
      local distance=math.sqrt(p.x*p.x+p.y*p.y)
      closest=closest and math.min(closest,distance) or distance
      check(surface.get_tile(p).name:find('nullius-fulgora-sediment',1,true)==1,'vent off sediment')
      if distance<=256 then
        near=near+1
        if surface.can_place_entity{name='nullius-extractor-1',position={math.floor(p.x),math.floor(p.y)},force='player'} then
          usable=usable+1
          usable_vents[#usable_vents+1]={distance=distance,yield=vent.amount/vent.prototype.normal_resource_amount}
        end
      end
    end
    check(usable>=3,'fewer than three usable vents within 256 tiles, seed '..seed..': '..usable)
    table.sort(usable_vents,function(a,b) return a.distance<b.distance end)
    local starter_yield=0
    local starter_vents={}
    for i=1,3 do
      starter_yield=starter_yield+usable_vents[i].yield
      starter_vents[i]=usable_vents[i]
    end
    rows[#rows+1]={starter_mean_yield=starter_yield/3,starter_vents=starter_vents,seed=seed,within_512=#vents,within_256=near,usable_within_256=usable,nearest=closest}
    game.delete_surface(surface)
  end
  helpers.write_file('factorio-tests/fulgora-vent-coverage.json',helpers.table_to_json{
    schema=1,case='fulgora-vent-coverage',status='pass',failure_count=0,assertions=assertions,
    tick=game.tick,factorio_version=script.active_mods.base,observations=rows},false)
end)

-- given: shipping prototypes on Factorio 2.1; 1234 water per tank
-- act: upgrade filled tanks and inspect radar, fuel recipes, and planet lighting
-- expect: all twelve logistics entities have no radar coverage
script.on_nth_tick(1,function()
  if game.tick==0 then return end
  assert(not game.forces.player.recipes["nullius-legacy-large-tank-3"].enabled)
  local rows={}
  for _,family in ipairs({"hangar","relay","charger"}) do
    for tier=1,4 do
      local name="nullius-"..family.."-"..tier
      local prototype=assert(prototypes.entity[name])
      assert(prototype.radar_range==0,name.." radar coverage")
      rows[#rows+1]={name=name,radar_range=prototype.radar_range}
    end
  end
  local function amount(parts,name)
    for _,part in pairs(parts) do if part.name==name then return part.amount end end
    error("missing recipe part "..name)
  end
  local fill=prototypes.recipe['nullius-diesel-canister']
  local flush=prototypes.recipe['nullius-diesel-canister-flushing']
  local bulk=prototypes.recipe['nullius-boxed-diesel-canister']
  assert(amount(fill.ingredients,'nullius-diesel')==amount(flush.products,'nullius-diesel'))
  assert(amount(bulk.ingredients,'nullius-diesel')==5*amount(flush.products,'nullius-diesel'))
  for _,r in ipairs({fill,flush,bulk}) do assert(not r.allowed_effects.productivity,r.name.." productivity") end
  local s=game.surfaces.nauvis
  s.request_to_generate_chunks({50,50},1);s.force_generate_chunk_requests()
  for i,pair in ipairs({{'nullius-small-tank-2','nullius-small-tank-3',40000},
    {'nullius-medium-tank-3','nullius-medium-tank-4',120000}}) do
    assert(prototypes.entity[pair[1]].next_upgrade.name==pair[2])
    local position={50+i*10,50}
    local old=assert(s.create_entity{name=pair[1],position=position,force='player'})
    assert(old.insert_fluid{name='nullius-water',amount=1234}==1234)
    local upgraded=assert(s.create_entity{name=pair[2],position=position,force='player',fast_replace=true})
    assert(upgraded.get_fluid_count('nullius-water')==1234,'upgrade lost fluid')
    assert(upgraded.prototype.fluid_capacity==pair[3],'tank capacity')
  end
  local surfaces={}
  for _,name in ipairs({"nauvis","vulcanus","fulgora"}) do
    local surface=game.surfaces[name] or game.planets[name].create_surface()
    surfaces[name]={solar_power_multiplier=surface.solar_power_multiplier,
      ticks_per_day=surface.ticks_per_day,dusk=surface.dusk,evening=surface.evening,
      morning=surface.morning,dawn=surface.dawn}
  end
  helpers.write_file("factorio-tests/upstream-progression-audit.json",helpers.table_to_json{
    schema=1,case="upstream-progression-audit",status="pass",assertions=#rows+14,tick=game.tick,
    factorio_version=script.active_mods.base,radar=rows,surfaces=surfaces,failure_count=0},false)
  script.on_nth_tick(1,nil)
end)

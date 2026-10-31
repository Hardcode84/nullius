-- given: shipping prototypes on Factorio 2.1; no supplied materials
-- act: read native roboport radar defaults and planet lighting
-- expect: all twelve logistics entities retain radar coverage
script.on_nth_tick(1,function()
  if game.tick==0 then return end
  local rows={}
  for _,family in ipairs({"hangar","relay","charger"}) do
    for tier=1,4 do
      local name="nullius-"..family.."-"..tier
      local prototype=assert(prototypes.entity[name])
      assert(prototype.radar_range>0,name.." radar coverage")
      rows[#rows+1]={name=name,radar_range=prototype.radar_range}
    end
  end
  local surfaces={}
  for _,name in ipairs({"nauvis","vulcanus","fulgora"}) do
    local surface=game.surfaces[name] or game.planets[name].create_surface()
    surfaces[name]={solar_power_multiplier=surface.solar_power_multiplier,
      ticks_per_day=surface.ticks_per_day,dusk=surface.dusk,evening=surface.evening,
      morning=surface.morning,dawn=surface.dawn}
  end
  helpers.write_file("factorio-tests/upstream-progression-audit.json",helpers.table_to_json{
    schema=1,case="upstream-progression-audit",status="pass",assertions=#rows,tick=game.tick,
    factorio_version=script.active_mods.base,radar=rows,surfaces=surfaces,failure_count=0},false)
  script.on_nth_tick(1,nil)
end)

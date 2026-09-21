-- given: production collectors and solar update code; no fuel or heat consumers
-- place: all tiers and reflected placements in twelve independent layouts
-- connect: native heat ports and neighbour connections only
-- act: hold daylight, remove an east neighbour, then hold night
-- run: three 541-tick measurements, each covering two solar bucket visits
-- expect: native heat plus exact solar heat; no bonus across tiers or gaps
require("__nullius-star__/scripts/solar")
local layouts={
  {name="isolated",points={{0,0,0}}},
  {name="east",points={{0,0,1},{5,0,1}},remove=true},
  {name="north",points={{0,0,1},{0,-4,1}}},
  {name="east gap",points={{0,0,0},{6,0,0}}},
  {name="north gap",points={{0,0,0},{0,-5,0}}},
  {name="diagonal",points={{0,0,0},{5,4,0}}},
  {name="east offset",points={{0,0,0},{5,1,0}}},
  {name="north offset",points={{0,0,0},{1,-4,0}}},
  {name="cross",points={{0,0,4},{5,0,1},{-5,0,1},{0,4,1},{0,-4,1}}},
  {name="square",points={{0,0,2},{5,0,2},{0,4,2},{5,4,2}}},
  {name="mixed east",points={{0,0,0},{5,0,0,true}}},
  {name="mixed north",points={{0,0,0},{0,-4,0,true}}},
}
local capacities={150000,350000,800000}
local watts={150,300,600}
local temperature_steps={7.36,6.07,5.13}
local function check(ok,message)
  storage.assertions=storage.assertions+1
  assert(ok,message)
end
local function heat(row)
  local energy=0
  for _,entry in ipairs(row.entities) do
    energy=energy+(entry.entity.temperature-15)*capacities[entry.tier]
  end
  return energy
end
local function expected_heat(row,day)
  local total=0
  for _,entry in ipairs(row.entities) do
    check(math.abs(entry.entity.neighbour_bonus-entry.bonus)<1e-9,
      row.label.." bonus: "..entry.entity.neighbour_bonus.." expected "..entry.bonus)
    total=total+(1+entry.bonus)*(watts[entry.tier]*541/60+
      (day and 2*temperature_steps[entry.tier]*capacities[entry.tier] or 0))
  end
  return total
end
script.on_init(function()
  storage.assertions=0
  storage.rows={}
  local surface=game.create_surface("solar-neighbours-test",{width=384,height=384,autoplace_controls={}})
  surface.request_to_generate_chunks({0,0},6)
  surface.force_generate_chunk_requests()
  for _,entity in pairs(surface.find_entities()) do entity.destroy() end
  surface.freeze_daytime=true
  surface.daytime=0
  surface.solar_power_multiplier=1
  storage.surface=surface
  for tier=1,3 do for i,layout in ipairs(layouts) do for rotation=0,3 do
    local row={label=layout.name.." tier "..tier.." reflection "..rotation,entities={},remove=layout.remove}
    for _,point in ipairs(layout.points) do
      local x,y=point[1]+0.5,point[2]
      if rotation%2==1 then x=-x end
      if rotation>=2 then y=-y end
      local level=point[4] and (tier%3+1) or tier
      local entity=surface.create_entity{name="nullius-solar-collector-"..level,
        position={x+(i-6)*28,y+((tier-1)*4+rotation-6)*28},direction=rotation*4,force="player"}
      check(entity~=nil,row.label.." placement")
      check(entity.direction==defines.direction.north,row.label.." fixed orientation")
      build_solar_collector(entity,level)
      row.entities[#row.entities+1]={entity=entity,tier=level,bonus=point[3]*0.1}
    end
    storage.rows[#storage.rows+1]=row
  end end end
end)
-- Match the production per-tick scheduler, including its real bucket assignment.
script.on_event(defines.events.on_tick,function(event)
  local tick=event.tick
  if tick==30 or tick==600 or tick==1170 then
    for _,row in ipairs(storage.rows) do
      row.start_heat=heat(row)
      row.expected=expected_heat(row,tick~=1170)
    end
  elseif tick==571 or tick==1141 or tick==1711 then
    for _,row in ipairs(storage.rows) do
      expected_heat(row,tick~=1711)
      local gained=heat(row)-row.start_heat
      check(math.abs(gained-row.expected)<1,row.label.." heat: "..gained.." expected "..row.expected)
      if tick==571 and row.remove then
        local removed=row.entities[2]
        remove_solar_collector(removed.entity,false,removed.tier)
        removed.entity.destroy()
        table.remove(row.entities,2)
        row.entities[1].bonus=0
      end
    end
    if tick==1141 then
      storage.surface.daytime=0.5
    elseif tick==1711 then
      script.on_event(defines.events.on_tick,nil)
      helpers.write_file("factorio-tests/solar-neighbours.json",helpers.table_to_json({
        schema=1,case="solar-neighbours",status="pass",factorio_version=script.active_mods.base,
        tick=tick,assertions=storage.assertions,layouts=#storage.rows,failure_count=0,failures={}
      }),false)
      return
    end
  end
  update_solar()
end)

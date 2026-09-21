-- given: one 10 GJ test fuel per reactor; no heat consumers
-- place: isolated, touching, spaced, diagonal, offset, cross, square, mixed pairs
-- connect: native heat ports and reactor neighbour connections only
-- act: burn fuel; remove the second reactor from each touching pair at tick 90
-- run: measure stored heat over ticks 30-90 and 120-180
-- expect: exact neighbour bonuses and 50 MW per Nullius reactor before bonuses
local layouts={
  {name="isolated",points={{0,0,0}}},
  {name="touching",points={{0,0,1},{5,0,1}},remove=true},
  {name="spaced",points={{0,0,0},{6,0,0}}},
  {name="diagonal",points={{0,0,0},{5,5,0}}},
  {name="offset",points={{0,0,0},{5,1,0}}},
  {name="cross",points={{0,0,4},{5,0,1},{-5,0,1},{0,5,1},{0,-5,1}}},
  {name="square",points={{0,0,2},{5,0,2},{0,5,2},{5,5,2}}},
  {name="mixed",points={{0,0,0},{5,0,0,true}}},
}
local function check(ok,message)
  storage.assertions=storage.assertions+1
  assert(ok,message)
end
local function heat(row)
  local total=0
  for _,entry in ipairs(row.entities) do
    total=total+(entry.entity.temperature-15)*10000000
  end
  return total
end
local function verify(row)
  local power=0
  for _,entry in ipairs(row.entities) do
    check(entry.entity.neighbour_bonus==entry.bonus,
      row.label.." bonus: "..entry.entity.neighbour_bonus.." expected "..entry.bonus)
    power=power+entry.power*(1+entry.bonus)
  end
  return power
end
script.on_nth_tick(1,function()
  script.on_nth_tick(1,nil)
  storage.assertions=0
  storage.rows={}
  local surface=game.create_surface("reactor-neighbours-test",{width=256,height=160,autoplace_controls={}})
  surface.request_to_generate_chunks({0,0},5)
  surface.force_generate_chunk_requests()
  for _,entity in pairs(surface.find_entities()) do entity.destroy() end
  for i,layout in ipairs(layouts) do for rotation=0,3 do
    local row={label=layout.name.." rotation "..rotation,entities={},remove=layout.remove}
    for _,point in ipairs(layout.points) do
      local x,y=point[1],point[2]
      for _=1,rotation do x,y=-y,x end
      local native=point[4]
      local name=native and "factorio-test-base-reactor" or "nullius-reactor"
      local entity=surface.create_entity{name=name,position={x+(i-4)*28,y+(rotation-2)*28},
        direction=rotation*4,force="player"}
      check(entity~=nil,row.label.." placed")
      check(entity.insert{name="factorio-test-reactor-fuel",count=1}==1,row.label.." fuel")
      row.entities[#row.entities+1]={entity=entity,bonus=point[3]*(native and 1 or 0.5),
        power=native and 40000000 or 50000000}
    end
    storage.rows[#storage.rows+1]=row
  end end
end)
script.on_nth_tick(30,function(event)
  if event.tick~=30 and event.tick~=90 and event.tick~=120 and event.tick~=180 then return end
  for _,row in ipairs(storage.rows) do
    local power=verify(row)
    local energy=heat(row)
    if event.tick==30 or event.tick==120 then
      row.start_heat=energy
    else
      check(math.abs(energy-row.start_heat-power)<1,row.label.." heat output: "..(energy-row.start_heat))
      if event.tick==90 and row.remove then
        row.entities[2].entity.destroy()
        table.remove(row.entities,2)
        row.entities[1].bonus=0
      end
    end
  end
  if event.tick==180 then
    script.on_nth_tick(30,nil)
    helpers.write_file("factorio-tests/reactor-neighbours.json",helpers.table_to_json({
      schema=1,case="reactor-neighbours",status="pass",factorio_version=script.active_mods.base,
      tick=game.tick,assertions=storage.assertions,layouts=#storage.rows,failure_count=0,failures={}
    }),false)
  end
end)

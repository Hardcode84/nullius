-- given: 100 blanks (iron plates) and 100 hydrogen per recorder; an explicit
-- electric test grid, or 200 compressed volcanic gas in each pneumatic recorder.
-- place/connect: chemical-plant recorders, hydrogen pipes, and electric substations.
-- act: set per-entity speed and consumption effects once; change one share mid-craft;
-- stop and restart the zero-share recorder only at storm edges.
-- run: three 300-tick windows.
-- expect: continuous proportional work, native speed clamps, preserved progress,
-- and the same effects on both power variants.
local CASE = "experiment-astronomy-effects"
local PREFIX = "factorio-test-astronomy-effects"
local function check(ok, message)
  storage.assertions = storage.assertions + 1
  assert(ok,message)
end
local function near(a,b,message)
  check(math.abs(a-b)<0.0001,message..": "..a.." expected "..b)
end
local function work(entity) return entity.products_finished + entity.crafting_progress end
script.on_init(function()
  storage.assertions=0; storage.rows={}; storage.observations={}
  local surface=game.surfaces.nauvis
  surface.request_to_generate_chunks({0,0},4);surface.force_generate_chunk_requests()
  local tiles={}
  for x=-10,160 do for y=-8,8 do tiles[#tiles+1]={name="grass-1",position={x,y}} end end
  surface.set_tiles(tiles)
  for _,entity in pairs(surface.find_entities_filtered{area={{-10,-8},{160,8}}}) do entity.destroy() end
  local cases={
    {variant="electric",share=1}, {variant="electric",share=0.5},
    {variant="electric",share=0.1}, {variant="electric",share=0.01},
    {variant="electric",share=0}, {variant="default-floor",share=0.01},
    {variant="pneumatic",share=0.5}, {variant="pneumatic",share=0.01},
  }
  for i,spec in ipairs(cases) do
    local x=(i-1)*20
    local machine=assert(surface.create_entity{name=PREFIX.."-"..spec.variant.."-recorder",position={x,0},force="player"})
    game.forces.player.recipes[PREFIX].enabled=true
    machine.set_recipe(PREFIX)
    check(machine.get_recipe() and machine.get_recipe().name==PREFIX,"selected recipe")
    check(machine.insert{name="iron-plate",count=100}==100,"finite blanks")
    local pipe=assert(surface.create_entity{name="pipe",position={x-1,-2},force="player"})
    check(pipe.insert_fluid{name="nullius-hydrogen",amount=100}==100,"finite hydrogen")
    if spec.variant=="pneumatic" then
      check(machine.insert_fluid{name="nullius-compressed-volcanic-gas",amount=200}==200,"finite fuel")
    else
      local grid=assert(surface.create_entity{name="factorio-test-planner-grid",position={x+7,0},force="player"})
      grid.power_production=10000000;grid.electric_buffer_size=10000000
      assert(surface.create_entity{name="substation",position={x+4,4},force="player"})
    end
    machine.local_effect={speed=spec.share-1,consumption=spec.share-1}
    local speed=spec.variant=="default-floor" and 0.2 or math.max(0.0001,spec.share)
    check(not machine.disabled_by_script,"no toggling "..i)
    spec.machine=machine;spec.expected=speed;storage.rows[i]=spec
  end
end)
script.on_nth_tick(30,function()
  if game.tick==0 then return end
  for i,row in ipairs(storage.rows) do
    near(row.machine.crafting_speed,row.expected,"native speed "..i)
    near(row.machine.consumption_bonus,math.max(-0.9999,row.share-1),"native consumption "..i)
  end
  script.on_nth_tick(30,nil)
end)
script.on_nth_tick(300,function()
  if game.tick==0 then return end
  if game.tick==300 then
    for i,row in ipairs(storage.rows) do
      local amount=work(row.machine)
      check(math.abs(amount-5*row.expected)<0.04,"continuous work "..i..": "..amount.." status="..row.machine.status.." energy="..row.machine.energy.." hydrogen="..row.machine.get_fluid_count("nullius-hydrogen"))
      storage.observations[i]={speed=row.machine.crafting_speed,work=amount}
    end
    local changing=storage.rows[2].machine
    storage.previous=work(changing)
    local progress=changing.crafting_progress
    changing.local_effect={speed=-0.75,consumption=-0.75}
    near(changing.crafting_progress,progress,"share change preserves progress")
    local zero=storage.rows[5].machine
    check(work(zero)>0,"speed minus one still leaks progress")
    zero.disabled_by_script=true
    storage.zero_work=work(zero)
  elseif game.tick==600 then
    local changing=storage.rows[2].machine
    check(math.abs(work(changing)-storage.previous-1.25)<0.02,"changed share adds continuous work")
    local zero=storage.rows[5].machine
    near(work(zero),storage.zero_work,"storm stop is exact")
    zero.local_effect={speed=0,consumption=0};zero.disabled_by_script=false
    check(not zero.disabled_by_script,"storm edge enables machine")
  else
    local zero=storage.rows[5].machine
    near(zero.crafting_speed,1,"storm edge restores full speed")
    check(math.abs(work(zero)-storage.zero_work-5)<0.02,"native crafting resumes after storm")
    helpers.write_file("factorio-tests/"..CASE..".json",helpers.table_to_json{
      schema=1,case=CASE,status="pass",tick=game.tick,assertions=storage.assertions,
      failure_count=0,observations=storage.observations},false)
    script.on_nth_tick(300,nil)
  end
end)

-- given: a Vulcanus surface and two forces, with no gas or power supply.
-- place: one vent, then three more through production build events.
-- act: remove three vents; place a released composite vent with 80 gas, a stray
--   drill with gas and an orphan seam with no vent, then rebuild.
-- run: fixed windows for one vent, four vents, and one vent after removal.
-- expect: square-root total work across both forces, both tiers at the same base
-- rate, native rotation, no hidden parts, lossless repeatable conversion, and
-- removal of composite parts that lost their vent.
local CASE="vulcanus-gas-vent-array"
local GAS="nullius-compressed-volcanic-gas"
local function check(ok,message)
  storage.assertions=storage.assertions+1
  assert(ok,message)
end
local function near(a,b,message)
  check(math.abs(a-b)<0.04,message..": "..a.." expected "..b)
end
local function work(entity) return entity.products_finished+entity.crafting_progress end
local function vent(x,tier,force)
  return assert(storage.surface.create_entity{
    name="nullius-lava-intake-"..tier.."-gasvent",position={x,0},
    force=force or game.forces.player,raise_built=true})
end
local function total_work()
  local total=0
  for _,entity in ipairs(storage.vents) do total=total+work(entity) end
  return total
end
script.on_nth_tick(1,function()
  if game.tick~=1 then return end
  script.on_nth_tick(1,nil)
  storage.assertions=0
  local planet=game.planets["nullius-vulcanus"]
  storage.surface=planet.surface or planet.create_surface()
  storage.surface.request_to_generate_chunks({0,0},2)
  storage.surface.force_generate_chunk_requests()
  for _,entity in pairs(storage.surface.find_entities_filtered{area={{-5,-5},{60,5}}}) do entity.destroy() end
  storage.vents={vent(0,1)}
  check(prototypes.recipe["nullius-gas-venting"].maximum_productivity==0,"gas rejects productivity")
  near(storage.vents[1].crafting_speed,1,"one vent speed")
end)
script.on_nth_tick(121,function()
  if game.tick~=121 then return end
  script.on_nth_tick(121,nil)
  near(total_work(),2,"one vent work")
  check(storage.vents[1].get_fluid_count(GAS)>=24,"native gas production")
  storage.before=total_work()
  local other=game.create_force("second-vent-owner")
  for i=2,4 do storage.vents[i]=vent((i-1)*10,i==4 and 2 or 1,other) end
  for _,entity in ipairs(storage.vents) do
    near(entity.crafting_speed,0.5,"surface-wide share includes both owners and tiers")
    check(not entity.disabled_by_script,"continuous production")
  end
end)
script.on_nth_tick(241,function()
  if game.tick~=241 then return end
  script.on_nth_tick(241,nil)
  near(total_work()-storage.before,4,"four vents double total production")
  for i=4,2,-1 do storage.vents[i].destroy();storage.vents[i]=nil end
end)
script.on_nth_tick(243,function()
  if game.tick~=243 then return end
  script.on_nth_tick(243,nil)
  near(storage.vents[1].crafting_speed,1,"removal restores speed")
  storage.before=work(storage.vents[1])
end)
script.on_nth_tick(363,function()
  if game.tick~=363 then return end
  script.on_nth_tick(363,nil)
  near(work(storage.vents[1])-storage.before,2,"restored production")
  check(storage.surface.count_entities_filtered{name={"nullius-gas-vent-drill","nullius-gas-vent-seam"}}==0,
    "new vents have no hidden parts")
  local shell=vent(50,1)
  local resource=assert(storage.surface.create_entity{name="nullius-gas-vent-seam",position=shell.position,amount=1000000})
  local drill=assert(storage.surface.create_entity{name="nullius-gas-vent-drill",position=shell.position,force="player"})
  game.forces.player.mining_drill_productivity_bonus=1
  near(drill.productivity_bonus,1,"legacy mining productivity baseline")
  near(shell.productivity_bonus,0,"direct vent uses speed for the output bonus")
  check(drill.insert_fluid{name=GAS,amount=80}==80,"legacy gas stock")
  local stray_seam=assert(storage.surface.create_entity{name="nullius-gas-vent-seam",position={70,0},amount=1000000})
  local stray=assert(storage.surface.create_entity{name="nullius-gas-vent-drill",position={70,0},force="player"})
  check(stray.insert_fluid{name=GAS,amount=50}==50,"stray gas stock")
  local orphan_seam=assert(storage.surface.create_entity{name="nullius-gas-vent-seam",position={80,0},amount=1000000})
  remote.call("nullius-test-gasvent","rebuild")
  check(not drill.valid and not resource.valid,"legacy components removed")
  check(not stray.valid and not stray_seam.valid and not orphan_seam.valid,"parts without a vent removed")
  check(storage.surface.count_entities_filtered{name={"nullius-gas-vent-drill","nullius-gas-vent-seam"}}==0,
    "no composite parts remain")
  near(shell.get_fluid_count(GAS),80,"legacy gas preserved")
  near(shell.crafting_speed,2/math.sqrt(2),"converted vent keeps mining output bonus")
  remote.call("nullius-test-gasvent","rebuild")
  near(shell.get_fluid_count(GAS),80,"rebuild preserves gas again")
  near(storage.vents[1].crafting_speed,2/math.sqrt(2),"remaining share after rebuild")
  game.forces.player.reset_technology_effects()
  near(shell.crafting_speed,(1+game.forces.player.mining_drill_productivity_bonus)/math.sqrt(2),"technology reset updates output")
  local technology=game.forces.player.technologies["nullius-mining-productivity-1"]
  technology.researched=true
  near(shell.crafting_speed,1.02/math.sqrt(2),"mining research updates output")
  technology.researched=false
  near(shell.crafting_speed,1/math.sqrt(2),"reversing mining research updates output")
  local other=game.forces["second-vent-owner"]
  local other_vent=vent(60,2,other)
  other.technologies["nullius-mining-productivity-1"].researched=true
  near(other_vent.crafting_speed,1.02/math.sqrt(3),"research bonus belongs to the vent owner")
  near(shell.crafting_speed,1/math.sqrt(3),"other force research leaves owner output unchanged")
  other.reset()
  near(other_vent.crafting_speed,1/math.sqrt(3),"force reset restores output")
  helpers.write_file("factorio-tests/"..CASE..".json",helpers.table_to_json{
    schema=1,case=CASE,status="pass",tick=game.tick,failure_count=0,assertions=storage.assertions},false)
end)

-- given: a fresh force and character, an iron chest, and the production lab wreck
-- place: all three entities on an empty surface
-- act: mine the chest, then mine the lab wreck through the native character API
-- run: check each result on the following tick
-- expect: only the lab wreck completes salvage research and opens geology research
local function check(ok,message)
  storage.assertions=storage.assertions+1
  assert(ok,message)
end
script.on_init(function()
  storage.assertions=0
  local force=game.create_force("salvage-test")
  local surface=game.create_surface("salvage-test",{width=64,height=64,autoplace_controls={}})
  surface.request_to_generate_chunks({0,0},1)
  surface.force_generate_chunk_requests()
  for _,entity in pairs(surface.find_entities()) do entity.destroy() end
  storage.force=force
  storage.character=assert(surface.create_entity{name="character",position={0,0},force=force})
  storage.chest=assert(surface.create_entity{name="iron-chest",position={2,0},force=force})
  storage.wreck=assert(surface.create_entity{name="nullius-landing-lab",position={0,4},force=force})
end)
script.on_nth_tick(1,function(event)
  local force=storage.force
  local salvage=force.technologies["nullius-salvage-lab-wreckage"]
  local geology=force.technologies["nullius-geology-1"]
  if event.tick==1 then
    check(not salvage.researched,"salvage starts locked")
    check(not geology.researched,"geology starts locked")
    check(geology.prerequisites[salvage.name]~=nil,"geology requires salvage")
    check(not force.add_research(geology),"geology cannot start before salvage")
    check(storage.character.mine_entity(storage.chest),"mine other entity")
  elseif event.tick==2 then
    check(not salvage.researched,"other entity does not complete salvage")
    check(storage.character.mine_entity(storage.wreck),"mine landing lab")
  elseif event.tick==3 then
    check(salvage.researched,"lab wreck completes salvage")
    check(not geology.researched,"geology still requires research")
    check(storage.character.get_item_count("nullius-lab-1")==1,"salvaged lab")
    check(storage.character.get_item_count("nullius-red-wire")==20,"salvaged wire")
    check(storage.character.get_item_count("nullius-broken-sensor-node")==2,"salvaged sensor nodes")
    check(force.add_research(geology),"geology can start after salvage")
    helpers.write_file("factorio-tests/salvage-research.json",helpers.table_to_json({
      schema=1,case="salvage-research",status="pass",factorio_version=script.active_mods.base,
      tick=game.tick,assertions=storage.assertions,failure_count=0,failures={}
    }),false)
    script.on_nth_tick(1,nil)
  end
end)

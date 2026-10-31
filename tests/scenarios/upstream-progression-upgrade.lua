-- given: the pre-port mod, stored biodiesel, filled canisters, and researched tanks
-- act: save, then load with the shipping mod and native migrations
-- expect: preserved items, fluid, active recipes, heat, and unlocked tank recipes
local resumed=false
script.on_load(function() resumed=true end)
script.on_init(function() storage.prepared=false end)
script.on_nth_tick(30,function()
  if game.tick==0 then return end
  if not storage.prepared then
    local force=game.forces.player
    force.technologies['nullius-plumbing-6'].researched=true
    force.technologies['nullius-biochemistry-6'].researched=true
    storage.rows={}
    for i,name in ipairs({'nauvis','vulcanus','fulgora'}) do
      local s=game.surfaces[name] or game.planets[name].create_surface()
      s.request_to_generate_chunks({0,0},1);s.force_generate_chunk_requests()
      for _,e in pairs(s.find_entities_filtered{area={{-20,-20},{20,20}}}) do e.destroy() end
      s.freeze_daytime=true;s.daytime=0
      local chest=assert(s.create_entity{name='nullius-large-chest-1',position={0,0},force=force})
      for _,item in ipairs({'nullius-biodiesel-canister','nullius-box-biodiesel-canister','nullius-biodiesel-barrel'}) do
        assert(chest.insert{name=item,count=3}==3)
      end
      local tank=assert(s.create_entity{name='nullius-medium-tank-3',position={5,0},force=force})
      assert(tank.insert_fluid{name='nullius-biodiesel',amount=1234}==1234)
      local assembler=assert(s.create_entity{name='nullius-large-assembler-2',position={0,8},force=force})
      assembler.set_recipe('nullius-large-tank-3')
      local solar=assert(s.create_entity{name='nullius-solar-collector-'..i,position={10,10},force=force,raise_built=true})
      solar.temperature=100
      storage.rows[i]={chest=chest,tank=tank,assembler=assembler,solar=solar}
    end
    storage.prepared=true;game.server_save('upstream-progression')
  elseif resumed and game.tick>=600 then
    local force=game.forces.player
    for _,name in ipairs({'nullius-small-tank-3','nullius-medium-tank-4','nullius-boxed-medium-tank-4',
      'nullius-large-tank-3','nullius-legacy-large-tank-3'}) do
      assert(force.recipes[name].enabled,'missing unlock '..name)
    end
    for _,row in ipairs(storage.rows) do
      for _,name in ipairs({'nullius-diesel-canister','nullius-box-diesel-canister','nullius-diesel-barrel'}) do
        assert(row.chest.get_item_count(name)==3,'lost '..name)
      end
      assert(row.tank.get_fluid_count('nullius-diesel')==1234,'lost stored diesel')
      assert(row.assembler.get_recipe().name=='nullius-legacy-large-tank-3','lost active tank recipe')
      assert(row.solar.temperature>100,'solar did not resume heating')
      assert(row.solar.get_fluid_count('nullius-solar-flux')>0,'solar buffer was not rebuilt')
    end
    if not storage.clones then
      storage.clones={}
      for _,row in ipairs(storage.rows) do
        local clone=assert(row.solar.clone{position={-10,10},surface=row.solar.surface,force=force})
        clone.clear_fluid_inside();clone.temperature=15
        storage.clones[#storage.clones+1]=clone
      end
      return
    end
    if game.tick<1200 then return end
    for _,clone in ipairs(storage.clones) do
      assert(clone.get_fluid_count('nullius-solar-flux')>0,'cloned solar was not registered')
      assert(clone.temperature>15,'cloned solar did not heat')
    end
    log('PROGRESSION_UPGRADE_PASS')
    script.on_nth_tick(30,nil)
  end
end)

local function assert_reactor(force)
  assert(force.technologies["nullius-nuclear-reactor"].researched,"lost reactor research from Nuclear Power 1")
  for _,name in ipairs({"nullius-reactor","nullius-portable-reactor","nullius-fusion-cell","nullius-fusion-recycling"}) do
    assert(force.recipes[name].enabled,"researched Nuclear Power 1 lost "..name)
  end
end

-- The uranium-ore checkpoint was removed with asteroid mining; Uranium Processing
-- unlocks the ore route instead. Uranium smelting and tritium enrichment were replaced by
-- conversion and centrifuge enrichment, which the migration researches. Seawater
-- uranium is new research the save has not done.
local function assert_uranium(force)
  for _,name in ipairs({"nullius-fluorine-chemistry","nullius-uranium-enrichment"}) do
    assert(force.technologies[name].researched,"researched Uranium Processing did not receive "..name)
  end
  for _,name in ipairs({"nullius-crushed-uranium-ore","nullius-yellowcake","nullius-fluorite",
    "nullius-hydrogen-fluoride","nullius-hydrogen-fluoride-electrolysis","nullius-uranium-dioxide",
    "nullius-uranium-tetrafluoride","nullius-uf6-cylinder","nullius-natural-uf6","nullius-centrifuge",
    "nullius-low-enriched-uf6","nullius-reactor-grade-uf6","nullius-enriched-uranium-deconversion",
    "nullius-uranium-deconversion"}) do
    assert(force.recipes[name].enabled,"researched Uranium Processing lost "..name)
  end
  for _,name in ipairs({"nullius-uranium","nullius-enriched-uranium"}) do
    assert(not force.recipes[name],"removed recipe "..name.." remains")
  end
  assert(not force.technologies["nullius-seawater-uranium-adsorption"].researched,"seawater uranium researched by upgrade")
  assert(not force.recipes["nullius-yellowcake-precipitation"].enabled,"seawater uranium unlocked by upgrade")
end

-- Traps stopped being nuclear fuel. The migration moves every seeded trap out of
-- the reactor, truck, and stored armor's portable reactor fuel slots onto the
-- ground beside them, losing none.
local function assert_traps()
  local seeded=storage.traps
  assert(seeded.reactor.get_fuel_inventory().get_item_count("nullius-antimatter-trap")==0,"trap left in reactor fuel")
  assert(seeded.truck.get_fuel_inventory().get_item_count("nullius-antimatter-trap")==0,"trap left in truck fuel")
  local grid=seeded.chest.get_inventory(defines.inventory.chest)[1].grid
  for _,item in pairs(grid.equipment) do
    assert(item.burner.inventory.get_item_count("nullius-antimatter-trap")==0,"trap left in equipment fuel")
  end
  local ground=0
  for _,item in pairs(seeded.reactor.surface.find_entities_filtered{name="item-on-ground",area={{50,50},{78,78}}}) do
    if item.stack.name=="nullius-antimatter-trap" then ground=ground+item.stack.count end
  end
  assert(ground==4,"moved traps on the ground: "..ground)
end

remote.add_interface("release-upgrade",{
  seed=function()
    local technologies=game.forces.player.technologies
    technologies["nullius-astronomy"].researched=true
    technologies["nullius-nuclear-power-1"].researched=true
    technologies["nullius-checkpoint-uranium-ore"].researched=true
    technologies["nullius-uranium-processing"].researched=true
    technologies["nullius-antimatter-containment"].researched=true
    technologies["nullius-explosives-1"].researched=true
    local surface=game.surfaces.nauvis
    surface.request_to_generate_chunks({64,64},1)
    surface.force_generate_chunk_requests()
    for _,entity in pairs(surface.find_entities_filtered{area={{56,56},{72,72}}}) do entity.destroy() end
    local tiles={}
    for x=56,72 do for y=56,72 do tiles[#tiles+1]={name="concrete",position={x,y}} end end
    surface.set_tiles(tiles)
    local reactor=assert(surface.create_entity{name="nullius-reactor",position={64,64},force="player"})
    assert(reactor.get_fuel_inventory().insert{name="nullius-antimatter-trap",count=2}==2,"seed traps as reactor fuel")
    local truck=assert(surface.create_entity{name="nullius-truck-2",position={59,59},force="player"})
    assert(truck.get_fuel_inventory().insert{name="nullius-antimatter-trap",count=1}==1,"seed a trap as vehicle fuel")
    local chest=assert(surface.create_entity{name="wooden-chest",position={69,69},force="player"})
    local armor=chest.get_inventory(defines.inventory.chest)[1]
    assert(armor.set_stack{name="nullius-chassis-4",count=1},"seed stored armor")
    local generator=assert(armor.grid.put{name="nullius-portable-reactor"},"seed a portable reactor")
    assert(generator.burner.inventory.insert{name="nullius-antimatter-trap",count=1}==1,"seed a trap as equipment fuel")
    storage.traps={reactor=reactor,truck=truck,chest=chest}
    game.create_force("nuclear-control")
    storage.astronomy_upgrade_seed=true
  end,
  verify=function()
    assert(script.active_mods["nullius-star"]==candidate_version,"candidate was not loaded")
    assert(storage.astronomy_upgrade_seed,"lost source save state")
    local force=game.forces.player
    assert(force.technologies["nullius-astronomy"].researched,"lost Astronomy research")
    for _,name in ipairs({"nullius-radio-dish","nullius-correlator","nullius-blank-recording-module",
      "nullius-boxed-blank-recording-module","nullius-nauvis-interferometric-recording",
      "nullius-correlate-nauvis","nullius-correlate-fulgora-nauvis-vulcanus"}) do
      assert(force.recipes[name].enabled,"researched Astronomy did not unlock "..name)
    end
    for _,planet in ipairs({"fulgora","vulcanus"}) do
      assert(not force.recipes["nullius-"..planet.."-interferometric-recording"].enabled,"planet research bypassed")
    end
    assert_reactor(force)
    assert_uranium(force)
    -- Explosives 1 gained the aluminum powder box recipes after this release.
    for _,name in ipairs({"nullius-box-aluminum-powder","nullius-unbox-aluminum-powder"}) do
      assert(force.recipes[name].enabled,"researched Explosives 1 did not unlock "..name)
    end
    assert_traps()
    force.reset_technology_effects()
    assert_reactor(force)
    assert_uranium(force)
    local control=game.forces["nuclear-control"]
    assert(not control.technologies["nullius-nuclear-reactor"].researched,"migration researched reactors without Nuclear Power 1")
    assert(not control.recipes["nullius-reactor"].enabled,"unresearched force has reactors")
    assert(not control.recipes["nullius-yellowcake"].enabled,"unresearched force has yellowcake")
    assert(not control.technologies["nullius-uranium-enrichment"].researched,"migration researched enrichment without Uranium Processing")
    helpers.write_file("upgrade-result.json",helpers.table_to_json{status="pass",astronomy_research=true,
      recordings=true,planet_gates=true,reactor_split=true,traps_moved=true},false)
  end,
})

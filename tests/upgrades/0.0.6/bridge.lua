local function assert_reactor(force)
  assert(force.technologies["nullius-nuclear-reactor"].researched,"lost reactor research from Nuclear Power 1")
  for _,name in ipairs({"nullius-reactor","nullius-portable-reactor","nullius-fusion-cell","nullius-fusion-recycling"}) do
    assert(force.recipes[name].enabled,"researched Nuclear Power 1 lost "..name)
  end
end

remote.add_interface("release-upgrade",{
  seed=function()
    local technologies=game.forces.player.technologies
    technologies["nullius-astronomy"].researched=true
    technologies["nullius-nuclear-power-1"].researched=true
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
    force.reset_technology_effects()
    assert_reactor(force)
    local control=game.forces["nuclear-control"]
    assert(not control.technologies["nullius-nuclear-reactor"].researched,"migration researched reactors without Nuclear Power 1")
    assert(not control.recipes["nullius-reactor"].enabled,"unresearched force has reactors")
    helpers.write_file("upgrade-result.json",helpers.table_to_json{status="pass",astronomy_research=true,
      recordings=true,planet_gates=true,reactor_split=true},false)
  end,
})

remote.add_interface("release-upgrade",{
  seed=function()
    game.forces.player.technologies["nullius-astronomy"].researched=true
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
    helpers.write_file("upgrade-result.json",helpers.table_to_json{status="pass",astronomy_research=true,
      recordings=true,planet_gates=true},false)
  end,
})

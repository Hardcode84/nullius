local modern = require("__unlock-test__/factorio-version").is_2_1

script.on_init(function()
  local assertions = 0
  local function expect(actual, expected, label)
    assertions = assertions + 1
    assert(actual == expected, label .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
  end

  -- Given: independent forces with no research, including an untouched control.
  local control = game.create_force("untouched")
  local cases = {
    {name = "nullius-robotics-1", network = true, requests = false, recipes = 5},
    {name = "nullius-construction-robot-1", network = false, requests = false, recipes = 1},
    {name = "nullius-logistic-robot-1", network = false, requests = true, recipes = 2},
    {name = "nullius-primitive-robotics", network = true, requests = true, recipes = 5},
  }
  for _, case in ipairs(cases) do
    local force = game.create_force(case.name)
    local technology = force.technologies[case.name]
    expect(force.character_logistic_requests, false, case.name .. " initial requests")
    if modern then expect(force.unlock_logistic_network, false, case.name .. " initial network") end

    -- Act: complete the actual production effect table on this force only.
    technology.researched = true
    expect(force.character_logistic_requests, case.requests, case.name .. " requests")
    if modern then
      expect(force.unlock_logistic_network, case.network, case.name .. " network")
      expect(control.unlock_logistic_network, false, "other force network")
    end
    expect(control.character_logistic_requests, false, "other force requests")
    local recipes, network_effects = 0, 0
    for _, effect in pairs(technology.prototype.effects) do
      if effect.type == "unlock-recipe" then
        recipes = recipes + 1
        expect(force.recipes[effect.recipe].enabled, true, effect.recipe)
      elseif effect.type == "unlock-logistic-network" then
        network_effects = network_effects + 1
      end
    end
    expect(recipes, case.recipes, case.name .. " recipe count")
    expect(network_effects, modern and case.network and 1 or 0, case.name .. " network effect count")

    -- Recompute from researched prototypes, as after a mod update.
    force.reset_technology_effects()
    expect(force.character_logistic_requests, case.requests, case.name .. " reset requests")
    if modern then expect(force.unlock_logistic_network, case.network, case.name .. " reset network") end
  end
  helpers.write_file("logistic-unlock.json", helpers.table_to_json{
    modern = modern, technologies = #cases, assertions = assertions,
  }, false)
end)

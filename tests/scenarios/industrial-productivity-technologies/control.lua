local CASE = "industrial-productivity-technologies"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local EXPECTED_PREREQUISITES = {
  ["nullius-crushing-productivity-1"] = "nullius-mineral-processing-1",
  ["nullius-smelting-productivity-1"] = "nullius-metallurgy-1",
  ["nullius-casting-productivity-1"] = "nullius-metalworking-1",
}
local CASES = {
  {
    technology = "nullius-crushing-productivity-1",
    recipe = "nullius-crushed-limestone",
    unrelated = "nullius-aluminum-ingot",
  },
  {
    technology = "nullius-smelting-productivity-1",
    recipe = "nullius-aluminum-ingot",
    unrelated = "nullius-iron-plate",
  },
  {
    technology = "nullius-casting-productivity-1",
    recipe = "nullius-iron-plate",
    unrelated = "nullius-crushed-limestone",
  },
}

local assertions = 0
local failures = {}
local observations = {}

local function check(condition, message)
  assertions = assertions + 1
  if not condition then failures[#failures + 1] = message end
end

local function finish()
  local result = {
    schema = 1,
    case = CASE,
    status = (#failures == 0) and "pass" or "fail",
    factorio_version = script.active_mods.base,
    tick = game.tick,
    assertions = assertions,
    failure_count = #failures,
    failures = failures,
    observations = observations,
  }
  helpers.write_file(RESULT, helpers.table_to_json(result), false)
  if #failures > 0 then error(helpers.table_to_json(result)) end
end

local function check_prerequisites(technology, branch_prerequisite)
  check(technology.prerequisites["nullius-efficient-metallurgic-science"] ~= nil,
    technology.name .. " is missing efficient metallurgic science prerequisite")
  check(technology.prerequisites[branch_prerequisite] ~= nil,
    technology.name .. " is missing " .. branch_prerequisite .. " prerequisite")

  local count = 0
  for _ in pairs(technology.prerequisites) do count = count + 1 end
  check(count == 2,
    technology.name .. " expected 2 prerequisites, found " .. count)
end

script.on_nth_tick(1, function()
  script.on_nth_tick(1, nil)
  local force = game.forces.player

  for _, test in ipairs(CASES) do
    local technology = force.technologies[test.technology]
    check(technology ~= nil, "missing technology " .. test.technology)
    if technology then
      check(technology.level == 1,
        test.technology .. " expected initial level 1")
      check(technology.research_unit_count == 100,
        test.technology .. " expected initial cost 100, found " ..
        technology.research_unit_count)
      check(technology.research_unit_energy == 30 * 60,
        test.technology .. " expected research time 1800 ticks, found " ..
        technology.research_unit_energy)
      check(#technology.research_unit_ingredients == 1,
        test.technology .. " expected exactly one science ingredient")
      local ingredient = technology.research_unit_ingredients[1]
      check(ingredient.name == "nullius-metallurgic-pack" and
          ingredient.amount == 1,
        test.technology .. " has an unexpected science ingredient")
      check_prerequisites(technology,
        EXPECTED_PREREQUISITES[test.technology])

      local unrelated_bonus_before =
        force.recipes[test.unrelated].productivity_bonus
      technology.enabled = true
      technology.researched = true

      local bonus = force.recipes[test.recipe].productivity_bonus
      local unrelated_bonus = force.recipes[test.unrelated].productivity_bonus
      observations[test.technology] = {
        recipe = test.recipe,
        productivity_bonus = bonus,
        unrelated_recipe = test.unrelated,
        unrelated_productivity_bonus_before = unrelated_bonus_before,
        unrelated_productivity_bonus = unrelated_bonus,
        next_level = technology.level,
        next_level_cost = technology.research_unit_count,
      }
      check(math.abs(bonus - 0.01) < 0.000001,
        test.technology .. " expected recipe productivity 0.01, found " ..
        bonus)
      check(unrelated_bonus == unrelated_bonus_before,
        test.technology .. " changed unrelated recipe productivity")
      check(technology.level == 2,
        test.technology .. " expected next level 2, found " ..
        technology.level)
      check(technology.research_unit_count == 400,
        test.technology .. " expected next cost 400, found " ..
        technology.research_unit_count)
      check(not technology.researched,
        test.technology .. " became permanently researched")
    end
  end

  finish()
end)

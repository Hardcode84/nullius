local CASE = "experiment-infinite-technology"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local TECHNOLOGY = "factorio-test-superlinear-cost-1"
local TARGET_RECIPE = "factorio-test-productivity-allowed"
local UNRELATED_RECIPE = "factorio-test-productivity-rejected"
local EXPECTED_COUNTS = {10, 40, 90, 160}
local EXPECTED_PRODUCTIVITY = {0, 0.01, 0.02, 0.03}

local assertions = 0
local failures = {}
local observations = {levels = {}}

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

local function advance()
  local force = game.forces.player
  local technology = force.technologies[TECHNOLOGY]
  local index = #observations.levels + 1
  observations.levels[index] = {
    level = technology.level,
    research_unit_count = technology.research_unit_count,
    target_productivity = force.recipes[TARGET_RECIPE].productivity_bonus,
    unrelated_productivity = force.recipes[UNRELATED_RECIPE].productivity_bonus,
  }
  check(technology.level == index,
    "technology level expected " .. index .. ", found " .. technology.level)
  check(technology.research_unit_count == EXPECTED_COUNTS[index],
    "level " .. index .. " cost expected " .. EXPECTED_COUNTS[index] ..
    ", found " .. technology.research_unit_count)
  check(math.abs(force.recipes[TARGET_RECIPE].productivity_bonus -
      EXPECTED_PRODUCTIVITY[index]) < 0.000001,
    "level " .. index .. " productivity expected " ..
    EXPECTED_PRODUCTIVITY[index] .. ", found " ..
    force.recipes[TARGET_RECIPE].productivity_bonus)
  check(force.recipes[UNRELATED_RECIPE].productivity_bonus == 0,
    "level " .. index .. " changed unrelated recipe productivity")

  if index == #EXPECTED_COUNTS then
    check(not technology.researched,
      "infinite technology became permanently researched")
    finish()
    return
  end

  check(force.add_research(technology),
    "Factorio refused to research infinite technology level " .. index)
  check(force.current_research == technology,
    "infinite technology is not current research at level " .. index)
  force.research_progress = 1
end

script.on_event(defines.events.on_research_finished, function(event)
  if event.research.name ~= TECHNOLOGY then return end
  script.on_nth_tick(game.tick + 1, function()
    script.on_nth_tick(game.tick, nil)
    advance()
  end)
end)

script.on_nth_tick(1, function()
  script.on_nth_tick(1, nil)
  local technology = game.forces.player.technologies[TECHNOLOGY]
  check(technology ~= nil, "missing infinite technology experiment prototype")
  if not technology then finish() return end
  technology.enabled = true
  technology.researched = false
  advance()
end)

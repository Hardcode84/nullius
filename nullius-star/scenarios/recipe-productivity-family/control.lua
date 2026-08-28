local CASE = "recipe-productivity-family"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local TECHNOLOGY = "factorio-test-recipe-productivity-family"
local INCLUDED = {
  "factorio-test-family-a-primary",
  "factorio-test-family-b-additional",
  "factorio-test-family-c-both",
}
local EXCLUDED = {
  "factorio-test-family-d-zero-cap",
  "factorio-test-family-e-unrelated",
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

script.on_nth_tick(1, function()
  script.on_nth_tick(1, nil)
  local force = game.forces.player
  local technology = force.technologies[TECHNOLOGY]
  check(technology ~= nil, "missing generated recipe-family technology fixture")
  if not technology then finish() return end

  technology.enabled = true
  technology.researched = true

  for _, recipe_name in ipairs(INCLUDED) do
    local bonus = force.recipes[recipe_name].productivity_bonus
    observations[recipe_name] = bonus
    check(math.abs(bonus - 0.01) < 0.000001,
      recipe_name .. " expected productivity 0.01, found " .. bonus)
  end
  for _, recipe_name in ipairs(EXCLUDED) do
    local bonus = force.recipes[recipe_name].productivity_bonus
    observations[recipe_name] = bonus
    check(bonus == 0,
      recipe_name .. " unexpectedly received productivity " .. bonus)
  end

  finish()
end)

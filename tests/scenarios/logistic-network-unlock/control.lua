-- given: three fresh forces with no research.
-- act: research Robotics 1, Primitive Robotics, and every technology, as a
-- sandbox game with all research does; then reset technology effects.
-- expect: each force can connect machines to its logistic network only after
-- that research, and keeps the connection after the reset.
local CASE = "logistic-network-unlock"

local assertions, failures = 0, {}
local function check(ok, message)
  assertions = assertions + 1
  if not ok then failures[#failures + 1] = message end
end

local function finish(tick)
  local result = {schema = 1, case = CASE, status = #failures == 0 and "pass" or "fail",
    tick = tick, assertions = assertions, failure_count = #failures, failures = failures}
  helpers.write_file("factorio-tests/" .. CASE .. ".json", helpers.table_to_json(result), false)
  if #failures > 0 then error(helpers.table_to_json(result)) end
end

local function research(force, technology)
  if technology then
    force.technologies[technology].researched = true
  else
    force.research_all_technologies()
  end
end

script.on_nth_tick(1, function(event)
  if event.tick == 0 then return end
  script.on_nth_tick(1, nil)
  for _, case in ipairs({
      {force = "robotics", technology = "nullius-robotics-1"},
      {force = "primitive", technology = "nullius-primitive-robotics"},
      {force = "sandbox"}}) do
    local force = game.create_force("logistic-unlock-" .. case.force)
    check(not force.unlock_logistic_network, case.force .. " connects before research")
    research(force, case.technology)
    check(force.unlock_logistic_network, case.force .. " cannot connect machines after research")
    force.reset_technology_effects()
    check(force.unlock_logistic_network, case.force .. " lost the connection on effect reset")
  end
  finish(event.tick)
end)

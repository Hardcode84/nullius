local CASE = "nauvis-titanium-checkpoint"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local CHECKPOINT = "nullius-checkpoint-titanium-ingot"
local PREREQUISITE = "nullius-toolmaking-5"
local INGOT = "nullius-titanium-ingot"

local assertions = 0
local failures = {}
local observations = {}

local function check(condition, message)
  assertions = assertions + 1
  if not condition then failures[#failures + 1] = message end
end

local function close(actual, expected)
  return math.abs(actual - expected) < 0.000001
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

local function research_closure(technology, visited)
  if visited[technology.name] then return end
  visited[technology.name] = true
  for _, prerequisite in pairs(technology.prerequisites) do
    research_closure(prerequisite, visited)
  end
  technology.researched = true
end

local function check_complete()
  script.on_nth_tick(19, nil)
  local force = game.forces.player
  local technology = force.technologies[CHECKPOINT]
  observations.complete = {
    produced = force.get_item_production_statistics("nauvis")
      .get_input_count(INGOT),
    researched = technology.researched,
    progress = technology.saved_progress,
  }
  check(observations.complete.produced == 10,
    "checkpoint fixture did not record exactly 10 titanium ingots")
  check(technology.researched,
    "checkpoint did not complete after 10 titanium ingots")
  finish()
end

local function check_incomplete()
  script.on_nth_tick(6, nil)
  local force = game.forces.player
  local technology = force.technologies[CHECKPOINT]
  observations.incomplete = {
    produced = force.get_item_production_statistics("nauvis")
      .get_input_count(INGOT),
    researched = technology.researched,
    progress = technology.saved_progress,
  }
  check(observations.incomplete.produced == 9,
    "checkpoint fixture did not record exactly 9 titanium ingots")
  check(not technology.researched,
    "checkpoint completed before 10 titanium ingots")
  check(close(technology.saved_progress or 0, 0.9),
    "checkpoint progress is not 90% after 9 titanium ingots")

  force.get_item_production_statistics("nauvis").on_flow(INGOT, 1)
  script.on_nth_tick(19, check_complete)
end

local function setup()
  script.on_nth_tick(1, nil)
  local force = game.forces.player
  local technology = force.technologies[CHECKPOINT]
  local prerequisite = force.technologies[PREREQUISITE]
  check(technology ~= nil, "missing titanium-ingot checkpoint technology")
  check(prerequisite ~= nil, "missing titanium-ingot checkpoint prerequisite")
  if not technology or not prerequisite then finish() return end

  for name, candidate in pairs(force.technologies) do
    if string.sub(name, 1, 19) == "nullius-checkpoint-" then
      candidate.researched = (name ~= CHECKPOINT)
    end
  end
  local visited = {}
  for _, dependency in pairs(prerequisite.prerequisites) do
    research_closure(dependency, visited)
  end
  prerequisite.researched = false
  technology.researched = false
  check(force.add_research(PREREQUISITE),
    "failed to queue titanium checkpoint prerequisite")
  force.research_progress = 1

  force.get_item_production_statistics("nauvis").on_flow(INGOT, 9)
  script.on_nth_tick(6, check_incomplete)
end

script.on_nth_tick(1, setup)

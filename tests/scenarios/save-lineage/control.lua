local CASE = "save-lineage"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local lineage = require("__nullius-star__/scripts/save_lineage")

local assertions = 0
local failures = {}

local function check(condition, message)
  assertions = assertions + 1
  if not condition then failures[#failures + 1] = message end
end

local function accepted(event)
  return pcall(lineage.validate, event)
end

local function run()
  script.on_nth_tick(1, nil)

  check(accepted(nil), "fresh configuration was rejected")
  check(accepted({mod_changes = {}}), "empty configuration change was rejected")
  check(accepted({mod_changes = {
    ["nullius-star"] = {old_version = "0.0.1", new_version = "0.0.2"},
  }}), "Nullius* upgrade was rejected")

  local ok, message = pcall(lineage.validate, {mod_changes = {
    nullius = {old_version = "2.0.9", new_version = nil},
    ["nullius-star"] = {old_version = nil, new_version = "0.0.1"},
  }})
  check(not ok, "upstream Nullius save was accepted")
  check(type(message) == "string" and
      string.find(message, "cannot load a save created with upstream Nullius", 1, true),
    "upstream rejection did not explain the save-lineage boundary")

  local result = {
    schema = 1,
    case = CASE,
    status = (#failures == 0) and "pass" or "fail",
    factorio_version = script.active_mods.base,
    tick = game.tick,
    assertions = assertions,
    failure_count = #failures,
    failures = failures,
  }
  helpers.write_file(RESULT, helpers.table_to_json(result), false)
  if #failures > 0 then error(helpers.table_to_json(result)) end
end

script.on_nth_tick(1, run)

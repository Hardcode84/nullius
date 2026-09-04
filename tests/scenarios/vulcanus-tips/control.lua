local CASE = "vulcanus-tips"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local contract = require("__nullius-star__/shared/vulcanus-tips")

local assertions = 0
local failures = {}

local function check(condition, message)
  assertions = assertions + 1
  if not condition then failures[#failures + 1] = message end
end

local function check_arrival_trigger(trigger, tip_name)
  check(trigger.type == "change-surface",
    tip_name .. " trigger is not change-surface")
  check(trigger.surface == "nullius-vulcanus",
    tip_name .. " trigger targets the wrong surface")
  check(trigger.count == 1,
    tip_name .. " trigger does not fire on first arrival")
end

local function run()
  script.on_nth_tick(1, nil)

  local category_history = prototypes.get_history(
    "tips-and-tricks-item-category", contract.category.name)
  check(category_history.created == "nullius-star",
    "Vulcanus tip category was not created by nullius-star")
  check(#contract.tips == 5, "Vulcanus tip chain does not contain five tips")
  check(prototypes.technology["nullius-probe-vulcanus"] ~= nil,
    "Vulcanus probe technology is missing")
  check(game.planets["nullius-vulcanus"] ~= nil,
    "Vulcanus space location is missing")

  for index, tip in ipairs(contract.tips) do
    local history = prototypes.get_history("tips-and-tricks-item", tip.name)
    check(history.created == "nullius-star",
      tip.name .. " was not created by nullius-star")

    if index == 1 then
      check(tip.is_title == true, "Vulcanus briefing is not the category title")
      check(tip.trigger.type == "research",
        "Vulcanus briefing trigger is not research")
      check(tip.trigger.technology == "nullius-probe-vulcanus",
        "Vulcanus briefing targets the wrong technology")
      check_arrival_trigger(tip.skip_trigger, tip.name .. " skip")
    else
      check_arrival_trigger(tip.trigger, tip.name)
      if index == 2 then
        check(tip.dependencies == nil,
          tip.name .. " is not the root of the arrival chain")
      else
        check(tip.dependencies ~= nil and #tip.dependencies == 1,
          tip.name .. " does not have exactly one dependency")
        check(tip.dependencies ~= nil and
            tip.dependencies[1] == contract.tips[index - 1].name,
          tip.name .. " does not follow the preceding tip")
      end
    end
  end

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

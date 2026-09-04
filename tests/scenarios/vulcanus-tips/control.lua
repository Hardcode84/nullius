local CASE = "vulcanus-tips"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local contract = require("__nullius-star__/shared/vulcanus-tips")

local assertions = 0
local failures = {}

local function check(condition, message)
  assertions = assertions + 1
  if not condition then failures[#failures + 1] = message end
end

local function run()
  script.on_nth_tick(1, nil)

  local category_history = prototypes.get_history(
    "tips-and-tricks-item-category", contract.category.name)
  check(category_history.created == "nullius-star",
    "Vulcanus tip category was not created by nullius-star")
  check(#contract.tips == 5, "Vulcanus tip chain does not contain five tips")
  check(prototypes.technology["nullius-pneumatic-technology"] ~= nil,
    "Pneumatic technology is missing")
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
      check(tip.trigger.technology == "nullius-pneumatic-technology",
        "Vulcanus briefing targets the wrong technology")
      check(tip.skip_trigger == nil,
        "Vulcanus briefing can be skipped before the tip chain starts")
      check(tip.dependencies == nil,
        "Vulcanus briefing is not the root of the tip chain")
    else
      check(tip.trigger.type == "dependencies-met",
        tip.name .. " does not activate when its dependency is read")
      check(tip.dependencies ~= nil and #tip.dependencies == 1,
        tip.name .. " does not have exactly one dependency")
      check(tip.dependencies ~= nil and
          tip.dependencies[1] == contract.tips[index - 1].name,
        tip.name .. " does not follow the preceding tip")
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

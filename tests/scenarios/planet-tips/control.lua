-- given: the shipped planet tip contracts.
-- expect: each planet chain is a nullius-star category whose title tip triggers on the
-- planet's pre-transfer research and whose remaining tips each follow the preceding tip;
-- every icon tag names an existing prototype.
local CASE = "planet-tips"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local PLANETS = {
  {planet = "nullius-vulcanus", technology = "nullius-pneumatic-technology", count = 5,
    contract = require("__nullius-star__/shared/vulcanus-tips")},
  {planet = "nullius-fulgora", technology = "nullius-primitive-filtration", count = 6,
    contract = require("__nullius-star__/shared/fulgora-tips")},
}
local TAGS = {item = "item", fluid = "fluid", tile = "tile", planet = "space_location"}

local assertions = 0
local failures = {}

local function check(condition, message)
  assertions = assertions + 1
  if not condition then failures[#failures + 1] = message end
end

local function check_planet(row)
  local contract = row.contract
  local category_history = prototypes.get_history(
    "tips-and-tricks-item-category", contract.category.name)
  check(category_history.created == "nullius-star",
    contract.category.name .. " category was not created by nullius-star")
  check(#contract.tips == row.count,
    contract.category.name .. " does not contain " .. row.count .. " tips")
  check(prototypes.technology[row.technology] ~= nil, row.technology .. " is missing")
  check(game.planets[row.planet] ~= nil, row.planet .. " space location is missing")

  for index, tip in ipairs(contract.tips) do
    local history = prototypes.get_history("tips-and-tricks-item", tip.name)
    check(history.created == "nullius-star", tip.name .. " was not created by nullius-star")
    local kind, name = tip.tag:match("^%[(%a+)=([%w%-]+)%]$")
    local table_name = TAGS[kind]
    check(table_name ~= nil and prototypes[table_name][name] ~= nil,
      tip.name .. " has an unknown tag " .. tip.tag)

    if index == 1 then
      check(tip.is_title == true, tip.name .. " is not the category title")
      check(tip.tag == "[planet=" .. row.planet .. "]", tip.name .. " does not show its planet")
      check(tip.trigger.type == "research", tip.name .. " trigger is not research")
      check(tip.trigger.technology == row.technology,
        tip.name .. " targets the wrong technology")
      check(tip.skip_trigger == nil, tip.name .. " can be skipped before the tip chain starts")
      check(tip.dependencies == nil, tip.name .. " is not the root of the tip chain")
    else
      check(tip.trigger.type == "dependencies-met",
        tip.name .. " does not activate when its dependency is read")
      check(tip.dependencies ~= nil and #tip.dependencies == 1,
        tip.name .. " does not have exactly one dependency")
      check(tip.dependencies ~= nil and tip.dependencies[1] == contract.tips[index - 1].name,
        tip.name .. " does not follow the preceding tip")
      check(tip.order > contract.tips[index - 1].order, tip.name .. " is ordered before its dependency")
    end
  end
end

local function run()
  script.on_nth_tick(1, nil)
  for _, row in ipairs(PLANETS) do check_planet(row) end
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

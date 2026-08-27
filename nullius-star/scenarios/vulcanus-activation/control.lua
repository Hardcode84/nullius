local CASE = "vulcanus-activation"
local RESULT = "factorio-tests/" .. CASE .. ".json"

local expected_wreck = {
  ["nullius-seawater-intake-1"] = 2,
  ["nullius-hydro-plant-1"] = 4,
  ["nullius-small-furnace-1"] = 4,
  pipe = 50,
  ["nullius-heat-pipe-1"] = 30,
  ["pipe-to-ground"] = 10,
  ["nullius-extractor-1"] = 2,
  ["nullius-air-filter-1"] = 2,
  ["nullius-distillery-1"] = 2,
  ["nullius-chemical-plant-1"] = 2,
  ["nullius-foundry-1"] = 4,
  ["nullius-small-assembler-1"] = 4,
  inserter = 12,
  ["iron-chest"] = 4,
  ["nullius-lab-1"] = 1,
  ["transport-belt"] = 50,
  splitter = 4,
  ["cliff-explosives"] = 30,
}

local expected_equipment = {
  ["nullius-charger-1"] = 1,
  ["nullius-hangar-1"] = 1,
  ["nullius-solar-panel-1"] = 2,
  ["nullius-battery-1"] = 4,
}

local assertions = 0
local failures = {}
local observations = {}

local function check(condition, message)
  assertions = assertions + 1
  if not condition then failures[#failures + 1] = message end
end

local function item_counts(inventory)
  local result = {}
  if not inventory then return result end
  for _, stack in pairs(inventory.get_contents()) do
    result[stack.name] = (result[stack.name] or 0) + stack.count
  end
  return result
end

local function check_exact_counts(actual, expected, label)
  for name, count in pairs(expected) do
    check(actual[name] == count,
      label .. " expected " .. count .. " " .. name ..
      ", found " .. tostring(actual[name] or 0))
  end
  for name, count in pairs(actual) do
    check(expected[name] == count,
      label .. " contained unexpected " .. count .. " " .. name)
  end
end

local function equipment_counts(grid)
  local result = {}
  if not grid then return result end
  for _, equipment in pairs(grid.equipment) do
    result[equipment.name] = (result[equipment.name] or 0) + 1
  end
  return result
end

local function research_prerequisites(technology, visited)
  if visited[technology.name] then return end
  visited[technology.name] = true
  for _, prerequisite in pairs(technology.prerequisites) do
    research_prerequisites(prerequisite, visited)
    prerequisite.researched = true
  end
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

local function validate()
  script.on_nth_tick(2, nil)

  local force = game.forces.player
  local planet = game.planets["nullius-vulcanus"]
  check(planet ~= nil, "missing nullius-vulcanus planet")
  if not planet then finish() return end

  local surface = planet.surface
  check(surface ~= nil, "probe event did not create the Vulcanus surface")
  if not surface then finish() return end
  check(surface.planet == planet, "Vulcanus surface is not attached to its planet")
  check(force.is_space_location_unlocked("nullius-vulcanus"),
    "Vulcanus space location was not unlocked")

  local wrecks = surface.find_entities_filtered{
    name = "nullius-landing-main",
    force = force,
  }
  check(#wrecks == 1, "expected one probe wreck, found " .. #wrecks)
  if #wrecks == 1 then
    check_exact_counts(
      item_counts(wrecks[1].get_inventory(defines.inventory.chest)),
      expected_wreck,
      "wreck inventory")
  end

  local androids = surface.find_entities_filtered{
    name = "character",
    force = force,
  }
  check(#androids == 1, "expected one Vulcanus android, found " .. #androids)
  if #androids == 1 then
    local android = androids[1]
    local armor_inventory = android.get_inventory(defines.inventory.character_armor)
    check(armor_inventory ~= nil, "Vulcanus android has no armor inventory")
    local armor = armor_inventory and armor_inventory.find_item_stack(
      "nullius-chassis-1")
    check(armor ~= nil, "Vulcanus android is missing nullius-chassis-1")
    check_exact_counts(equipment_counts(armor and armor.grid),
      expected_equipment, "android equipment")

    local main_inventory = android.get_inventory(defines.inventory.character_main)
    check_exact_counts(item_counts(main_inventory),
      {["nullius-construction-bot-1"] = 6}, "android inventory")

  end

  local pneumatic = force.technologies["nullius-pneumatic-technology"]
  local probe = force.technologies["nullius-probe-vulcanus"]
  check(pneumatic and pneumatic.researched,
    "nullius-pneumatic-technology is not researched")
  check(probe and probe.researched,
    "nullius-probe-vulcanus is not completed")
  finish()
end

local function activate()
  script.on_nth_tick(1, nil)

  local force = game.forces.player
  local pneumatic = force.technologies["nullius-pneumatic-technology"]
  local probe = force.technologies["nullius-probe-vulcanus"]
  check(pneumatic ~= nil, "missing nullius-pneumatic-technology")
  check(probe ~= nil, "missing nullius-probe-vulcanus")
  if not pneumatic or not probe then finish() return end

  local prerequisites = {}
  research_prerequisites(probe, prerequisites)
  observations.probe_prerequisite_count = table_size(prerequisites) - 1
  pneumatic.researched = true
  probe.researched = false
  check(force.add_research(probe),
    "Factorio refused to start nullius-probe-vulcanus research")
  check(force.current_research == probe,
    "nullius-probe-vulcanus is not the active research")
  if force.current_research ~= probe then finish() return end
  force.research_progress = 1
  script.on_nth_tick(2, validate)
end

script.on_nth_tick(1, activate)

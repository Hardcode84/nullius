local CASE = "renewable-placement"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local AMBIENT_TEMPERATURE = "nullius-ambient-temperature"

local assertions = 0
local failures = {}

local function check(condition, message)
  assertions = assertions + 1
  if not condition then failures[#failures + 1] = message end
end

local function finish(observations)
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

local function prepare(surface, tile)
  surface.request_to_generate_chunks({100, 100}, 1)
  surface.force_generate_chunk_requests()
  local tiles = {}
  for x = 96, 104 do
    for y = 96, 104 do
      tiles[#tiles + 1] = {name = tile, position = {x, y}}
    end
  end
  surface.set_tiles(tiles, true, false, false, false)
  for _, entity in pairs(surface.find_entities_filtered{
      area = {{96, 96}, {105, 105}}}) do
    if entity.valid and entity.type ~= "character" then entity.destroy() end
  end
end

local function check_condition(name)
  local prototype = prototypes.entity[name]
  check(prototype ~= nil, "missing entity prototype " .. name)
  if not prototype then return end
  local conditions = prototype.surface_conditions or {}
  check(#conditions == 1, name .. " does not have exactly one surface condition")
  local condition = conditions[1]
  if not condition then return end
  check(condition.property == AMBIENT_TEMPERATURE,
    name .. " is not restricted by ambient temperature")
  check(condition.max == 50,
    name .. " does not have the exact cool-surface boundary")
end

script.on_nth_tick(1, function()
  script.on_nth_tick(1, nil)
  local force = game.forces.player
  local nauvis = game.surfaces.nauvis
  local planet = game.planets["nullius-vulcanus"]
  check(nauvis ~= nil, "missing Nauvis surface")
  check(planet ~= nil, "missing Nullius Vulcanus planet")
  if not nauvis or not planet then finish({}) return end
  local vulcanus = planet.surface or planet.create_surface()
  check(vulcanus ~= nil, "failed to create Nullius Vulcanus surface")
  if not vulcanus then finish({}) return end

  prepare(nauvis, "lab-dark-1")
  prepare(vulcanus, "volcanic-soil-dark")

  local checked = {}
  for tier = 1, 4 do
    local name = "nullius-solar-panel-" .. tier
    checked[#checked + 1] = name
    check_condition(name)
    check(prototypes.recipe[name] ~= nil, "missing recipe " .. name)
    if prototypes.recipe[name] then
      check(prototypes.recipe[name].surface_conditions == nil,
        name .. " recipe is surface-restricted")
    end
    check(nauvis.can_place_entity{name = name, position = {100, 100}, force = force},
      name .. " cannot be placed on Nauvis")
    check(not vulcanus.can_place_entity{
        name = name, position = {100, 100}, force = force},
      name .. " can be placed on Vulcanus")
  end

  for tier = 1, 3 do
    local item_name = "nullius-wind-turbine-" .. tier
    local build_name = "nullius-wind-build-" .. tier
    local base_name = "nullius-wind-base-" .. tier
    checked[#checked + 1] = item_name
    check(prototypes.item[item_name] ~= nil, "missing item " .. item_name)
    if prototypes.item[item_name] then
      check(prototypes.item[item_name].place_result and
          prototypes.item[item_name].place_result.name == build_name,
        item_name .. " does not place " .. build_name)
    end
    check(prototypes.recipe[item_name] ~= nil, "missing recipe " .. item_name)
    if prototypes.recipe[item_name] then
      check(prototypes.recipe[item_name].surface_conditions == nil,
        item_name .. " recipe is surface-restricted")
    end
    check_condition(build_name)
    check_condition(base_name)
    check(nauvis.can_place_entity{
        name = build_name, position = {100, 100}, force = force},
      item_name .. " cannot be placed on Nauvis")
    check(not vulcanus.can_place_entity{
        name = build_name, position = {100, 100}, force = force},
      item_name .. " can be placed on Vulcanus")
  end

  finish({checked = checked, cool_surface = nauvis.name, hot_surface = vulcanus.name})
end)

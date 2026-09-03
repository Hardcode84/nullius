local CASE = "water-well-placement"
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
  for tier = 1, 2 do
    local current = "nullius-well-" .. tier
    local legacy = "nullius-legacy-well-" .. tier
    for _, name in pairs({current, legacy}) do
      checked[#checked + 1] = name
      local item = prototypes.item[name]
      check(item ~= nil, "missing item prototype " .. name)
      if item then
        check(item.place_result and item.place_result.name == name,
          name .. " item has the wrong place result")
      end
      check_condition(name)
      check(nauvis.can_place_entity{
          name = name, position = {100, 100}, force = force},
        name .. " cannot be placed on Nauvis")
      check(not vulcanus.can_place_entity{
          name = name, position = {100, 100}, force = force},
        name .. " can be placed on Vulcanus")
    end

    local recipe = prototypes.recipe[current]
    check(recipe ~= nil, "missing recipe " .. current)
    if recipe then
      check(recipe.surface_conditions == nil,
        current .. " recipe is surface-restricted")
    end
  end

  finish({checked = checked, cool_surface = nauvis.name, hot_surface = vulcanus.name})
end)

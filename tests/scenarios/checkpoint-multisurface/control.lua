local CASE = "checkpoint-multisurface"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local INTERFACE = "nullius-test-checkpoints"

local assertions = 0
local failures = {}

local function check(condition, message)
  assertions = assertions + 1
  if not condition then failures[#failures + 1] = message end
end

local function close(actual, expected)
  return math.abs(actual - expected) < 0.000001
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

local function split_statistic(statistics, name, input, output)
  statistics.set_input_count(name, input)
  statistics.set_output_count(name, output)
end

local function progress(force, checkpoint, requirement)
  return remote.call(INTERFACE, "progress", force.name, checkpoint, requirement)
end

script.on_nth_tick(1, function()
  script.on_nth_tick(1, nil)
  check(remote.interfaces[INTERFACE] ~= nil, "missing checkpoint test interface")
  if not remote.interfaces[INTERFACE] then finish({}) return end

  local force = game.forces.player
  local nauvis = game.surfaces.nauvis
  local planet = game.planets["nullius-vulcanus"]
  check(nauvis ~= nil, "missing Nauvis surface")
  check(planet ~= nil, "missing Nullius Vulcanus planet")
  if not nauvis or not planet then finish({}) return end
  local vulcanus = planet.surface or planet.create_surface()
  check(vulcanus ~= nil, "failed to create Nullius Vulcanus surface")
  if not vulcanus then finish({}) return end

  local nauvis_items = force.get_item_production_statistics(nauvis)
  local vulcanus_items = force.get_item_production_statistics(vulcanus)
  split_statistic(nauvis_items, "nullius-iron-ingot", 6, 600)
  split_statistic(vulcanus_items, "nullius-iron-ingot", 10, 900)
  check(close(progress(force, "iron-ingot"), 1),
    "item production checkpoint did not aggregate surfaces")
  check(close(progress(force, "iron-ingot-2"), 1),
    "item consumption checkpoint did not aggregate surfaces")

  local nauvis_fluids = force.get_fluid_production_statistics(nauvis)
  local vulcanus_fluids = force.get_fluid_production_statistics(vulcanus)
  split_statistic(nauvis_fluids, "nullius-hydrogen", 400, 0)
  split_statistic(vulcanus_fluids, "nullius-hydrogen", 600, 0)
  split_statistic(nauvis_fluids, "nullius-water", 0, 4000)
  split_statistic(vulcanus_fluids, "nullius-water", 0, 6000)
  check(close(progress(force, "hydrogen"), 1),
    "fluid production checkpoint did not aggregate surfaces")
  check(close(progress(force, "water"), 1),
    "fluid consumption checkpoint did not aggregate surfaces")

  split_statistic(nauvis_items, "nullius-limestone", 0, 0)
  split_statistic(nauvis_items, "nullius-crushed-limestone", 319, 0)
  check(progress(force, "limestone") < 1,
    "calcite checkpoint completed before 320 crushed calcite")
  split_statistic(nauvis_items, "nullius-crushed-limestone", 320, 0)
  check(close(progress(force, "limestone"), 1),
    "calcite checkpoint did not accept 320 crushed calcite")

  split_statistic(nauvis_items, "nullius-limestone", 500, 0)
  split_statistic(nauvis_items, "nullius-crushed-limestone", 0, 0)
  check(close(progress(force, "limestone"), 1),
    "calcite checkpoint did not accept 500 calcite")

  split_statistic(nauvis_items, "nullius-limestone", 250, 0)
  split_statistic(nauvis_items, "nullius-crushed-limestone", 160, 0)
  check(close(progress(force, "limestone"), 1),
    "calcite checkpoint did not combine proportional alternatives")

  check(force.technologies["nullius-checkpoint-freshwater"] == nil,
    "obsolete freshwater checkpoint still exists")

  local nauvis_builds = force.get_entity_build_count_statistics(nauvis)
  local vulcanus_builds = force.get_entity_build_count_statistics(vulcanus)
  split_statistic(nauvis_builds, "nullius-small-furnace-1", 2, 0)
  split_statistic(vulcanus_builds, "nullius-small-furnace-1", 3, 1)
  check(close(progress(force, "furnace"), 1),
    "building net-count checkpoint did not aggregate surfaces")

  split_statistic(nauvis_fluids, "nullius-carbon-dioxide", 0, 600000000)
  split_statistic(vulcanus_fluids, "nullius-carbon-dioxide", 0, 900000000)
  check(close(progress(force, "carbon-sequestration", 1), 1),
    "carbon sequestration checkpoint did not aggregate surfaces")

  vulcanus.request_to_generate_chunks({100, 100}, 1)
  vulcanus.force_generate_chunk_requests()
  local tiles = {}
  for x = 98, 102 do
    for y = 98, 102 do
      tiles[#tiles + 1] = {name = "volcanic-soil-dark", position = {x, y}}
    end
  end
  vulcanus.set_tiles(tiles, true, false, false, false)
  local entity = vulcanus.create_entity{
    name = "nullius-small-furnace-1-thermal",
    position = {100, 100},
    force = force,
  }
  check(entity ~= nil, "failed to create replacement-statistics fixture")
  if not entity then finish({}) return end
  split_statistic(nauvis_builds, entity.name, 0, 0)
  split_statistic(vulcanus_builds, entity.name, 0, 0)
  remote.call(INTERFACE, "adjust_build_statistics", entity, false)
  check(close(nauvis_builds.get_input_count(entity.name), 0),
    "replacement build was attributed to Nauvis")
  check(close(vulcanus_builds.get_input_count(entity.name), 1),
    "replacement build was not attributed to Vulcanus")
  remote.call(INTERFACE, "adjust_build_statistics", entity, true)
  check(close(nauvis_builds.get_output_count(entity.name), 0),
    "replacement removal was attributed to Nauvis")
  check(close(vulcanus_builds.get_output_count(entity.name), 1),
    "replacement removal was not attributed to Vulcanus")

  finish({surfaces = {nauvis.name, vulcanus.name}})
end)

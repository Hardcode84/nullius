-- given: five starter-pack platforms above Nauvis with Vulcanus unlocked; each
--   has one thruster fed thruster fuel and oxidizer from declared infinity
--   pipes, held at one fill level per platform.
-- place: thruster and two infinity pipes on a foundation extension behind each platform hub.
-- connect: each pipe to its thruster's west fluid connection.
-- act: schedule every platform to Vulcanus.
-- run: sample every 600 ticks until all arrive or the window ends.
-- expect: observations give speed, weight, propellant consumed, and kilometres
--   travelled per sample, so propellant per trip follows for each throttle.
local CASE = "experiment-platform-transit"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local DESTINATION = "nullius-vulcanus"
local CONNECTION_KM = 15000
local WINDOW_END = 9000
local VARIANTS = {
  {name = "fill-100", percentage = 1}, {name = "fill-60", percentage = 0.6},
  {name = "fill-40", percentage = 0.4}, {name = "fill-25", percentage = 0.25},
  {name = "fill-10", percentage = 0.1},
}

local function check(ok, message)
  storage.assertions = storage.assertions + 1
  if not ok then storage.failures[#storage.failures + 1] = message end
end

local function consumed(row, fluid)
  return game.forces.player.get_fluid_production_statistics(row.platform.surface).output_counts[fluid] or 0
end

local function sample(row)
  local platform = row.platform
  local km = platform.distance and platform.distance * CONNECTION_KM or nil
  row.samples[#row.samples + 1] = {
    tick = game.tick, state = platform.state, speed = platform.speed, km = km,
    weight = platform.weight, location = platform.space_location and platform.space_location.name or nil,
    fuel = consumed(row, "thruster-fuel"), oxidizer = consumed(row, "thruster-oxidizer"),
    fuel_fill = row.thruster.get_fluid_count("thruster-fuel"),
  }
  if not row.arrived and platform.space_location and platform.space_location.name == DESTINATION then
    row.arrived = game.tick
  end
end

local function finish()
  local observations = {}
  for _, row in ipairs(storage.rows) do
    observations[row.name] = {percentage = row.percentage, departed = row.departed,
      arrived = row.arrived, samples = row.samples}
    check(row.samples[#row.samples].fuel > 0, row.name .. " consumed no fuel")
  end
  helpers.write_file(RESULT, helpers.table_to_json{
    schema = 1, case = CASE, status = (#storage.failures == 0) and "pass" or "fail",
    factorio_version = script.active_mods.base, tick = game.tick,
    assertions = storage.assertions, failure_count = #storage.failures,
    failures = storage.failures, observations = observations}, false)
  if #storage.failures > 0 then error(helpers.table_to_json(storage.failures)) end
end

script.on_init(function()
  storage.assertions = 0
  storage.failures = {}
  storage.rows = {}
  local force = game.forces.player
  force.unlock_space_location(DESTINATION)
  for _, variant in ipairs(VARIANTS) do
    local platform = assert(force.create_space_platform{
      name = CASE .. "-" .. variant.name, planet = "nauvis", starter_pack = "space-platform-starter-pack"})
    assert(platform.apply_starter_pack(true))
    local surface = platform.surface
    local tiles={}
    for x=-3,2 do for y=5,8 do tiles[#tiles+1]={name="space-platform-foundation",position={x,y}} end end
    surface.set_tiles(tiles)
    check(surface.can_place_entity{name="thruster",position={0,6.5},force=force},variant.name.." collision-free thruster")
    local thruster = surface.create_entity{name = "thruster", position = {0, 6.5}, force = force}
    check(thruster ~= nil, variant.name .. " thruster placement")
    for fluid, y in pairs({["thruster-fuel"] = 4.5, ["thruster-oxidizer"] = 6.5}) do
      local pipe = assert(surface.create_entity{name = "infinity-pipe", position = {-2.5, y}, force = force})
      pipe.set_infinity_pipe_filter{name = fluid, percentage = variant.percentage, mode = "exactly"}
    end
    platform.schedule = {current = 1, records = {{station = DESTINATION}}}
    platform.paused = false
    storage.rows[#storage.rows + 1] = {name = variant.name, percentage = variant.percentage,
      platform = platform, thruster = thruster, samples = {}}
  end
end)

script.on_nth_tick(600, function()
  local done = true
  for _, row in ipairs(storage.rows) do
    if not row.departed and row.platform.space_connection then row.departed = game.tick end
    sample(row)
    done = done and row.arrived ~= nil
  end
  if done or game.tick >= WINDOW_END then
    script.on_nth_tick(600, nil)
    finish()
  end
end)

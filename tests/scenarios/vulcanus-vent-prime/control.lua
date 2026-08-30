local CASE = "vulcanus-vent-prime"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local GAS = "nullius-compressed-volcanic-gas"
local INTAKE = "nullius-seawater-intake-1"
local LAVA_INTAKE = "nullius-lava-intake-1"
local VENT = "nullius-lava-intake-1-gasvent"
local VENT_2 = "nullius-lava-intake-2-gasvent"
local DRILL = "nullius-gas-vent-drill"
local SEAM = "nullius-gas-vent-seam"

local assertions = 0
local failures = {}
local observations = {}

local function check(condition, message)
  assertions = assertions + 1
  if not condition then failures[#failures + 1] = message end
end

local function entities_at(surface, name, position)
  return surface.find_entities_filtered{
    name = name,
    position = position,
    radius = 0.1,
  }
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

local function check_cleanup()
  script.on_nth_tick(123, nil)
  local surface = game.planets["nullius-vulcanus"].surface
  local position = storage.vent_position
  check(#entities_at(surface, VENT, position) == 0,
    "gas-vent shell survived destruction")
  check(#entities_at(surface, DRILL, position) == 0,
    "owned hidden drill survived shell destruction")
  check(#entities_at(surface, SEAM, position) == 0,
    "owned hidden resource survived shell destruction")
  finish()
end

local function check_production()
  script.on_nth_tick(121, nil)
  local surface = game.planets["nullius-vulcanus"].surface
  local position = storage.vent_position
  local vents = entities_at(surface, VENT, position)
  local drills = entities_at(surface, DRILL, position)
  local seams = entities_at(surface, SEAM, position)
  local tanks = entities_at(surface, "storage-tank", storage.tank_position)
  local pipes = entities_at(surface, "pipe", storage.pipe_position)

  check(#vents == 1, "gas-vent shell disappeared during production")
  check(#drills == 1, "vent did not retain exactly one owned hidden drill")
  check(#seams == 1, "vent did not retain exactly one owned hidden resource")
  check(#tanks == 1, "gas buffer disappeared during production")
  check(#pipes == 1, "gas connection pipe disappeared during production")

  local vent_gas = (#vents == 1) and vents[1].get_fluid_count(GAS) or 0
  local drill_gas = (#drills == 1) and drills[1].get_fluid_count(GAS) or 0
  local tank_gas = (#tanks == 1) and tanks[1].get_fluid_count(GAS) or 0
  local pipe_gas = (#pipes == 1) and pipes[1].get_fluid_count(GAS) or 0
  local network_gas = vent_gas + drill_gas + pipe_gas + tank_gas
  observations.elapsed_ticks = game.tick - storage.started_tick
  observations.gas = {
    vent = vent_gas,
    drill = drill_gas,
    pipe = pipe_gas,
    tank = tank_gas,
    network = network_gas,
  }
  check(observations.elapsed_ticks >= 120,
    "production check ran before 120 simulated ticks")
  check(tank_gas > 0, "gas-vent output did not connect to the gas buffer")
  check(network_gas + 0.000001 >= 24,
    "gas network contained less than 24 compressed volcanic gas")

  if #vents == 1 then vents[1].destroy() end
  script.on_nth_tick(123, check_cleanup)
end

local function setup()
  script.on_nth_tick(1, nil)
  local planet = game.planets["nullius-vulcanus"]
  check(planet ~= nil, "missing nullius-vulcanus planet")
  if not planet then finish() return end

  local surface = planet.surface or planet.create_surface()
  check(surface ~= nil, "failed to create Vulcanus surface")
  if not surface then finish() return end

  local force = game.forces.player
  local technology = force.technologies["nullius-pneumatic-technology"]
  check(technology ~= nil, "missing initial pneumatic technology")
  if not technology then finish() return end
  technology.researched = true
  check(technology.researched, "failed to research initial pneumatic technology")

  surface.request_to_generate_chunks({0, 0}, 1)
  surface.force_generate_chunk_requests()
  local tiles = {}
  for x = -8, 8 do
    for y = -8, 8 do
      tiles[#tiles + 1] = {
        name = (y <= 1) and "lava-hot" or "volcanic-soil-dark",
        position = {x, y},
      }
    end
  end
  surface.set_tiles(tiles, true, false, false, false)

  local tier_2_vent = surface.create_entity{
    name = VENT_2,
    position = {6.5, 6.5},
    direction = defines.direction.north,
    force = force,
  }
  check(tier_2_vent ~= nil, "failed to create tier-2 free-gas vent")
  if tier_2_vent then
    check(tier_2_vent.rotate(), "tier-2 free-gas vent refused rotation")
    check(tier_2_vent.direction == defines.direction.east,
      "tier-2 free-gas vent did not rotate from north to east")
    tier_2_vent.destroy()
  end

  local position = surface.find_non_colliding_position(INTAKE, {0, 0}, 64, 1)
  check(position ~= nil, "no valid intake position near Vulcanus origin")
  if not position then finish() return end

  local ghost = surface.create_entity{
    name = "entity-ghost",
    inner_name = INTAKE,
    position = position,
    direction = defines.direction.north,
    force = force,
    expires = false,
  }
  check(ghost ~= nil, "failed to create seawater-intake ghost")
  if not ghost then finish() return end

  ghost.revive{raise_revive = true}
  local lava_intakes = surface.find_entities_filtered{
    name = LAVA_INTAKE,
    position = position,
    radius = 2,
  }
  check(#surface.find_entities_filtered{
      name = INTAKE, position = position, radius = 2} == 0,
    "production build event left a seawater intake on Vulcanus")
  check(#lava_intakes == 1,
    "production build event did not create exactly one lava intake")
  if #lava_intakes ~= 1 then finish() return end

  local lava_intake = lava_intakes[1]
  position = lava_intake.position
  local direction = lava_intake.direction
  lava_intake.destroy{raise_destroy = true}
  local vent_ghost = surface.create_entity{
    name = "entity-ghost",
    inner_name = VENT,
    position = position,
    direction = direction,
    force = force,
    expires = false,
  }
  check(vent_ghost ~= nil, "failed to create free-gas mode ghost")
  if not vent_ghost then finish() return end
  local _, vent = vent_ghost.revive{raise_revive = true}
  check(vent ~= nil, "failed to select free-gas intake mode")
  if not vent then finish() return end
  position = vent.position

  check(#entities_at(surface, VENT, position) == 1,
    "free-gas mode did not create exactly one visible vent")
  check(#entities_at(surface, DRILL, position) == 1,
    "free-gas mode did not create exactly one owned hidden drill")
  check(#entities_at(surface, SEAM, position) == 1,
    "free-gas mode did not create exactly one owned hidden resource")

  local drills = entities_at(surface, DRILL, position)
  if #drills ~= 1 then finish() return end
  check(vent.rotate(), "free-gas vent refused clockwise rotation")
  check(vent.direction == defines.direction.east,
    "free-gas vent did not rotate from north to east")
  remote.call("nullius-test-gasvent", "rotated", vent)
  check(drills[1].direction == vent.direction,
    "hidden gas drill did not follow free-gas vent rotation")
  local pipe_position = nil
  for _, connection in pairs(drills[1].fluidbox.get_pipe_connections(1)) do
    if connection.target_position then
      pipe_position = connection.target_position
      break
    end
  end
  check(pipe_position ~= nil, "gas vent has no physical output connection")
  if not pipe_position then finish() return end
  local pipe = surface.create_entity{
    name = "pipe",
    position = pipe_position,
    force = force,
  }
  check(pipe ~= nil, "failed to place pipe on gas-vent output")
  if not pipe then finish() return end

  local outward_x = math.max(-1, math.min(1, pipe_position.x - position.x))
  local outward_y = math.max(-1, math.min(1, pipe_position.y - position.y))
  local tank_position = {
    pipe_position.x + (2 * outward_x) + outward_y,
    pipe_position.y + (2 * outward_y) - outward_x,
  }
  observations.layout = {
    vent = position,
    pipe = pipe_position,
    tank = tank_position,
    direction = vent.direction,
  }
  local tank = surface.create_entity{
    name = "storage-tank",
    position = tank_position,
    direction = vent.direction,
    force = force,
  }
  check(tank ~= nil, "failed to place gas buffer at vent output")
  if not tank then finish() return end
  check(tank.get_fluid_count(GAS) == 0, "gas buffer was not initially empty")

  storage.vent_position = position
  storage.pipe_position = pipe.position
  storage.tank_position = tank.position
  storage.started_tick = game.tick
  script.on_nth_tick(121, check_production)
end

script.on_nth_tick(1, setup)

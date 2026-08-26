local CASE = "vulcanus-pneumatic-heat"
local RESULT = "factorio-tests/" .. CASE .. ".json"

local cases = {
  {
    size = "small",
    machine = "nullius-small-assembler-1-pneumatic",
    interface = "nullius-pneumatic-heat-small",
    pipe_offset = {-0.5, -1.5},
    position = {-30, 0},
  },
  {
    size = "medium",
    machine = "nullius-foundry-1-pneumatic",
    interface = "nullius-pneumatic-heat-medium",
    pipe_offset = {-1, -2},
    position = {-10, 0},
  },
  {
    size = "medium2",
    machine = "nullius-surge-electrolyzer-1-pneumatic",
    interface = "nullius-pneumatic-heat-medium2",
    pipe_offset = {-1.5, -2.5},
    position = {10, 0},
  },
  {
    size = "large",
    machine = "nullius-hydro-plant-1-pneumatic",
    interface = "nullius-pneumatic-heat-large",
    pipe_offset = {0, -3},
    position = {30, 0},
  },
}

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

local function surface()
  return game.planets["nullius-vulcanus"].surface
end

local function check_cleanup()
  script.on_nth_tick(62, nil)
  local s = surface()
  for _, test in ipairs(cases) do
    local position = storage.machine_positions[test.size]
    check(#entities_at(s, test.machine, position) == 0,
      test.size .. " pneumatic machine survived destruction")
    check(#entities_at(s, test.interface, position) == 0,
      test.size .. " heat interface survived machine destruction")
  end
  finish()
end

local function check_heat_transfer()
  script.on_nth_tick(60, nil)
  local s = surface()
  for _, test in ipairs(cases) do
    local position = storage.machine_positions[test.size]
    local interfaces = entities_at(s, test.interface, position)
    check(#interfaces == 1,
      test.size .. " heat interface disappeared before transfer check")
    if #interfaces == 1 then
      local before = storage.initial_temperatures[test.size]
      local after = interfaces[1].temperature
      observations[test.size] = {
        initial_temperature = before,
        final_temperature = after,
      }
      check(after > before + 0.1,
        test.size .. " heat interface did not receive heat from delayed pipe")
    end

    local machines = entities_at(s, test.machine, position)
    if #machines == 1 then machines[1].destroy() end
  end
  script.on_nth_tick(62, check_cleanup)
end

local function place_heat_pipes()
  script.on_nth_tick(5, nil)
  local s = surface()
  storage.initial_temperatures = {}
  for _, test in ipairs(cases) do
    local machine_position = storage.machine_positions[test.size]
    local interfaces = entities_at(s, test.interface, machine_position)
    check(#interfaces == 1,
      test.size .. " machine did not own exactly one heat interface at tick 5")
    if #interfaces == 1 then
      storage.initial_temperatures[test.size] = interfaces[1].temperature
      check(math.abs(interfaces[1].temperature - 15) < 0.01,
        test.size .. " heat interface warmed before heat-pipe placement")
    else
      storage.initial_temperatures[test.size] = 15
    end

    local pipe_position = {
      machine_position.x + test.pipe_offset[1],
      machine_position.y + test.pipe_offset[2],
    }
    local pipe = s.create_entity{
      name = "nullius-heat-pipe-2",
      position = pipe_position,
      force = game.forces.player,
    }
    check(pipe ~= nil,
      test.size .. " heat pipe could not be placed at expected connection")
    if pipe then pipe.temperature = 500 end
  end
  script.on_nth_tick(60, check_heat_transfer)
end

local function setup()
  script.on_nth_tick(1, nil)
  local planet = game.planets["nullius-vulcanus"]
  check(planet ~= nil, "missing nullius-vulcanus planet")
  if not planet then finish() return end

  local s = planet.surface or planet.create_surface()
  check(s ~= nil, "failed to create Vulcanus surface")
  if not s then finish() return end

  s.request_to_generate_chunks({0, 0}, 3)
  s.force_generate_chunk_requests()
  local tiles = {}
  for x = -48, 48 do
    for y = -12, 12 do
      tiles[#tiles + 1] = {name = "volcanic-soil-dark", position = {x, y}}
    end
  end
  s.set_tiles(tiles, true, false, false, false)

  storage.machine_positions = {}
  for _, test in ipairs(cases) do
    local ghost = s.create_entity{
      name = "entity-ghost",
      inner_name = test.machine,
      position = test.position,
      force = game.forces.player,
      expires = false,
    }
    check(ghost ~= nil, "failed to create " .. test.size .. " machine ghost")
    if ghost then
      local _, machine = ghost.revive{raise_revive = true}
      check(machine ~= nil, "failed to revive " .. test.size .. " machine")
      if machine then
        machine.active = false
        storage.machine_positions[test.size] = machine.position
        check(#entities_at(s, test.interface, machine.position) == 1,
          test.size .. " build did not create exactly one heat interface")
      end
    end
  end

  if #failures > 0 then finish() return end
  script.on_nth_tick(5, place_heat_pipes)
end

script.on_nth_tick(1, setup)

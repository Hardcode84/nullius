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
    machine = "nullius-medium-assembler-1-pneumatic",
    interface = "nullius-pneumatic-heat-medium",
    pipe_offset = {-1, -2},
    position = {-10, 0},
  },
  {
    size = "medium2",
    machine = "nullius-surge-compressor-1-pneumatic",
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

local excluded_machines = {
  {name = "nullius-pump-1-pneumatic", type = "pump"},
  {name = "nullius-pump-2-pneumatic", type = "pump"},
  {name = "pump-pneumatic", type = "pump"},
  {name = "nullius-small-pump-1-pneumatic", type = "pump"},
  {name = "nullius-small-pump-2-pneumatic", type = "pump"},
  {name = "nullius-togglable-pump-1-pneumatic", type = "pump"},
  {name = "nullius-togglable-pump-2-pneumatic", type = "pump"},
  {name = "nullius-togglable-pump-3-pneumatic", type = "pump"},
  {name = "nullius-togglable-small-pump-1-pneumatic", type = "pump"},
  {name = "nullius-togglable-small-pump-2-pneumatic", type = "pump"},
  {name = "nullius-boxer-pneumatic", type = "furnace"},
}

local heat_interfaces = {
  "nullius-pneumatic-heat-small",
  "nullius-pneumatic-heat-medium",
  "nullius-pneumatic-heat-medium2",
  "nullius-pneumatic-heat-large",
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

local function heat_interfaces_at(surface, position)
  return surface.find_entities_filtered{
    name = heat_interfaces,
    position = position,
    radius = 0.1,
  }
end

local function check_rebuild(s)
  local interface = remote.interfaces["nullius-test-pneumatic-heat"]
  check(interface ~= nil, "missing pneumatic heat test interface")
  if not interface then return end

  local small = cases[1]
  local small_interfaces = entities_at(
    s, small.interface, storage.machine_positions[small.size])
  check(#small_interfaces == 1, "missing small interface before rebuild corruption")
  if #small_interfaces == 1 then small_interfaces[1].temperature = 321 end

  remote.call("nullius-test-pneumatic-heat", "forget_all")
  local fresh_position = {-45, -8}
  local fresh_ghost = s.create_entity{
    name = "entity-ghost",
    inner_name = small.machine,
    position = fresh_position,
    force = game.forces.player,
    expires = false,
  }
  check(fresh_ghost ~= nil, "failed to create fresh machine with missing storage")
  local fresh_machine
  if fresh_ghost then
    local _, revived = fresh_ghost.revive{raise_revive = true}
    fresh_machine = revived
  end
  check(fresh_machine ~= nil, "failed to revive fresh machine with missing storage")
  check(#entities_at(s, small.interface, fresh_position) == 1,
    "first build with missing storage lost its heat ownership")
  if fresh_machine then fresh_machine.destroy() end

  local duplicate = s.create_entity{
    name = small.interface,
    position = storage.machine_positions[small.size],
    force = game.forces.player,
  }
  check(duplicate ~= nil, "failed to create duplicate heat interface")
  if duplicate then duplicate.temperature = 123 end

  local medium = cases[2]
  local wrong_size = s.create_entity{
    name = cases[1].interface,
    position = storage.machine_positions[medium.size],
    force = game.forces.player,
  }
  check(wrong_size ~= nil, "failed to create wrong-size heat interface")

  local large = cases[4]
  local missing = entities_at(
    s, large.interface, storage.machine_positions[large.size])
  check(#missing == 1, "missing large interface before deletion")
  if #missing == 1 then missing[1].destroy() end

  local stray_position = {45, 8}
  local stray = s.create_entity{
    name = cases[3].interface,
    position = stray_position,
    force = game.forces.player,
  }
  check(stray ~= nil, "failed to create stray heat interface")

  remote.call("nullius-test-pneumatic-heat", "rebuild")
  check(#s.find_entities_filtered{name = heat_interfaces} == #cases,
    "missing-storage rebuild did not leave one interface per machine")
  check(#heat_interfaces_at(s, stray_position) == 0,
    "missing-storage rebuild did not remove stray interface")
  for _, test in ipairs(cases) do
    local position = storage.machine_positions[test.size]
    check(#heat_interfaces_at(s, position) == 1,
      test.size .. " rebuild left duplicate or wrong-size interfaces")
    check(#entities_at(s, test.interface, position) == 1,
      test.size .. " rebuild did not select the correct interface size")
  end
  local preserved = entities_at(
    s, small.interface, storage.machine_positions[small.size])
  check(#preserved == 1 and math.abs(preserved[1].temperature - 321) < 0.01,
    "rebuild did not preserve the hottest valid interface")

  local medium_machine = entities_at(
    s, medium.machine, storage.machine_positions[medium.size])[1]
  check(medium_machine ~= nil, "missing medium machine for partial-state rebuild")
  if medium_machine then
    remote.call("nullius-test-pneumatic-heat", "forget_owner",
      medium_machine.unit_number)
  end
  remote.call("nullius-test-pneumatic-heat", "rebuild")
  local first_units = {}
  for _, test in ipairs(cases) do
    local heat = entities_at(s, test.interface,
      storage.machine_positions[test.size])[1]
    first_units[test.size] = heat and heat.unit_number
  end
  remote.call("nullius-test-pneumatic-heat", "rebuild")
  check(#s.find_entities_filtered{name = heat_interfaces} == #cases,
    "repeated rebuild changed interface count")
  for _, test in ipairs(cases) do
    local heat = entities_at(s, test.interface,
      storage.machine_positions[test.size])[1]
    check(heat and heat.unit_number == first_units[test.size],
      test.size .. " repeated rebuild replaced a valid interface")
  end

  local clone_position = {-40, -8}
  local source = entities_at(
    s, small.machine, storage.machine_positions[small.size])[1]
  local clone = source and source.clone{
    position = clone_position,
    surface = s,
    force = game.forces.player,
  }
  check(clone ~= nil, "failed to clone pneumatic machine")
  check(#entities_at(s, small.interface, clone_position) == 1,
    "cloned pneumatic machine did not receive one heat interface")
  if clone then clone.destroy() end
  storage.clone_position = clone_position
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
  check(#heat_interfaces_at(s, storage.clone_position) == 0,
    "cloned machine heat interface survived destruction event")
  storage.initial_temperatures = {}
  for _, test in ipairs(cases) do
    local machine_position = storage.machine_positions[test.size]
    local interfaces = entities_at(s, test.interface, machine_position)
    check(#interfaces == 1,
      test.size .. " machine did not own exactly one heat interface at tick 5")
    if #interfaces == 1 then
      storage.initial_temperatures[test.size] = interfaces[1].temperature
      local expected = (test.size == "small") and 321 or 15
      check(math.abs(interfaces[1].temperature - expected) < 0.01,
        test.size .. " heat interface has unexpected initial temperature")
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

  observations.excluded_machines = {}
  for index, excluded in ipairs(excluded_machines) do
    local name = excluded.name
    local prototype = prototypes.entity[name]
    check(prototype ~= nil, "missing excluded pneumatic machine " .. name)
    if prototype then
      check(prototype.type == excluded.type,
        name .. " is not a " .. excluded.type)
      local position = {-45 + (index - 1) * 10, 8}
      local ghost = s.create_entity{
        name = "entity-ghost",
        inner_name = name,
        position = position,
        force = game.forces.player,
        expires = false,
      }
      check(ghost ~= nil, "failed to create " .. name .. " ghost")
      if ghost then
        local _, machine = ghost.revive{raise_revive = true}
        check(machine ~= nil, "failed to revive " .. name)
        if machine then
          check(#heat_interfaces_at(s, machine.position) == 0,
            name .. " created a heat interface")
          observations.excluded_machines[name] = machine.type
        end
      end
    end
  end

  check_rebuild(s)

  if #failures > 0 then finish() return end
  script.on_nth_tick(5, place_heat_pipes)
end

script.on_nth_tick(1, setup)

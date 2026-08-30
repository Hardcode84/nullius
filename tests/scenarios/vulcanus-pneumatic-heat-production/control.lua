local CASE = "vulcanus-pneumatic-heat-production"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local HYDRO = "nullius-hydro-plant-1-pneumatic"
local HYDRO_RECIPE = "nullius-lava-gas-extraction"
local FURNACE = "nullius-small-furnace-1-thermal"
local FURNACE_RECIPE = "nullius-aluminum-ingot"
local RADIATOR = "nullius-vulcanus-radiator-1"
local RADIATOR_RECIPE = "nullius-so2-catalytic-decomposition"
local HEAT_PIPE = "nullius-heat-pipe-1"
local HEAT_INTERFACE = "nullius-pneumatic-heat-large"
local GAS = "nullius-compressed-volcanic-gas"
local SO2 = "nullius-sulfur-dioxide"
local OXYGEN = "nullius-oxygen"
local INITIAL_TECH = "nullius-pneumatic-technology"
local RECIPE_TECH = "nullius-aluminum-production"
local HEAT_PIPE_BUDGET = 30
local TERMINAL_TICK = 65000
local BASE_X = 32

local HYDRO_FIXTURES = {
  {position = {BASE_X - 4, -4}, gas_side = -1, lava_side = -1},
  {position = {BASE_X + 4, -4}, gas_side = 1, lava_side = 1},
  {position = {BASE_X - 4, 4}, gas_side = -1, lava_side = -1},
  {position = {BASE_X + 4, 4}, gas_side = 1, lava_side = 1},
}

local DIRECTION_OFFSET = {
  [defines.direction.north] = {0, -1},
  [defines.direction.east] = {1, 0},
  [defines.direction.south] = {0, 1},
  [defines.direction.west] = {-1, 0},
}

local assertions = 0
local failures = {}
local observations = {}

local function check(condition, message)
  assertions = assertions + 1
  if not condition then failures[#failures + 1] = message end
end

local function close(actual, expected)
  return math.abs(actual - expected) < 0.000001
end

local function status_name(status)
  for name, value in pairs(defines.entity_status) do
    if value == status then return name end
  end
  return tostring(status)
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

local function research_closure(technology, visited)
  if visited[technology.name] then return end
  visited[technology.name] = true
  for _, prerequisite in pairs(technology.prerequisites) do
    research_closure(prerequisite, visited)
  end
  technology.researched = true
end

local function place(surface, name, position, direction)
  local entity = surface.create_entity{
    name = name,
    position = position,
    direction = direction,
    force = game.forces.player,
  }
  check(entity ~= nil,
    "failed to place " .. name .. " at [" .. position[1] .. "," .. position[2] .. "]")
  return entity
end

local function build(surface, name, position, direction)
  local ghost = surface.create_entity{
    name = "entity-ghost",
    inner_name = name,
    position = position,
    direction = direction or defines.direction.north,
    force = game.forces.player,
    expires = false,
  }
  check(ghost ~= nil, "failed to create ghost for " .. name)
  if not ghost then return nil end
  local _, entity = ghost.revive{raise_revive = true}
  check(entity ~= nil, "failed to revive " .. name)
  return entity
end

local function heat_target(machine)
  local source = machine.prototype.heat_energy_source_prototype
  check(source ~= nil, machine.name .. " has no heat energy source")
  if not source then return nil end
  check(#source.connections > 0, machine.name .. " has no heat connection")
  if #source.connections == 0 then return nil end
  local connection = source.connections[1]
  local outward = DIRECTION_OFFSET[connection.direction]
  check(outward ~= nil, machine.name .. " heat connection is not cardinal")
  if not outward then return nil end
  return {
    machine.position.x + connection.position[1] + outward[1],
    machine.position.y + connection.position[2] + outward[2],
  }
end

local function item_counts(machine)
  local result = {}
  local inventory = machine.get_output_inventory()
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

local function fluid_total(machine, entities, fluid)
  local total = machine.get_fluid_count(fluid)
  for _, entity in ipairs(entities) do
    if entity.valid then total = total + entity.get_fluid_count(fluid) end
  end
  return total
end

local function stone_total()
  local total = 0
  for index, hydro in ipairs(storage.hydros) do
    total = total + hydro.get_item_count("stone")
    total = total + storage.stone_sinks[index].get_item_count("stone")
    local held = storage.stone_inserters[index].held_stack
    if held.valid_for_read and held.name == "stone" then total = total + held.count end
  end
  return total
end

local function check_terminal()
  script.on_nth_tick(TERMINAL_TICK, nil)
  local furnace_outputs = item_counts(storage.furnace)
  local radiator_outputs = item_counts(storage.radiator)
  local oxygen = fluid_total(storage.radiator, storage.oxygen_entities, OXYGEN)
  local owned_interfaces = storage.surface.find_entities_filtered{name = HEAT_INTERFACE}
  local debug_sources = storage.surface.find_entities_filtered{type = "heat-interface"}
  local hydro_cycles = 0
  local minimum_interface_temperature = 1000
  local hydro_state = {}
  local heat_pipe_state = {}
  for _, pipe in ipairs(storage.heat_pipes) do
    heat_pipe_state[#heat_pipe_state + 1] = {
      position = pipe.position,
      temperature = pipe.temperature,
    }
  end
  for index, hydro in ipairs(storage.hydros) do
    hydro_cycles = hydro_cycles + hydro.products_finished
    hydro_state[index] = {
      cycles = hydro.products_finished,
      stone_in_machine = hydro.get_item_count("stone"),
      stone_in_sink = storage.stone_sinks[index].get_item_count("stone"),
      inserter_status = status_name(storage.stone_inserters[index].status),
      inserter_energy = storage.stone_inserters[index].energy,
      hydro_status = status_name(hydro.status),
      gas = hydro.get_fluid_count(GAS),
      lava = hydro.get_fluid_count("lava"),
    }
  end
  for _, interface in ipairs(owned_interfaces) do
    minimum_interface_temperature = math.min(minimum_interface_temperature,
      interface.temperature)
  end
  observations.terminal = {
    heat_pipe_count = #storage.heat_pipes,
    hydro_cycles = hydro_cycles,
    stone = stone_total(),
    furnace_cycles = storage.furnace.products_finished,
    furnace_temperature = storage.furnace.temperature,
    furnace_outputs = furnace_outputs,
    radiator_cycles = storage.radiator.products_finished,
    radiator_temperature = storage.radiator.temperature,
    radiator_outputs = radiator_outputs,
    oxygen = oxygen,
    owned_heat_interfaces = #owned_interfaces,
    minimum_interface_temperature = minimum_interface_temperature,
    heat_interface_entities = #debug_sources,
    hydro_state = hydro_state,
    heat_pipe_state = heat_pipe_state,
  }

  check(#storage.heat_pipes <= HEAT_PIPE_BUDGET,
    "fixture exceeded the 30 heat-pipe landing stock")
  check(hydro_cycles > 0, "pneumatic hydro plants completed no gas-extraction cycles")
  check(stone_total() == hydro_cycles * 3,
    "stone output does not match completed gas-extraction cycles")
  check(#owned_interfaces == 4,
    "four hydros did not own exactly four pneumatic heat interfaces")
  check(#debug_sources == 4,
    "fixture contains a heat-interface other than the four owned pneumatic sources")
  check(minimum_interface_temperature > 15,
    "one or more owned heat interfaces remained at engine-default temperature")
  check(storage.furnace.temperature >= 100,
    "furnace did not receive its minimum working temperature")
  check(storage.radiator.temperature >= 200,
    "radiator did not receive its minimum working temperature")
  check(storage.furnace.products_finished == 1,
    "furnace did not complete exactly one aluminum reduction cycle")
  check(storage.radiator.products_finished == 1,
    "radiator did not complete exactly one catalysis cycle")
  check_exact_counts(furnace_outputs, {
    ["nullius-aluminum-ingot"] = 3,
    ["nullius-aluminum-carbide"] = 4,
  }, "furnace output")
  check_exact_counts(radiator_outputs, {
    sulfur = 1,
    ["nullius-rutile"] = 1,
  }, "radiator output")
  check(close(oxygen, 40), "radiator oxygen output mismatch")
  finish()
end

local function setup()
  script.on_nth_tick(1, nil)
  local planet = game.planets["nullius-vulcanus"]
  check(planet ~= nil, "missing nullius-vulcanus planet")
  if not planet then finish() return end
  local surface = planet.surface or planet.create_surface()
  check(surface ~= nil, "failed to create Vulcanus surface")
  if not surface then finish() return end
  storage.surface = surface
  surface.request_to_generate_chunks({BASE_X, 0}, 2)
  surface.force_generate_chunk_requests()
  local tiles = {}
  for x = BASE_X - 20, BASE_X + 20 do
    for y = -16, 16 do
      tiles[#tiles + 1] = {name = "volcanic-soil-dark", position = {x, y}}
    end
  end
  surface.set_tiles(tiles, true, false, false, false)
  for _, entity in ipairs(surface.find_entities_filtered{
      area = {{BASE_X - 20, -16}, {BASE_X + 20, 16}},
      type = {"simple-entity", "tree", "cliff", "resource"},
  }) do
    entity.destroy()
  end

  local force = game.forces.player
  local initial_technology = force.technologies[INITIAL_TECH]
  check(initial_technology ~= nil, "missing initial pneumatic technology")
  if not initial_technology then finish() return end
  local researched = {}
  research_closure(initial_technology, researched)
  check(researched[RECIPE_TECH] == true,
    "initial pneumatic closure omitted aluminum production")
  check(force.recipes[HYDRO_RECIPE] and force.recipes[HYDRO_RECIPE].enabled,
    "gas-extraction recipe is not enabled")
  check(force.recipes[FURNACE_RECIPE] and force.recipes[FURNACE_RECIPE].enabled,
    "aluminum reduction recipe is not enabled")
  check(force.recipes[RADIATOR_RECIPE] and force.recipes[RADIATOR_RECIPE].enabled,
    "catalysis recipe is not enabled")

  storage.hydros = {}
  storage.stone_sinks = {}
  storage.stone_inserters = {}
  storage.lava_sources = {}
  storage.gas_entities = {}
  for _, fixture in ipairs(HYDRO_FIXTURES) do
    local hydro = build(surface, HYDRO, fixture.position, defines.direction.north)
    if not hydro then finish() return end
    hydro.active = false
    check(hydro.set_recipe(HYDRO_RECIPE), "failed to set hydro gas-extraction recipe")
    storage.hydros[#storage.hydros + 1] = hydro

    local gas_offsets
    if fixture.gas_side < 0 then
      gas_offsets = {{-3,0},{-4,0},{-5,0},{-4,1},{-4,2},{-4,3},{-3,3},{-2,3},{-1,3}}
    else
      gas_offsets = {{3,0},{4,0},{5,0},{4,1},{4,2},{4,3},{3,3},{2,3},{1,3}}
    end
    for _, offset in ipairs(gas_offsets) do
      local pipe = place(surface, "pipe", {
        hydro.position.x + offset[1], hydro.position.y + offset[2]})
      if not pipe then finish() return end
      storage.gas_entities[#storage.gas_entities + 1] = pipe
    end
    local gas_endpoint = {
      hydro.position.x + fixture.gas_side * 5, hydro.position.y,
    }
    local gas_tank = place(surface, "storage-tank", {
      hydro.position.x + fixture.gas_side * 8, hydro.position.y + 1})
    if not gas_tank then finish() return end
    storage.gas_entities[#storage.gas_entities + 1] = gas_tank
    local tank_target = nil
    local tank_distance = nil
    for _, connection in pairs(gas_tank.fluidbox.get_pipe_connections(1)) do
      local target = connection.target_position
      local distance = math.abs(target.x - gas_endpoint[1]) +
        math.abs(target.y - gas_endpoint[2])
      if not tank_distance or distance < tank_distance then
        tank_target = target
        tank_distance = distance
      end
    end
    check(tank_target ~= nil, "gas storage tank has no pipe connection")
    if not tank_target then finish() return end
    local route_x = gas_endpoint[1]
    local route_y = gas_endpoint[2]
    while route_x ~= tank_target.x or route_y ~= tank_target.y do
      if route_x < tank_target.x then route_x = route_x + 1
      elseif route_x > tank_target.x then route_x = route_x - 1
      elseif route_y < tank_target.y then route_y = route_y + 1
      else route_y = route_y - 1 end
      local pipe = place(surface, "pipe", {route_x, route_y})
      if not pipe then finish() return end
      storage.gas_entities[#storage.gas_entities + 1] = pipe
    end

    local gas_box = nil
    for index = 1, #hydro.fluidbox do
      local filter = hydro.fluidbox.get_filter(index)
      if filter and filter.name == GAS then gas_box = gas_box or index end
    end
    check(gas_box ~= nil, "hydro has no compressed-gas fluid box")
    if not gas_box then finish() return end
    hydro.fluidbox[gas_box] = {
      name = GAS,
      amount = 24,
      temperature = prototypes.fluid[GAS].default_temperature,
    }

    local lava_box = nil
    for index = 1, #hydro.fluidbox do
      local filter = hydro.fluidbox.get_filter(index)
      if filter and filter.name == "lava" then lava_box = index end
    end
    check(lava_box ~= nil, "hydro has no lava fluid box")
    if not lava_box then finish() return end
    local connections = hydro.fluidbox.get_pipe_connections(lava_box)
    local selected = nil
    for _, connection in pairs(connections) do
      if not selected or
          (fixture.lava_side < 0 and connection.target_position.x < selected.x) or
          (fixture.lava_side > 0 and connection.target_position.x > selected.x) then
        selected = connection.target_position
      end
    end
    check(selected ~= nil, "hydro lava input has no pipe connection")
    if not selected then finish() return end
    local lava = place(surface, "infinity-pipe", {selected.x, selected.y})
    if not lava then finish() return end
    lava.set_infinity_pipe_filter{
      name = "lava", percentage = 1, mode = "at-least",
      temperature = prototypes.fluid.lava.default_temperature,
    }
    storage.lava_sources[#storage.lava_sources + 1] = lava

    local sink = place(surface, "steel-chest", {hydro.position.x, hydro.position.y + 4})
    local inserter = place(surface, "inserter", {hydro.position.x, hydro.position.y + 3},
      defines.direction.north)
    if not sink or not inserter then finish() return end
    storage.stone_sinks[#storage.stone_sinks + 1] = sink
    storage.stone_inserters[#storage.stone_inserters + 1] = inserter

    local pole = place(surface, "small-electric-pole", {
      hydro.position.x + fixture.gas_side * 2, hydro.position.y + 4})
    local power = place(surface, "electric-energy-interface", {
      hydro.position.x + fixture.gas_side * 4, hydro.position.y + 4})
    if not pole or not power then finish() return end
    power.power_production = 1000000
    power.electric_buffer_size = 1000000
  end

  storage.furnace = build(surface, FURNACE, {BASE_X, -4}, defines.direction.north)
  storage.radiator = build(surface, RADIATOR, {BASE_X, 9}, defines.direction.north)
  if not storage.furnace or not storage.radiator then finish() return end
  storage.furnace.active = false
  storage.radiator.active = false
  check(storage.furnace.set_recipe(FURNACE_RECIPE),
    "failed to set aluminum reduction recipe")
  check(storage.radiator.set_recipe(RADIATOR_RECIPE),
    "failed to set catalytic decomposition recipe")

  local furnace_input = storage.furnace.get_inventory(
    defines.inventory.assembling_machine_input)
  check(furnace_input ~= nil, "furnace has no input inventory")
  if not furnace_input then finish() return end
  check(furnace_input.insert{name = "nullius-alumina", count = 9} == 9,
    "failed to insert alumina")
  check(furnace_input.insert{name = "nullius-graphite", count = 5} == 5,
    "failed to insert graphite")

  local radiator_input = storage.radiator.get_inventory(
    defines.inventory.assembling_machine_input)
  check(radiator_input ~= nil, "radiator has no input inventory")
  if not radiator_input then finish() return end
  check(radiator_input.insert{name = "nullius-rutile", count = 1} == 1,
    "failed to insert rutile")

  local so2_box = nil
  local oxygen_box = nil
  for index = 1, #storage.radiator.fluidbox do
    local filter = storage.radiator.fluidbox.get_filter(index)
    if filter and filter.name == SO2 then so2_box = index end
    if filter and filter.name == OXYGEN then oxygen_box = index end
  end
  check(so2_box ~= nil, "radiator has no sulfur-dioxide fluid box")
  check(oxygen_box ~= nil, "radiator has no oxygen fluid box")
  if not so2_box or not oxygen_box then finish() return end
  local so2_connection = storage.radiator.fluidbox.get_pipe_connections(so2_box)[1]
  local oxygen_connection = storage.radiator.fluidbox.get_pipe_connections(oxygen_box)[1]
  check(so2_connection ~= nil, "radiator sulfur-dioxide box has no connection")
  check(oxygen_connection ~= nil, "radiator oxygen box has no connection")
  if not so2_connection or not oxygen_connection then finish() return end
  local so2_pipe = place(surface, "pipe", {
    so2_connection.target_position.x, so2_connection.target_position.y})
  local oxygen_pipe = place(surface, "pipe", {
    oxygen_connection.target_position.x, oxygen_connection.target_position.y})
  if not so2_pipe or not oxygen_pipe then finish() return end
  storage.oxygen_entities = {oxygen_pipe}
  check(close(so2_pipe.insert_fluid{
    name = SO2,
    amount = 40,
    temperature = prototypes.fluid[SO2].default_temperature,
  }, 40), "failed to insert sulfur dioxide")

  local furnace_heat_target = heat_target(storage.furnace)
  local radiator_heat_target = heat_target(storage.radiator)
  if not furnace_heat_target or not radiator_heat_target then finish() return end

  local coordinates = {}
  local top_y = storage.hydros[1].position.y - 3
  local bottom_y = storage.hydros[3].position.y - 3
  for x = storage.hydros[1].position.x, storage.hydros[2].position.x do
    coordinates[#coordinates + 1] = {x, top_y}
  end
  for x = storage.hydros[3].position.x, storage.hydros[4].position.x do
    coordinates[#coordinates + 1] = {x, bottom_y}
  end
  coordinates[#coordinates + 1] = furnace_heat_target
  local radiator_y = radiator_heat_target[2]
  while radiator_y > bottom_y do
    coordinates[#coordinates + 1] = {radiator_heat_target[1], radiator_y}
    radiator_y = radiator_y - 1
  end

  storage.heat_pipes = {}
  for _, position in ipairs(coordinates) do
    local pipe = place(surface, HEAT_PIPE, position)
    if not pipe then finish() return end
    storage.heat_pipes[#storage.heat_pipes + 1] = pipe
    check(close(pipe.temperature, 15), "heat pipe was not placed at engine-default temperature")
  end
  check(#storage.heat_pipes <= HEAT_PIPE_BUDGET,
    "runtime heat topology requires more than 30 heat pipes")
  check(#surface.find_entities_filtered{name = HEAT_INTERFACE} == 4,
    "four hydros did not create four owned heat interfaces")
  local initial_gas = 0
  for _, hydro in ipairs(storage.hydros) do
    initial_gas = initial_gas + hydro.get_fluid_count(GAS)
  end
  for _, entity in ipairs(storage.gas_entities) do
    initial_gas = initial_gas + entity.get_fluid_count(GAS)
  end
  check(close(initial_gas, 96),
    "pneumatic heat fixture did not start with exactly 96 compressed gas")
  for _, interface in ipairs(surface.find_entities_filtered{name = HEAT_INTERFACE}) do
    check(close(interface.temperature, 15),
      "owned pneumatic heat interface was preheated")
  end

  observations.initial = {
    heat_pipe_count = #storage.heat_pipes,
    furnace_temperature = storage.furnace.temperature,
    radiator_temperature = storage.radiator.temperature,
    owned_heat_interfaces = #surface.find_entities_filtered{name = HEAT_INTERFACE},
    compressed_gas = initial_gas,
    furnace_heat_target = furnace_heat_target,
    radiator_heat_target = radiator_heat_target,
  }
  check(close(storage.furnace.temperature, 15), "furnace was preheated")
  check(close(storage.radiator.temperature, 15), "radiator was preheated")
  if #failures > 0 then finish() return end
  for _, hydro in ipairs(storage.hydros) do hydro.active = true end
  storage.furnace.active = true
  storage.radiator.active = true
  script.on_nth_tick(TERMINAL_TICK, check_terminal)
end

script.on_nth_tick(1, setup)

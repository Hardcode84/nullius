return function(config)
local CASE = config.case
local RESULT = "factorio-tests/" .. CASE .. ".json"
local TECHNOLOGY = config.technology
local TRANSITION_INTERFACE = "nullius-test-transitions"
local TRANSFER_PERIOD = 60
local MACHINES_PER_CELL = config.machines_per_cell
local TIMEOUT_TICK = config.timeout_tick
local MIN_TEMPERATURE = config.min_temperature
local PRODUCTIVITY = config.productivity
local HEAT_SOURCE = config.heat_source
local HEAT_PIPE = config.heat_pipe
local SOURCE_FUEL = config.source_fuel
local SOURCE_FUEL_COUNT = config.source_fuel_count or 0
local cells = config.cells

local assertions = 0
local failures = {}
local observations = {cells = {}}

local function check(condition, message)
  assertions = assertions + 1
  if not condition then failures[#failures + 1] = message end
end

local function close(actual, expected)
  return math.abs(actual - expected) < 0.000001
end

local function inventory_counts(inventory)
  local result = {}
  for _, stack in pairs(inventory.get_contents()) do
    result[stack.name] = (result[stack.name] or 0) + stack.count
  end
  return result
end

local function check_exact(actual, expected, label)
  for name, value in pairs(expected) do
    check(actual[name] == value,
      label .. " expected " .. tostring(value) .. " " .. name ..
      ", found " .. tostring(actual[name]))
  end
  for name, value in pairs(actual) do
    check(expected[name] == value,
      label .. " contained unexpected " .. tostring(value) .. " " .. name)
  end
end

local function status_name(status)
  for name, value in pairs(defines.entity_status) do
    if value == status then return name end
  end
  return tostring(status)
end

local function finish()
  script.on_nth_tick(TRANSFER_PERIOD, nil)
  script.on_nth_tick(TIMEOUT_TICK, nil)
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

local function create(surface, parameters, label)
  local entity = surface.create_entity(parameters)
  check(entity ~= nil, "failed to place " .. label)
  return entity
end

local function connection_offset(direction)
  if direction == defines.direction.north then return 0, -1 end
  if direction == defines.direction.east then return 1, 0 end
  if direction == defines.direction.south then return 0, 1 end
  if direction == defines.direction.west then return -1, 0 end
  return nil, nil
end

local function heat_pipe_position(machine)
  local connections = machine.prototype.heat_energy_source_prototype.connections
  local connection = nil
  for _, candidate in pairs(connections) do
    if candidate.direction == defines.direction.west then
      connection = candidate
      break
    end
  end
  connection = connection or connections[1]
  check(connection ~= nil, machine.name .. " has no heat connection")
  if not connection then return nil end
  local dx, dy = connection_offset(connection.direction)
  check(dx ~= nil, machine.name .. " has an unsupported heat direction")
  if not dx then return nil end
  local position = connection.position
  return {
    machine.position.x + (position.x or position[1]) + dx,
    machine.position.y + (position.y or position[2]) + dy,
  }
end

local function transfer_inputs(cell)
  for machine_index, machine in ipairs(cell.machines) do
    local machine_inventory = machine.get_inventory(
      defines.inventory.assembling_machine_input)
    local chest_inventory = cell.input_chests[machine_index].get_inventory(
      defines.inventory.chest)
    for name in pairs(cell.inputs) do
      local available = chest_inventory.get_item_count(name)
      if available > 0 then
        local inserted = machine_inventory.insert{name = name, count = available}
        if inserted > 0 then
          check(chest_inventory.remove{name = name, count = inserted} == inserted,
            cell.id .. " input transfer mismatch for " .. name)
        end
      end
    end
  end
end

local function transfer_outputs(cell)
  local chest_inventory = cell.output_chest.get_inventory(defines.inventory.chest)
  for _, machine in ipairs(cell.machines) do
    local machine_inventory = machine.get_output_inventory()
    for _, stack in pairs(machine_inventory.get_contents()) do
      local inserted = chest_inventory.insert{name = stack.name, count = stack.count}
      check(inserted == stack.count,
        cell.id .. " output chest could not accept " .. stack.name)
      check(machine_inventory.remove{name = stack.name, count = inserted} == inserted,
        cell.id .. " output transfer mismatch for " .. stack.name)
    end
  end
end

local function inputs_empty(cell)
  for machine_index, machine in ipairs(cell.machines) do
    if not cell.input_chests[machine_index].get_inventory(
        defines.inventory.chest).is_empty() or
        not machine.get_inventory(
          defines.inventory.assembling_machine_input).is_empty() then
      return false
    end
  end
  return true
end

local function exact_outputs_ready(cell)
  local actual = inventory_counts(
    cell.output_chest.get_inventory(defines.inventory.chest))
  for name, count in pairs(cell.outputs) do
    if actual[name] ~= count then return false end
  end
  for name, count in pairs(actual) do
    if cell.outputs[name] ~= count then return false end
  end
  return true
end

local function terminal_check()
  local surface = game.surfaces.nauvis
  for _, cell in ipairs(cells) do
    transfer_outputs(cell)
    local output = inventory_counts(
      cell.output_chest.get_inventory(defines.inventory.chest))
    observations.cells[cell.id] = {machines = {}, output = output}
    for machine_index, machine in ipairs(cell.machines) do
      observations.cells[cell.id].machines[machine_index] = {
        entity = machine.name,
        temperature = machine.temperature,
        productivity_bonus = machine.productivity_bonus,
        products_finished = machine.products_finished,
      }
      check(machine.name == cell.base .. "-thermal",
        cell.id .. " machine " .. machine_index .. " left thermal mode")
      check(machine.temperature >= MIN_TEMPERATURE,
        cell.id .. " machine " .. machine_index ..
        " did not retain its working temperature")
      check(close(machine.productivity_bonus, PRODUCTIVITY),
        cell.id .. " machine " .. machine_index ..
        " productivity bonus differs from tier contract")
      check(machine.prototype.electric_energy_source_prototype == nil,
        cell.id .. " machine " .. machine_index ..
        " retained an electric energy source")
    end
    check(inputs_empty(cell), cell.id .. " did not consume all declared inputs")
    check_exact(output, cell.outputs, cell.id .. " output")

    for machine_index, machine in ipairs(cell.machines) do
      local position = machine.position
      remote.call(TRANSITION_INTERFACE, "execute", machine)
      local base = surface.find_entity(cell.base, position)
      check(base ~= nil, cell.id .. " machine " .. machine_index ..
        " base item was not preserved by transition")
    end
  end
  observations.heat_network = {
    sources = #storage.heat_sources,
    heat_pipes = #storage.heat_pipes,
  }
  check(#storage.heat_sources == #cells * MACHINES_PER_CELL,
    "heat-source count differs from cell contract")
  check(#storage.heat_pipes == #cells * MACHINES_PER_CELL,
    "heat-pipe count differs from cell contract")
  check(#storage.heat_pipes <= config.max_heat_pipes,
    "heat-pipe count exceeds fixture budget")
  for source_index, source in ipairs(storage.heat_sources) do
    check(source.name == HEAT_SOURCE,
      "heat source " .. source_index .. " changed prototype")
    check(source.temperature >= MIN_TEMPERATURE,
      "heat source " .. source_index .. " did not reach working temperature")
  end
  for pipe_index, pipe in ipairs(storage.heat_pipes) do
    check(pipe.name == HEAT_PIPE,
      "heat pipe " .. pipe_index .. " changed prototype")
    check(pipe.temperature >= MIN_TEMPERATURE,
      "heat pipe " .. pipe_index .. " did not reach working temperature")
  end
  finish()
end

local function service_cells()
  local complete = true
  for _, cell in ipairs(cells) do
    transfer_outputs(cell)
    transfer_inputs(cell)
    if not inputs_empty(cell) or not exact_outputs_ready(cell) then
      complete = false
    end
  end
  if #failures > 0 then finish() return end
  if complete then terminal_check() end
end

local function setup_cell(surface, force, cell)
  force.recipes[cell.base].enabled = true
  force.recipes[cell.recipe].enabled = true

  local output_chest = create(surface, {
    name = "steel-chest", position = {43, cell.row + 7}, force = force,
  }, cell.id .. " output chest")
  if not output_chest then return end

  cell.machines = {}
  cell.input_chests = {}
  for machine_index = 1, MACHINES_PER_CELL do
    local x = cell.machine_x + ((machine_index - 1) * 8)
    local input_chest = create(surface, {
      name = "steel-chest", position = {x, cell.row + 7}, force = force,
    }, cell.id .. " input chest " .. machine_index)
    if not input_chest then return end
    for name, count in pairs(cell.inputs) do
      local per_machine = count / MACHINES_PER_CELL
      check(per_machine == math.floor(per_machine),
        cell.id .. " input does not divide across machines: " .. name)
      check(input_chest.insert{name = name, count = per_machine} == per_machine,
        cell.id .. " input chest rejected " .. name)
    end

    local machine = create(surface, {
      name = cell.base,
      position = {x, cell.row + cell.machine_y_offset},
      force = force,
    }, cell.id .. " machine " .. machine_index)
    if not machine then return end
    check(machine.set_recipe(cell.recipe), cell.id .. " rejected its recipe")
    local machine_position = machine.position
    remote.call(TRANSITION_INTERFACE, "execute", machine)
    machine = surface.find_entity(cell.base .. "-thermal", machine_position)
    check(machine ~= nil, cell.id .. " machine " .. machine_index ..
      " did not enter thermal mode")
    if not machine then return end
    cell.machines[machine_index] = machine
    cell.input_chests[machine_index] = input_chest

    local pipe_position = heat_pipe_position(machine)
    if not pipe_position then return end
    local source = create(surface, {
      name = HEAT_SOURCE,
      position = {
        pipe_position[1] - config.source_connection_offset[1],
        pipe_position[2] - config.source_connection_offset[2],
      },
      force = force,
      raise_built = true,
    }, cell.id .. " heat source " .. machine_index)
    if source then
      storage.heat_sources[#storage.heat_sources + 1] = source
      if SOURCE_FUEL then
        local fuel_inventory = source.get_fuel_inventory()
        check(fuel_inventory ~= nil,
          cell.id .. " heat source has no fuel inventory")
        if fuel_inventory then
          check(fuel_inventory.insert{
            name = SOURCE_FUEL, count = SOURCE_FUEL_COUNT,
          } == SOURCE_FUEL_COUNT,
            cell.id .. " heat source rejected nuclear fuel")
        end
      end
    end

    local pipe = create(surface, {
      name = HEAT_PIPE,
      position = pipe_position,
      force = force,
    }, cell.id .. " heat pipe " .. machine_index)
    if pipe then storage.heat_pipes[#storage.heat_pipes + 1] = pipe end
  end

  cell.output_chest = output_chest
  transfer_inputs(cell)
end

local function timeout()
  script.on_nth_tick(TIMEOUT_TICK, nil)
  observations.timeout = {}
  for _, cell in ipairs(cells) do
    transfer_outputs(cell)
    local machines = {}
    for index, machine in ipairs(cell.machines) do
      machines[index] = {
        position = machine.position,
        temperature = machine.temperature,
        status = status_name(machine.status),
        recipe = machine.get_recipe() and machine.get_recipe().name,
        input = inventory_counts(machine.get_inventory(
          defines.inventory.assembling_machine_input)),
        products_finished = machine.products_finished,
      }
    end
    observations.timeout[cell.id] = {
      inputs_empty = inputs_empty(cell),
      output = inventory_counts(
        cell.output_chest.get_inventory(defines.inventory.chest)),
      machines = machines,
    }
  end
  observations.timeout.heat_sources = {}
  for index, source in ipairs(storage.heat_sources) do
    observations.timeout.heat_sources[index] = {
      name = source.name,
      position = source.position,
      temperature = source.temperature,
      fuel = source.get_fuel_inventory() and
        inventory_counts(source.get_fuel_inventory()) or {},
    }
  end
  observations.timeout.heat_pipes = {}
  for index, pipe in ipairs(storage.heat_pipes) do
    observations.timeout.heat_pipes[index] = {
      position = pipe.position,
      temperature = pipe.temperature,
    }
  end
  check(false, "thermal cell did not complete by tick " .. TIMEOUT_TICK)
  finish()
end

local function setup()
  script.on_nth_tick(1, nil)
  local surface = game.surfaces.nauvis
  local force = game.forces.player
  surface.request_to_generate_chunks({0, 0}, 2)
  surface.force_generate_chunk_requests()
  if config.freeze_daytime then
    surface.freeze_daytime = true
    surface.daytime = 0
  end
  for _, entity in ipairs(surface.find_entities_filtered{
      area = config.clear_area,
      type = {"simple-entity", "tree", "cliff", "resource"},
  }) do
    entity.destroy()
  end

  local technology = force.technologies[TECHNOLOGY]
  check(technology ~= nil, "missing " .. TECHNOLOGY)
  check(remote.interfaces[TRANSITION_INTERFACE] ~= nil,
    "transition test interface is missing")
  if not technology or not remote.interfaces[TRANSITION_INTERFACE] then
    finish()
    return
  end
  technology.researched = true
  storage.heat_sources = {}
  storage.heat_pipes = {}
  for _, cell in ipairs(cells) do setup_cell(surface, force, cell) end
  if #failures > 0 then finish() return end

  observations.initial = {}
  for _, cell in ipairs(cells) do
    observations.initial[cell.id] = {
      machines = #cell.machines,
      input_chests = #cell.input_chests,
    }
  end
  script.on_nth_tick(TRANSFER_PERIOD, service_cells)
  script.on_nth_tick(TIMEOUT_TICK, timeout)
end

script.on_nth_tick(1, setup)
end

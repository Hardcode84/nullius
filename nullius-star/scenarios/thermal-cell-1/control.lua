local CASE = "thermal-cell-1"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local TECHNOLOGY = "nullius-thermal-engineering-1"
local TRANSITION_INTERFACE = "nullius-test-transitions"
local TRANSFER_PERIOD = 60
local MACHINES_PER_CELL = 5
local TIMEOUT_TICK = 64000

local cells = {
  {
    id = "crusher",
    base = "nullius-crusher-1",
    recipe = "nullius-crushed-limestone",
    row = -12,
    machine_x = 3,
    machine_y_offset = 3,
    connection_x_offset = -1,
    collector_x_offset = -4,
    inputs = {['nullius-limestone'] = 800},
    outputs = {['nullius-crushed-limestone'] = 525, stone = 315},
  },
  {
    id = "furnace",
    base = "nullius-small-furnace-1",
    recipe = "nullius-aluminum-ingot",
    row = 0,
    machine_x = 3.5,
    machine_y_offset = 2.5,
    connection_x_offset = -0.5,
    collector_x_offset = -3.5,
    inputs = {['nullius-alumina'] = 900, ['nullius-graphite'] = 500},
    outputs = {
      ['nullius-aluminum-ingot'] = 315,
      ['nullius-aluminum-carbide'] = 420,
    },
  },
  {
    id = "foundry",
    base = "nullius-foundry-1",
    recipe = "nullius-iron-plate",
    row = 16,
    machine_x = 3,
    machine_y_offset = 3,
    connection_x_offset = -1,
    collector_x_offset = -4,
    inputs = {['nullius-iron-ingot'] = 400},
    outputs = {['nullius-iron-plate'] = 315},
  },
}

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
      check(machine.temperature >= 100,
        cell.id .. " machine " .. machine_index ..
        " did not retain its working temperature")
      check(close(machine.productivity_bonus, 0.05),
        cell.id .. " machine " .. machine_index ..
        " productivity bonus differs from 5 percent")
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
    collectors = #storage.collectors,
    heat_pipes = #storage.heat_pipes,
  }
  check(#storage.collectors == 15, "expected fifteen solar collectors")
  check(#storage.heat_pipes <= 30, "used more than 30 heat pipes")
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

    local collector = create(surface, {
      name = "nullius-solar-collector-1",
      position = {x + cell.collector_x_offset, cell.row + 0.5},
      force = force,
      raise_built = true,
    }, cell.id .. " solar collector " .. machine_index)
    if collector then storage.collectors[#storage.collectors + 1] = collector end

    local pipe = create(surface, {
      name = "nullius-heat-pipe-1",
      position = {x + cell.connection_x_offset, cell.row + 1},
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
        status = machine.status,
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
  observations.timeout.collectors = {}
  for index, collector in ipairs(storage.collectors) do
    observations.timeout.collectors[index] = {
      position = collector.position,
      temperature = collector.temperature,
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
  surface.freeze_daytime = true
  surface.daytime = 0
  for _, entity in ipairs(surface.find_entities_filtered{
      area = {{-18, -22}, {46, 26}},
      type = {"simple-entity", "tree", "cliff", "resource"},
  }) do
    entity.destroy()
  end

  local technology = force.technologies[TECHNOLOGY]
  check(technology ~= nil, "missing Thermal Engineering 1")
  check(remote.interfaces[TRANSITION_INTERFACE] ~= nil,
    "transition test interface is missing")
  if not technology or not remote.interfaces[TRANSITION_INTERFACE] then
    finish()
    return
  end
  technology.researched = true
  storage.collectors = {}
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

return function(CONFIG)
local CASE = CONFIG.case
local RESULT = "factorio-tests/" .. CASE .. ".json"
local CONTRACT = CONFIG.contract
local INITIAL_TECH = "nullius-pneumatic-technology"
local GAS = "nullius-compressed-volcanic-gas"
local HEAT_PIPE = "nullius-heat-pipe-1"
local BASE_X = 32
local MAX_STEP_WAIT = 72000
local POLL_TICKS = 30
local BACKGROUND_TICKS = 127
local CASE_DEADLINE = CONFIG.deadline

local FIXTURE = CONFIG.fixture

local HYDRO_FIXTURES = {
  {BASE_X - 4, -4}, {BASE_X + 4, -4},
  {BASE_X - 4, 4}, {BASE_X + 4, 4},
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
  return condition
end

local function close(actual, expected)
  return math.abs((actual or 0) - (expected or 0)) < 0.00001
end

local function status_name(status)
  for name, value in pairs(defines.entity_status) do
    if value == status then return name end
  end
  return tostring(status)
end

local function add(values, name, amount)
  values[name] = (values[name] or 0) + amount
  if close(values[name], 0) then values[name] = nil end
end

local function copy_map(values)
  local result = {}
  for name, amount in pairs(values) do result[name] = amount end
  return result
end

local function consume(values, name, amount, label)
  local available = values[name] or 0
  if not check(available + 0.00001 >= amount,
      label .. " requires " .. amount .. " " .. name ..
      ", ledger has " .. available) then
    return false
  end
  add(values, name, -amount)
  return true
end

local function finish()
  script.on_nth_tick(CASE_DEADLINE, nil)
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

local function build(name, position, direction)
  local ghost = storage.surface.create_entity{
    name = "entity-ghost",
    inner_name = name,
    position = position,
    direction = direction or defines.direction.north,
    force = game.forces.player,
    expires = false,
  }
  if not check(ghost ~= nil, "failed to create ghost for " .. name) then return nil end
  local _, entity = ghost.revive{raise_revive = true}
  check(entity ~= nil, "failed to revive " .. name)
  return entity
end

local function place(name, position)
  local entity = storage.surface.create_entity{
    name = name,
    position = position,
    force = game.forces.player,
  }
  check(entity ~= nil,
    "failed to place " .. name .. " at [" .. position[1] .. "," .. position[2] .. "]")
  return entity
end

local function heat_target(machine)
  local source = machine.prototype.heat_energy_source_prototype
  if not check(source ~= nil, machine.name .. " has no heat energy source") then return nil end
  if not check(#source.connections > 0, machine.name .. " has no heat connection") then return nil end
  local connection = source.connections[1]
  local outward = DIRECTION_OFFSET[connection.direction]
  if not check(outward ~= nil, machine.name .. " heat connection is not cardinal") then return nil end
  if machine.direction == defines.direction.south then
    return {
      machine.position.x - connection.position[1] - outward[1],
      machine.position.y - connection.position[2] - outward[2],
    }
  end
  if machine.direction == defines.direction.west then
    local dx = connection.position[1] + outward[1]
    local dy = connection.position[2] + outward[2]
    return {machine.position.x + dy, machine.position.y - dx}
  end
  return {
    machine.position.x + connection.position[1] + outward[1],
    machine.position.y + connection.position[2] + outward[2],
  }
end

local function consume_build_item(item)
  if (storage.fixture_remaining[item] or 0) >= 1 then
    storage.fixture_remaining[item] = storage.fixture_remaining[item] - 1
    storage.fixture_placed[item] = (storage.fixture_placed[item] or 0) + 1
    return true
  end
  if consume(storage.ledger, item, 1, "placing executor") then
    storage.production_placed[item] = (storage.production_placed[item] or 0) + 1
    return true
  end
  return false
end

local function register_machine(entity)
  storage.machines[entity.name] = storage.machines[entity.name] or {}
  storage.machines[entity.name][#storage.machines[entity.name] + 1] = entity
  entity.active = false
end

local function build_executor(item, name, position)
  if not consume_build_item(item) then return nil end
  local entity
  if name == "nullius-lava-intake-1" then
    local valid_position = storage.surface.find_non_colliding_position(
      item, {80, -32}, 48, 1)
    if not check(valid_position ~= nil, "no valid lava-intake shoreline position") then
      return nil
    end
    local ghost = storage.surface.create_entity{
      name = "entity-ghost",
      inner_name = item,
      position = valid_position,
      direction = defines.direction.north,
      force = game.forces.player,
      expires = false,
    }
    if not check(ghost ~= nil, "failed to create lava-intake source ghost") then
      return nil
    end
    ghost.revive{raise_revive = true}
    local converted = storage.surface.find_entities_filtered{
      name = name, position = valid_position, radius = 2,
    }
    check(#converted == 1, "seawater intake did not convert to one lava intake")
    entity = converted[1]
  else
    entity = build(name, position)
  end
  if entity then register_machine(entity) end
  return entity
end

local function ensure_machine(executor)
  local pool = storage.machines[executor.name]
  if pool and #pool > 0 then
    local next_index = (storage.machine_cursor[executor.name] or 0) % #pool + 1
    storage.machine_cursor[executor.name] = next_index
    return pool[next_index]
  end
  local position
  if executor.name == "nullius-vulcanus-radiator-1" then
    position = {BASE_X, 9}
  else
    local index = storage.executor_count
    storage.executor_count = index + 1
    position = {80 + (index % 5) * 12, -24 + math.floor(index / 5) * 12}
  end
  local machine = build_executor(executor.item, executor.name, position)
  if machine and executor.name == "nullius-vulcanus-radiator-1" then
    local target = heat_target(machine)
    check(target and close(target[1], storage.radiator_heat_target[1]) and
      close(target[2], storage.radiator_heat_target[2]),
      "crafted radiator did not align with its prebuilt heat branch")
    check(target and #storage.surface.find_entities_filtered{
      name = HEAT_PIPE, position = target, radius = 0.1} == 1,
      "crafted radiator heat connection has no heat pipe")
  end
  return machine
end

local function insert_machine_item(machine, name, amount)
  local inserted = machine.insert{name = name, count = amount}
  return check(inserted == amount,
    machine.name .. " accepted " .. inserted .. "/" .. amount .. " " .. name)
end

local function fluid_box(machine, name, role)
  local fallback = nil
  if role == "fuel" then
    for index = 1, #machine.fluidbox do
      local filter = machine.fluidbox.get_filter(index)
      if not filter then return index end
    end
  end
  for index = 1, #machine.fluidbox do
    local filter = machine.fluidbox.get_filter(index)
    local prototype = machine.fluidbox.get_prototype(index)
    local production_type = prototype and prototype.production_type or "none"
    if filter and filter.name == name then
      if role == "input" and production_type ~= "output" then return index end
      if role == "output" and production_type ~= "input" then return index end
      fallback = fallback or index
    end
  end
  return fallback
end

local function fluid_box_state(machine)
  local state = {}
  for index = 1, #machine.fluidbox do
    local filter = machine.fluidbox.get_filter(index)
    local prototype = machine.fluidbox.get_prototype(index)
    local contents = machine.fluidbox[index]
    state[index] = {
      filter = filter and filter.name or nil,
      production_type = prototype and prototype.production_type or nil,
      fluid = contents and contents.name or nil,
      amount = contents and contents.amount or 0,
    }
  end
  return state
end

local function insert_machine_fluid(machine, name, amount, role)
  local index = fluid_box(machine, name, role)
  if not check(index ~= nil,
      machine.name .. " has no " .. role .. " fluid box for " .. name) then return nil end
  local current = machine.fluidbox[index]
  local current_amount = current and current.amount or 0
  machine.fluidbox[index] = {
    name = name,
    amount = current_amount + amount,
    temperature = prototypes.fluid[name].default_temperature,
  }
  local stored = machine.fluidbox[index]
  if not check(stored and close(stored.amount, current_amount + amount),
      machine.name .. " failed to store " .. amount .. " " .. name ..
      " in " .. role .. " box " .. index) then return nil end
  return index
end

local function collect_machine_item(machine, name, amount)
  local output = machine.get_output_inventory()
  local removed = output and output.remove{name = name, count = amount} or 0
  check(removed == amount,
    machine.name .. " produced " .. removed .. "/" .. amount .. " " .. name)
  return removed
end


local function collect_machine_fluid(machine, name, amount)
  local index = fluid_box(machine, name, "output")
  if not check(index ~= nil, machine.name .. " has no output fluid box for " .. name) then
    return 0
  end
  local contents = machine.fluidbox[index]
  local available = contents and contents.name == name and contents.amount or 0
  local removed = math.min(available, amount)
  local remaining = available - removed
  machine.fluidbox[index] = (remaining > 0) and {
    name = name,
    amount = remaining,
    temperature = contents.temperature,
  } or nil
  check(close(removed, amount),
    machine.name .. " produced " .. removed .. "/" .. amount .. " " .. name)
  return removed
end

local advance
local start_background_gas

local function fill_pending_fuel(active)
  if not active.fuel_box or active.fuel_pending <= 0 then return end
  local machine = active.machine
  local contents = machine.fluidbox[active.fuel_box]
  local current = contents and contents.amount or 0
  local capacity = machine.fluidbox.get_capacity(active.fuel_box)
  local amount = math.min(active.fuel_pending, capacity - current)
  if amount > 0 then
    local stored = insert_machine_fluid(machine, active.step.fuel.name, amount, "fuel")
    if stored then active.fuel_pending = active.fuel_pending - amount end
  end
end

local function record_outputs(step, divisor, collector)
  for _, output in ipairs(step.outputs) do
    local amount = output.amount / divisor
    local collected = collector(output.name, amount, output.type)
    add(storage.ledger, output.name, collected)
    add(storage.produced, output.name, collected)
  end
end

local function machine_cycle_complete()
  script.on_nth_tick(game.tick, nil)
  local active = storage.active
  local machine = active.machine
  local step = active.step
  if step.heat and machine.products_finished > active.products_finished and
      storage.background_gas then
    script.on_nth_tick(game.tick + POLL_TICKS, machine_cycle_complete)
    return
  end
  if machine.products_finished <= active.products_finished then
    fill_pending_fuel(active)
    if game.tick >= active.deadline then
      check(false, "step " .. step.producer .. " did not complete one cycle; status=" ..
        status_name(machine.status) .. ", temperature=" .. tostring(machine.temperature) ..
        ", fluids=" .. helpers.table_to_json(machine.get_fluid_contents()) ..
        ", boxes=" .. helpers.table_to_json(fluid_box_state(machine)) ..
        ", gas_cycles=" .. tostring(storage.completed_cycles[storage.gas_step_index]) ..
        ", heat=" .. helpers.table_to_json((function()
          local values = {}
          for _, entity in ipairs(storage.surface.find_entities_filtered{
              type = {"heat-interface", "heat-pipe"}}) do
            values[#values + 1] = {name = entity.name, position = entity.position,
              temperature = entity.temperature}
          end
          return values
        end)()))
      finish()
      return
    end
    script.on_nth_tick(game.tick + active.poll_ticks, machine_cycle_complete)
    return
  end
  machine.active = false
  record_outputs(step, step.cycles, function(name, amount, kind)
    if kind == "fluid" then return collect_machine_fluid(machine, name, amount) end
    return collect_machine_item(machine, name, amount)
  end)
  if step.fuel then
    local box = active.fuel_box
    local contents = box and machine.fluidbox[box]
    local returned = contents and contents.name == step.fuel.name and contents.amount or 0
    if returned > 0 then
      machine.fluidbox[box] = nil
      add(storage.ledger, step.fuel.name, returned)
      add(storage.fuel_consumed, step.fuel.name, -returned)
    end
    if active.fuel_pending > 0 then
      add(storage.ledger, step.fuel.name, active.fuel_pending)
      add(storage.fuel_consumed, step.fuel.name, -active.fuel_pending)
    end
  end
  active.cycle = active.cycle + 1
  storage.completed_cycles[active.step_index] = active.cycle - 1
  storage.active = nil
  advance()
end

local function background_gas_complete()
  script.on_nth_tick(BACKGROUND_TICKS, nil)
  local backgrounds = storage.background_gas
  if not backgrounds then return end
  local step = CONTRACT.steps[storage.gas_step_index]
  for _, background in ipairs(backgrounds) do
    if background.machine.products_finished <= background.products_finished then
      script.on_nth_tick(BACKGROUND_TICKS, background_gas_complete)
      return
    end
  end
  for _, background in ipairs(backgrounds) do
    local machine = background.machine
    machine.active = false
    record_outputs(step, step.cycles, function(name, amount, kind)
      if kind == "fluid" then return collect_machine_fluid(machine, name, amount) end
      return collect_machine_item(machine, name, amount)
    end)
    local contents = machine.fluidbox[background.fuel_box]
    local returned = contents and contents.name == step.fuel.name and contents.amount or 0
    if returned > 0 then
      machine.fluidbox[background.fuel_box] = nil
      add(storage.ledger, step.fuel.name, returned)
      add(storage.fuel_consumed, step.fuel.name, -returned)
    end
    storage.completed_cycles[storage.gas_step_index] =
      (storage.completed_cycles[storage.gas_step_index] or 0) + 1
  end
  storage.background_gas = nil
  local heat_active = storage.active and storage.active.step.heat and
    storage.active.machine.products_finished <= storage.active.products_finished
  if heat_active then start_background_gas() end
end

start_background_gas = function()
  local step = CONTRACT.steps[storage.gas_step_index]
  if (storage.completed_cycles[storage.gas_step_index] or 0) >= step.cycles then return end
  local pool = storage.machines[step.executor.name]
  if not pool then return end
  local lava = step.ingredients[1].amount / step.cycles
  local fuel = step.fuel.amount_per_cycle
  local backgrounds = {}
  for _, machine in ipairs(pool) do
    if (storage.completed_cycles[storage.gas_step_index] or 0) + #backgrounds >=
        step.cycles then break end
    if (storage.ledger[step.ingredients[1].name] or 0) < lava or
        (storage.ledger[step.fuel.name] or 0) < fuel then break end
    consume(storage.ledger, step.ingredients[1].name, lava, "background gas heat")
    consume(storage.ledger, step.fuel.name, fuel, "background gas heat fuel")
    check(machine.set_recipe(step.producer), "failed to set background gas recipe")
    insert_machine_fluid(machine, step.ingredients[1].name, lava, "input")
    local fuel_box = insert_machine_fluid(machine, step.fuel.name, fuel, "fuel")
    add(storage.fuel_consumed, step.fuel.name, fuel)
    backgrounds[#backgrounds + 1] = {
      machine = machine,
      products_finished = machine.products_finished,
      fuel_box = fuel_box,
    }
    machine.active = true
  end
  if #backgrounds == 0 then return end
  storage.background_gas = backgrounds
  script.on_nth_tick(BACKGROUND_TICKS, background_gas_complete)
end

local function start_machine_cycle(step)
  local active = storage.active
  local machine = active.machine
  local cycle_label = step.producer .. " cycle " .. active.cycle
  check(machine.set_recipe(step.producer), "failed to set recipe " .. step.producer)
  for _, ingredient in ipairs(step.ingredients) do
    local amount = ingredient.amount / step.cycles
    if not consume(storage.ledger, ingredient.name, amount, cycle_label) then finish() return end
    if ingredient.type == "fluid" then
      if not insert_machine_fluid(machine, ingredient.name, amount, "input") then
        finish() return
      end
    else
      if not insert_machine_item(machine, ingredient.name, amount) then finish() return end
    end
  end
  if step.fuel then
    local amount = step.fuel.amount_per_cycle
    if not consume(storage.ledger, step.fuel.name, amount, cycle_label .. " fuel") then
      finish() return
    end
    active.fuel_box = fluid_box(machine, step.fuel.name, "fuel")
    if not check(active.fuel_box ~= nil,
        machine.name .. " has no fuel fluid box for " .. step.fuel.name) then
      finish() return
    end
    active.fuel_pending = amount
    local capacity = machine.fluidbox.get_capacity(active.fuel_box)
    active.poll_ticks = math.max(POLL_TICKS,
      math.floor(step.ticks_per_cycle * capacity / amount * 0.75))
    fill_pending_fuel(active)
    add(storage.fuel_consumed, step.fuel.name, amount)
  else
    active.poll_ticks = POLL_TICKS
  end
  active.products_finished = machine.products_finished
  active.deadline = game.tick + MAX_STEP_WAIT
  machine.active = true
  local first_check = step.ticks_per_cycle + 2
  if step.fuel and active.fuel_pending > 0 then
    first_check = math.min(first_check, active.poll_ticks)
  end
  script.on_nth_tick(game.tick + first_check, machine_cycle_complete)
  if step.heat then start_background_gas() end
end

local function character_cycle_complete()
  script.on_nth_tick(game.tick, nil)
  local active = storage.active
  local player = storage.player
  if player.crafting_queue_size > 0 then
    if game.tick >= active.deadline then
      check(false, "handcraft " .. active.step.producer .. " did not complete")
      finish()
      return
    end
    script.on_nth_tick(game.tick + POLL_TICKS, character_cycle_complete)
    return
  end
  record_outputs(active.step, active.step.cycles, function(name, amount, kind)
    if kind == "fluid" then
      check(false, "character recipe produced fluid " .. name)
      return 0
    end
    local removed = player.remove_item{name = name, count = amount}
    check(removed == amount,
      "handcraft produced " .. removed .. "/" .. amount .. " " .. name)
    return removed
  end)
  active.cycle = active.cycle + 1
  storage.completed_cycles[active.step_index] = active.cycle - 1
  storage.active = nil
  advance()
end

local function start_character_cycle(step)
  local label = step.producer .. " cycle " .. storage.active.cycle
  for _, ingredient in ipairs(step.ingredients) do
    if ingredient.type ~= "item" then
      check(false, "character recipe has fluid ingredient " .. ingredient.name)
      finish()
      return
    end
    local amount = ingredient.amount / step.cycles
    if not consume(storage.ledger, ingredient.name, amount, label) then finish() return end
    local inserted = storage.player.insert{name = ingredient.name, count = amount}
    if not check(inserted == amount,
        "character accepted " .. inserted .. "/" .. amount .. " " .. ingredient.name) then
      finish() return
    end
  end
  local crafted = storage.player.begin_crafting{count = 1, recipe = step.producer}
  if not check(crafted == 1, "failed to handcraft " .. step.producer) then finish() return end
  storage.active.deadline = game.tick + MAX_STEP_WAIT
  script.on_nth_tick(game.tick + step.ticks_per_cycle + 2, character_cycle_complete)
end

local function spoil_complete()
  script.on_nth_tick(game.tick, nil)
  local active = storage.active
  local step = active.step
  record_outputs(step, 1, function(name, amount, kind)
    if kind ~= "item" then
      check(false, "spoil step produced fluid " .. name)
      return 0
    end
    local removed = active.chest.remove_item{name = name, count = amount}
    check(removed == amount,
      "spoil step produced " .. removed .. "/" .. amount .. " " .. name)
    return removed
  end)
  active.chest.destroy()
  storage.completed_cycles[active.step_index] = step.cycles
  storage.active = nil
  advance()
end

local function start_spoil(step)
  local ingredient = step.ingredients[1]
  if not consume(storage.ledger, ingredient.name, ingredient.amount,
      step.producer) then finish() return end
  local chest = place("steel-chest", {160 + storage.active.step_index * 2, 24})
  if not chest then finish() return end
  local inserted = chest.insert{name = ingredient.name, count = ingredient.amount}
  if not check(inserted == ingredient.amount,
      "spoil chest accepted " .. inserted .. "/" .. ingredient.amount ..
      " " .. ingredient.name) then finish() return end
  storage.active.chest = chest
  script.on_nth_tick(game.tick + step.spoil_ticks + 1, spoil_complete)
end

local function check_exact_map(actual, expected, label)
  for name, amount in pairs(expected) do
    check(close(actual[name], amount),
      label .. " expected " .. amount .. " " .. name ..
      ", found " .. tostring(actual[name] or 0))
  end
  for name, amount in pairs(actual) do
    check(expected[name] ~= nil and close(amount, expected[name]),
      label .. " contained unexpected " .. amount .. " " .. name)
  end
end

local function check_terminal()
  local expected_produced = {}
  for _, step in ipairs(CONTRACT.steps) do
    for _, output in ipairs(step.outputs) do add(expected_produced, output.name, output.amount) end
  end
  local expected_ledger = {}
  for name, amount in pairs(CONTRACT.targets) do add(expected_ledger, name, amount) end
  for name, amount in pairs(CONTRACT.surplus) do add(expected_ledger, name, amount) end
  for name, amount in pairs(storage.production_placed) do add(expected_ledger, name, -amount) end

  check_exact_map(storage.produced, expected_produced, "produced")
  check_exact_map(storage.ledger, expected_ledger, "terminal ledger")
  check_exact_map(storage.fuel_consumed, CONTRACT.fuel_consumption, "fuel consumption")
  for item, count in pairs(FIXTURE) do
    check((storage.fixture_remaining[item] or 0) + (storage.fixture_placed[item] or 0) == count,
      "fixture conservation failed for " .. item)
  end
  local completed_steps = 0
  for index, step in ipairs(CONTRACT.steps) do
    if storage.completed_cycles[index] == step.cycles then
      completed_steps = completed_steps + 1
    end
  end
  check(completed_steps == #CONTRACT.steps,
    "completed " .. completed_steps .. "/" .. #CONTRACT.steps .. " steps")
  check((storage.fixture_placed[HEAT_PIPE] or 0) <= FIXTURE[HEAT_PIPE],
    "heat topology exceeded landing heat-pipe stock")
  local heat_interfaces = storage.surface.find_entities_filtered{type = "heat-interface"}
  check(#heat_interfaces >= 4,
    "heat topology lost one or more landing pneumatic heat interfaces")
  for _, interface in ipairs(heat_interfaces) do
    check(string.find(interface.name, "^nullius%-pneumatic%-heat%-") ~= nil,
      "heat topology contains a debug heat interface: " .. interface.name)
  end

  observations.terminal = {
    elapsed_ticks = game.tick - storage.started_tick,
    selected_steps = #CONTRACT.steps,
    produced = storage.produced,
    ledger = storage.ledger,
    fuel_consumed = storage.fuel_consumed,
    fixture_placed = storage.fixture_placed,
    production_placed = storage.production_placed,
  }
  finish()
end

local function step_ready(step)
  if storage.background_gas and step.producer == "nullius-lava-gas-extraction" then
    return false
  end
  local divisor = step.spoil_ticks and 1 or step.cycles
  for _, ingredient in ipairs(step.ingredients) do
    if (storage.ledger[ingredient.name] or 0) + 0.00001 <
        ingredient.amount / divisor then return false end
  end
  if step.fuel and (storage.ledger[step.fuel.name] or 0) + 0.00001 <
      step.fuel.amount_per_cycle then return false end
  if step.fuel and step.producer ~= "nullius-lava-gas-extraction" and
      (storage.completed_cycles[storage.gas_step_index] or 0) <
        CONTRACT.steps[storage.gas_step_index].cycles and
      (storage.ledger[step.fuel.name] or 0) + 0.00001 <
        step.fuel.amount_per_cycle + 24 then return false end
  if step.executor and step.executor.kind == "machine" then
    local pool = storage.machines[step.executor.name]
    if not pool or #pool == 0 then
      local item = step.executor.item
      if (storage.fixture_remaining[item] or 0) < 1 and
          (storage.ledger[item] or 0) < 1 then return false end
    end
  end
  return true
end

advance = function()
  if #failures > 0 then finish() return end
  local selected_index = nil
  local gas_index = nil
  local lava_index = nil
  local complete = true
  for index, candidate in ipairs(CONTRACT.steps) do
    local completed = storage.completed_cycles[index] or 0
    if completed < candidate.cycles then
      complete = false
      if step_ready(candidate) then
        selected_index = index
        if candidate.producer == "nullius-lava-gas-extraction" then gas_index = index end
        if candidate.producer == "nullius-lava-pumping" then lava_index = index end
      end
    end
  end
  if not storage.gas_bootstrapped then
    selected_index = gas_index or lava_index or selected_index
  end
  if complete then check_terminal() return end
  if not selected_index then
    check(false, "production manifest reached a material or executor deadlock")
    finish()
    return
  end
  local step = CONTRACT.steps[selected_index]
  if step.producer == "nullius-lava-gas-extraction" then
    storage.gas_bootstrapped = true
  end
  storage.active = {
    step = step,
    step_index = selected_index,
    cycle = (storage.completed_cycles[selected_index] or 0) + 1,
  }
  if step.spoil_ticks then start_spoil(step) return end
  if step.executor.kind == "machine" then
    local machine = ensure_machine(step.executor)
    if not machine then finish() return end
    storage.active.machine = machine
    if step.heat then machine.temperature = step.heat.maximum_temperature end
  end
  if step.executor.kind == "character" then
    start_character_cycle(step)
  else
    start_machine_cycle(step)
  end
end

local function setup_heat_fixture()
  local hydros = {}
  for _, position in ipairs(HYDRO_FIXTURES) do
    local hydro = build_executor("nullius-hydro-plant-1",
      "nullius-hydro-plant-1-pneumatic", position)
    if not hydro then return false end
    hydros[#hydros + 1] = hydro
  end
  local furnace = build_executor("nullius-small-furnace-1",
    "nullius-small-furnace-1-pneumatic", {BASE_X, -4})
  if not furnace then return false end
  local furnace_target = heat_target(furnace)
  if not furnace_target then return false end

  local coordinates = {}
  local top_y = hydros[1].position.y - 3
  local bottom_y = hydros[3].position.y - 3
  for x = hydros[1].position.x, hydros[2].position.x do
    coordinates[#coordinates + 1] = {x, top_y}
  end
  for x = hydros[3].position.x, hydros[4].position.x do
    coordinates[#coordinates + 1] = {x, bottom_y}
  end
  coordinates[#coordinates + 1] = furnace_target
  local radiator_source = prototypes.entity["nullius-vulcanus-radiator-1"]
    .heat_energy_source_prototype
  local radiator_ghost = storage.surface.create_entity{
    name = "entity-ghost",
    inner_name = "nullius-vulcanus-radiator-1",
    position = {BASE_X, 9},
    direction = defines.direction.north,
    force = game.forces.player,
    expires = false,
  }
  if not check(radiator_ghost ~= nil, "failed to plan radiator heat branch") then
    return false
  end
  local radiator_position = radiator_ghost.position
  radiator_ghost.destroy()
  local connection = radiator_source.connections[1]
  local outward = DIRECTION_OFFSET[connection.direction]
  local radiator_target = {
    radiator_position.x + connection.position[1] + outward[1],
    radiator_position.y + connection.position[2] + outward[2],
  }
  storage.radiator_heat_target = radiator_target
  local radiator_y = radiator_target[2]
  while radiator_y > bottom_y do
    coordinates[#coordinates + 1] = {radiator_target[1], radiator_y}
    radiator_y = radiator_y - 1
  end
  for _, position in ipairs(coordinates) do
    if not consume_build_item(HEAT_PIPE) then return false end
    local pipe = place(HEAT_PIPE, position)
    if not pipe then return false end
    pipe.temperature = 250
  end
  local heat_interfaces = storage.surface.find_entities_filtered{type = "heat-interface"}
  check(#heat_interfaces == 4,
    "heat fixture must contain exactly four owned pneumatic heat interfaces")
  for _, interface in ipairs(heat_interfaces) do interface.temperature = 500 end
  check(#coordinates == 27, "heat fixture must place exactly 27 heat pipes")
  return true
end

local function setup()
  script.on_nth_tick(1, nil)
  check(CONTRACT.schema == 1, "unsupported manifest schema")
  local planet = game.planets["nullius-vulcanus"]
  if not check(planet ~= nil, "missing nullius-vulcanus planet") then finish() return end
  local surface = planet.surface or planet.create_surface()
  if not check(surface ~= nil, "failed to create Vulcanus surface") then finish() return end
  storage.surface = surface
  surface.request_to_generate_chunks({80, 0}, 5)
  surface.force_generate_chunk_requests()
  local tiles = {}
  for x = 0, 220 do
    for y = -48, 48 do
      tiles[#tiles + 1] = {
        name = (y <= -32) and "lava-hot" or "volcanic-soil-dark",
        position = {x, y},
      }
    end
  end
  surface.set_tiles(tiles, true, false, false, false)
  for _, entity in ipairs(surface.find_entities_filtered{
      area = {{0, -48}, {220, 48}},
      type = {"simple-entity", "tree", "cliff", "resource"},
  }) do entity.destroy() end

  local technology = game.forces.player.technologies[INITIAL_TECH]
  if not check(technology ~= nil, "missing initial pneumatic technology") then finish() return end
  local researched = {}
  research_closure(technology, researched)
  for _, name in ipairs(CONTRACT.assumed_technologies) do
    check(researched[name] == true, "manifest assumed technology outside initial closure: " .. name)
  end
  for _, step in ipairs(CONTRACT.steps) do
    if not step.spoil_ticks then
      check(game.forces.player.recipes[step.producer] and
        game.forces.player.recipes[step.producer].enabled,
        "manifest recipe is not enabled: " .. step.producer)
    end
  end

  storage.player = surface.create_entity{
    name = "character",
    position = {0, 0},
    force = game.forces.player,
  }
  if not check(storage.player ~= nil, "failed to create crafting character") then
    finish() return
  end
  storage.fixture_remaining = copy_map(FIXTURE)
  storage.fixture_placed = {}
  storage.production_placed = {}
  storage.ledger = {}
  storage.produced = {}
  storage.fuel_consumed = {}
  storage.machines = {}
  storage.machine_cursor = {}
  storage.executor_count = 0
  storage.completed_cycles = {}
  for index, step in ipairs(CONTRACT.steps) do
    if step.producer == "nullius-lava-gas-extraction" then
      storage.gas_step_index = index
    end
  end
  check(storage.gas_step_index ~= nil, "manifest has no gas-bootstrap step")
  for name, amount in pairs(CONTRACT.raw_inputs) do add(storage.ledger, name, amount) end
  for name, amount in pairs(CONTRACT.initial_stock) do add(storage.ledger, name, amount) end

  if not setup_heat_fixture() then finish() return end
  observations.initial = {
    fixture = FIXTURE,
    raw_inputs = CONTRACT.raw_inputs,
    initial_stock = CONTRACT.initial_stock,
    selected_steps = #CONTRACT.steps,
    heat_pipes = storage.fixture_placed[HEAT_PIPE],
    heat_pipe_temperature = 250,
    pneumatic_heat_temperature = 500,
    heat_mode = "scripted-preheat-per-cycle",
  }
  if #failures > 0 then finish() return end
  storage.started_tick = game.tick
  advance()
end

local function deadline()
  if game.tick < CASE_DEADLINE then return end
  script.on_nth_tick(CASE_DEADLINE, nil)
  local completed_steps = 0
  for index, step in ipairs(CONTRACT.steps) do
    if (storage.completed_cycles[index] or 0) == step.cycles then
      completed_steps = completed_steps + 1
    end
  end
  local active = storage.active
  check(false, "production manifest exceeded tick budget; completed_steps=" ..
    completed_steps .. "/" .. #CONTRACT.steps ..
    ", active=" .. tostring(active and active.step.producer) ..
    ", active_cycle=" .. tostring(active and active.cycle) ..
    ", gas_cycles=" .. tostring(storage.completed_cycles[storage.gas_step_index]))
  finish()
end

script.on_nth_tick(1, setup)
script.on_nth_tick(CASE_DEADLINE, deadline)
end

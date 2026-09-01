local CASE = "experiment-pneumatic-roboport"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local PORT = "factorio-test-pneumatic-roboport"
local RESERVOIR = "factorio-test-pneumatic-roboport-reservoir"
local GAS = "nullius-compressed-volcanic-gas"
local ROBOT = "nullius-construction-bot-1"
local NUM_BUCKETS = 443
local IDLE_USAGE = 200000
local CHARGING_SLOTS = 4
local CHARGING_USAGE_PER_SLOT = 450000

local assertions = 0
local failures = {}
local observations = {
  bucket_count = NUM_BUCKETS,
  refill_ticks = {},
  charging_ticks = 0,
}

local function check(condition, message)
  assertions = assertions + 1
  if not condition then failures[#failures + 1] = message end
end

local function finish()
  if storage.finished then return end
  storage.finished = true
  observations.final_port_energy = storage.port and storage.port.valid and
    storage.port.energy or nil
  observations.final_gas = storage.reservoir and storage.reservoir.valid and
    storage.reservoir.get_fluid_count(GAS) or nil
  observations.final_robot_energy = storage.robot and storage.robot.valid and
    storage.robot.energy or nil
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

local function refill()
  if not storage.refill_enabled or not storage.port.valid or
      not storage.reservoir.valid then return end
  if game.tick % NUM_BUCKETS ~= storage.bucket then return end

  local capacity = storage.port.prototype.electric_energy_source_prototype.buffer_capacity
  local deficit = math.max(0, capacity - storage.port.energy)
  local requested = deficit / storage.fuel_value
  local removed = storage.reservoir.remove_fluid{name = GAS, amount = requested}
  storage.port.energy = storage.port.energy + removed * storage.fuel_value
  observations.refill_ticks[#observations.refill_ticks + 1] = game.tick
  observations.last_refill_gas = removed
end

local function setup()
  local surface = game.surfaces.nauvis
  surface.request_to_generate_chunks({0, 0}, 2)
  surface.force_generate_chunk_requests()
  for _, entity in pairs(surface.find_entities_filtered{area = {{-16, -16}, {16, 16}}}) do
    if entity.valid and entity.type ~= "character" then entity.destroy() end
  end

  local power = surface.create_entity{
    name = "electric-energy-interface", position = {7, 0},
    force = game.forces.player,
  }
  local pole = surface.create_entity{
    name = "substation", position = {3, 0}, force = game.forces.player,
  }
  storage.port = surface.create_entity{
    name = PORT, position = {0, 0}, force = game.forces.player,
  }
  storage.reservoir = surface.create_entity{
    name = RESERVOIR, position = {0, 0}, force = game.forces.player,
  }
  check(power ~= nil, "failed to create electric grid source")
  check(pole ~= nil, "failed to create electric grid pole")
  check(storage.port ~= nil, "failed to create experiment roboport")
  check(storage.reservoir ~= nil, "failed to create experiment gas reservoir")
  if not power or not pole or not storage.port or not storage.reservoir then
    finish()
    return
  end

  power.power_production = 1000000000
  power.electric_buffer_size = 1000000000
  power.energy = 1000000000
  storage.port.energy = 0
  storage.bucket = storage.port.unit_number % NUM_BUCKETS
  storage.fuel_value = prototypes.fluid[GAS].fuel_value
  check(storage.fuel_value == 20000,
    "unexpected compressed volcanic gas fuel value: " .. storage.fuel_value)
  observations.bucket = storage.bucket
  observations.buffer_capacity =
    storage.port.prototype.electric_energy_source_prototype.buffer_capacity
  observations.input_flow_limit =
    storage.port.prototype.electric_energy_source_prototype.get_input_flow_limit()
  observations.worst_case_interval_energy =
    (IDLE_USAGE + CHARGING_SLOTS * CHARGING_USAGE_PER_SLOT) *
    NUM_BUCKETS / 60
  check(observations.input_flow_limit == 0,
    "experiment roboport prototype still accepts grid power")
  check(observations.buffer_capacity >= observations.worst_case_interval_energy,
    "roboport buffer cannot cover one fully loaded amortization interval")
  storage.phase = "grid_isolation"
  storage.phase_tick = game.tick
end

local function update()
  if storage.finished or not storage.phase then return end
  refill()

  if storage.port.valid and storage.port.logistic_cell and
      storage.port.logistic_cell.charging_robot_count > 0 then
    observations.charging_ticks = observations.charging_ticks + 1
  end

  if storage.phase == "grid_isolation" and game.tick >= storage.phase_tick + 90 then
    observations.grid_isolated_energy = storage.port.energy
    check(storage.port.energy == 0,
      "zero-input roboport drew energy from a live electric grid")
    local inserted = storage.reservoir.insert_fluid{
      name = GAS, amount = 2000, temperature = 200,
    }
    check(inserted == 2000, "failed to fill experiment gas reservoir")
    storage.robot = storage.port.surface.create_entity{
      name = ROBOT, position = {0, 4}, force = game.forces.player,
    }
    check(storage.robot ~= nil, "failed to create construction robot")
    if not storage.robot then finish() return end
    storage.robot.energy = 1
    observations.robot_energy_before_charge = storage.robot.energy
    storage.refill_enabled = true
    storage.phase = "await_charge"
    storage.phase_tick = game.tick

  elseif storage.phase == "await_charge" then
    if storage.robot.valid and storage.robot.energy > 100000 then
      observations.robot_energy_after_charge = storage.robot.energy
      observations.gas_after_charge = storage.reservoir.get_fluid_count(GAS)
      check(#observations.refill_ticks >= 1,
        "robot charged before the amortized gas refill ran")
      check(observations.gas_after_charge < 2000,
        "robot charging did not consume compressed volcanic gas")
      check(observations.charging_ticks > 0,
        "roboport never reported a charging robot")

      storage.refill_enabled = false
      storage.reservoir.clear_fluid_inside()
      storage.port.energy = 100000
      storage.robot.energy = 1
      storage.phase = "await_blackout"
      storage.phase_tick = game.tick
    elseif game.tick > storage.phase_tick + NUM_BUCKETS * 3 then
      check(false, "robot did not charge after three bucket intervals")
      finish()
    end

  elseif storage.phase == "await_blackout" and
      game.tick >= storage.phase_tick + 180 then
    observations.blackout_port_energy = storage.port.energy
    observations.blackout_robot_energy = storage.robot.valid and
      storage.robot.energy or nil
    check(storage.port.energy == 0,
      "roboport buffer did not drain after gas starvation")
    storage.blackout_robot_energy = storage.robot.valid and storage.robot.energy or 0
    storage.phase = "confirm_blackout"
    storage.phase_tick = game.tick

  elseif storage.phase == "confirm_blackout" and
      game.tick >= storage.phase_tick + 90 then
    check(storage.robot.valid, "construction robot disappeared during blackout")
    if storage.robot.valid then
      check(storage.robot.energy <= storage.blackout_robot_energy,
        "robot gained energy while the roboport was blacked out")
    end
    local inserted = storage.reservoir.insert_fluid{
      name = GAS, amount = 2000, temperature = 200,
    }
    check(inserted == 2000, "failed to restore experiment gas")
    storage.refill_enabled = true
    storage.recovery_energy = storage.robot.valid and storage.robot.energy or 0
    storage.phase = "await_recovery"
    storage.phase_tick = game.tick

  elseif storage.phase == "await_recovery" then
    if storage.robot.valid and storage.robot.energy > storage.recovery_energy + 100000 then
      observations.recovery_robot_energy = storage.robot.energy
      check(#observations.refill_ticks >= 2,
        "robot recovered without a second amortized refill")
      if #observations.refill_ticks >= 2 then
        local delta = observations.refill_ticks[#observations.refill_ticks] -
          observations.refill_ticks[#observations.refill_ticks - 1]
        observations.refill_interval = delta
        check(delta % NUM_BUCKETS == 0,
          "refills did not remain in the assigned amortization bucket")
      end
      finish()
    elseif game.tick > storage.phase_tick + NUM_BUCKETS * 3 then
      check(false, "robot charging did not recover after gas restoration")
      finish()
    end
  end
end

script.on_nth_tick(1, function()
  script.on_nth_tick(1, nil)
  setup()
end)
script.on_event(defines.events.on_tick, update)

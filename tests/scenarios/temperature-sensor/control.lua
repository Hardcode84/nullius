local CASE = "temperature-sensor"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local SENSOR = "nullius-temperature-sensor"
local PNEUMATIC = "nullius-pneumatic-technology"
local RED = defines.wire_connector_id.circuit_red
local TEMPERATURE = {type = "virtual", name = "signal-T"}

local assertions = 0
local failures = {}
local observations = {}

local function check(condition, message)
  assertions = assertions + 1
  if not condition then failures[#failures + 1] = message end
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

local function verify()
  script.on_nth_tick(120, nil)

  local sensor = storage.sensor
  local isolated = storage.isolated
  check(sensor.valid, "connected sensor was destroyed")
  check(isolated.valid, "isolated sensor was destroyed")
  if not sensor.valid or not isolated.valid then finish() return end

  local signal = sensor.get_signal(TEMPERATURE, RED)
  observations.connected_temperature = sensor.temperature
  observations.circuit_signal = signal
  observations.isolated_temperature = isolated.temperature

  check(sensor.temperature > 390,
    "sensor did not receive heat from the connected heat source")
  check(math.abs(signal - sensor.temperature) < 1,
    "circuit signal does not report the sensor temperature")
  check(isolated.temperature < 15.01,
    "the engine-required 1W reactor consumption materially heated an isolated sensor")

  finish()
end

local function setup()
  script.on_nth_tick(1, nil)

  local entity_prototype = prototypes.entity[SENSOR]
  local item_prototype = prototypes.item[SENSOR]
  local recipe = prototypes.recipe[SENSOR]
  local boxed_recipe = prototypes.recipe["nullius-boxed-temperature-sensor"]
  local technology = prototypes.technology[PNEUMATIC]
  check(entity_prototype ~= nil, "missing temperature sensor entity")
  check(item_prototype ~= nil, "missing temperature sensor item")
  check(recipe ~= nil, "missing temperature sensor recipe")
  check(boxed_recipe ~= nil, "missing boxed temperature sensor recipe")
  check(technology ~= nil, "missing pneumatic technology")
  if not entity_prototype or not item_prototype or not recipe or
      not boxed_recipe or not technology then finish() return end

  check(entity_prototype.type == "reactor",
    "temperature sensor does not use native reactor circuit behavior")
  check(entity_prototype.tile_width == 1 and entity_prototype.tile_height == 1,
    "temperature sensor is not 1x1")
  check(item_prototype.place_result and item_prototype.place_result.name == SENSOR,
    "temperature sensor item does not place its entity")

  local force = game.forces.player
  force.technologies[PNEUMATIC].researched = false
  check(not force.recipes[SENSOR].enabled,
    "temperature sensor recipe is enabled before pneumatic technology")
  check(not force.recipes["nullius-boxed-temperature-sensor"].enabled,
    "boxed temperature sensor recipe is enabled before pneumatic technology")
  force.technologies[PNEUMATIC].researched = true
  check(force.recipes[SENSOR].enabled,
    "pneumatic technology did not unlock the temperature sensor")
  check(force.recipes["nullius-boxed-temperature-sensor"].enabled,
    "pneumatic technology did not unlock the boxed temperature sensor")
  check(force.recipes["nullius-box-temperature-sensor"].enabled,
    "pneumatic technology did not unlock temperature sensor boxing")
  check(force.recipes["nullius-unbox-temperature-sensor"].enabled,
    "pneumatic technology did not unlock temperature sensor unboxing")

  local surface = game.surfaces[1]
  local source = surface.create_entity{
    name = "heat-interface",
    position = {0, -1},
    force = force,
  }
  local sensor = surface.create_entity{
    name = SENSOR,
    position = {0, 0},
    force = force,
  }
  local isolated = surface.create_entity{
    name = SENSOR,
    position = {8, 0},
    force = force,
  }
  local sink = surface.create_entity{
    name = "constant-combinator",
    position = {2, 0},
    force = force,
  }
  check(source ~= nil, "failed to place heat source")
  check(sensor ~= nil, "failed to place connected temperature sensor")
  check(isolated ~= nil, "failed to place isolated temperature sensor")
  check(sink ~= nil, "failed to place circuit sink")
  if not source or not sensor or not isolated or not sink then finish() return end

  source.set_heat_setting{temperature = 400, mode = "exactly"}
  local behavior = sensor.get_or_create_control_behavior()
  check(behavior ~= nil, "temperature sensor has no reactor control behavior")
  if not behavior then finish() return end
  behavior.read_temperature = true
  check(behavior.temperature_signal and
      behavior.temperature_signal.name == "signal-T",
    "temperature sensor does not default to signal T")

  local sensor_connector = sensor.get_wire_connector(RED, true)
  local sink_connector = sink.get_wire_connector(RED, true)
  check(sensor_connector ~= nil, "temperature sensor has no red connector")
  check(sink_connector ~= nil, "circuit sink has no red connector")
  if not sensor_connector or not sink_connector then finish() return end
  check(sensor_connector.connect_to(sink_connector),
    "failed to connect temperature sensor to circuit network")

  storage.sensor = sensor
  storage.isolated = isolated
  script.on_nth_tick(120, verify)
end

script.on_nth_tick(1, setup)

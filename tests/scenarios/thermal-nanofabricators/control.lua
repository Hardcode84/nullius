local CASE = "thermal-nanofabricators"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local SPECS = {
  {
    base = "nullius-nanofabricator-1",
    energy_ratio = 2,
    min_temperature = 200,
    max_temperature = 500,
  },
  {
    base = "nullius-nanofabricator-2",
    energy_ratio = 2,
    min_temperature = 500,
    max_temperature = 1500,
  },
}

local assertions = 0
local failures = {}
local observations = {machines = {}}

local function check(condition, message)
  assertions = assertions + 1
  if not condition then failures[#failures + 1] = message end
end

local function close(actual, expected)
  return math.abs(actual - expected) < 0.000001
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

local function values_to_set(values)
  local result = {}
  for key, value in pairs(values or {}) do
    if type(key) == "number" then result[value] = true
    elseif value then result[key] = true end
  end
  return result
end

local function check_same_set(actual, expected, label)
  actual = values_to_set(actual)
  expected = values_to_set(expected)
  for name in pairs(expected) do
    check(actual[name], label .. " omitted " .. name)
  end
  for name in pairs(actual) do
    check(expected[name], label .. " added " .. name)
  end
end

local function toggle(entity)
  check(remote.interfaces["nullius-test-transitions"] ~= nil,
    "transition test interface is missing")
  if remote.interfaces["nullius-test-transitions"] then
    return remote.call("nullius-test-transitions", "execute", entity)
  end
  return false
end

local function connection_offset(direction)
  if direction == defines.direction.north then return 0, -1 end
  if direction == defines.direction.east then return 1, 0 end
  if direction == defines.direction.south then return 0, 1 end
  if direction == defines.direction.west then return -1, 0 end
  return nil, nil
end

local function connect_heat(surface, machine, spec)
  local connections = machine.prototype.heat_energy_source_prototype.connections
  local connection = connections[1]
  check(connection ~= nil, machine.name .. " has no heat connection")
  if not connection then return end
  local dx, dy = connection_offset(connection.direction)
  check(dx ~= nil, machine.name .. " has unsupported heat direction")
  if not dx then return end
  local offset = connection.position
  local pipe_position = {
    machine.position.x + (offset.x or offset[1]) + dx,
    machine.position.y + (offset.y or offset[2]) + dy,
  }
  local pipe = surface.create_entity{
    name = (spec.max_temperature == 500) and
      "nullius-heat-pipe-2" or "nullius-heat-pipe-3",
    position = pipe_position,
    force = machine.force,
  }
  check(pipe ~= nil, machine.name .. " heat pipe did not fit")
  if not pipe then return end
  local source = surface.create_entity{
    name = "heat-interface",
    position = {pipe_position[1] + dx, pipe_position[2] + dy},
    force = machine.force,
  }
  check(source ~= nil, machine.name .. " heat source did not fit")
  if source then
    source.set_heat_setting{temperature = spec.max_temperature, mode = "at-least"}
  end
end

local function input_fluid_box(machine, fluid_name)
  local fallback = nil
  for index = 1, #machine.fluidbox do
    local prototype = machine.fluidbox.get_prototype(index)
    if prototype and prototype.production_type ~= "output" then
      local filter = machine.fluidbox.get_filter(index)
      if filter and filter.name == fluid_name then return index end
      fallback = fallback or index
    end
  end
  return fallback
end

local function validate_prototype(spec)
  local base = prototypes.entity[spec.base]
  local thermal = prototypes.entity[spec.base .. "-thermal"]
  check(base ~= nil, spec.base .. " base prototype is missing")
  check(thermal ~= nil, spec.base .. " thermal prototype is missing")
  if not base or not thermal then return end

  check_same_set(thermal.crafting_categories, base.crafting_categories,
    spec.base .. " crafting categories")
  check_same_set(thermal.allowed_effects, base.allowed_effects,
    spec.base .. " allowed effects")
  check(close(thermal.get_crafting_speed(), base.get_crafting_speed()),
    spec.base .. " crafting speed changed")
  check(thermal.module_inventory_size == base.module_inventory_size,
    spec.base .. " module inventory changed")
  check(close(thermal.get_max_energy_usage(),
      base.get_max_energy_usage() * spec.energy_ratio),
    spec.base .. " energy usage is not doubled")
  check(thermal.electric_energy_source_prototype == nil,
    spec.base .. " thermal mode retained electric power")
  local heat = thermal.heat_energy_source_prototype
  check(heat ~= nil, spec.base .. " thermal mode has no heat source")
  if heat then
    check(close(heat.min_working_temperature, spec.min_temperature),
      spec.base .. " has wrong minimum temperature")
    check(close(heat.max_temperature, spec.max_temperature),
      spec.base .. " has wrong maximum temperature")
    check(#heat.connections > 0, spec.base .. " has no heat connections")
  end
  check((thermal.effect_receiver == nil) == (base.effect_receiver == nil),
    spec.base .. " thermal mode changed effect-receiver presence")
  if thermal.effect_receiver and base.effect_receiver then
    for _, effect in ipairs{
        "consumption", "speed", "productivity", "pollution", "quality"} do
      check(close(thermal.effect_receiver.base_effect[effect] or 0,
          base.effect_receiver.base_effect[effect] or 0),
        spec.base .. " thermal mode changed innate " .. effect)
    end
  end
  check(#thermal.items_to_place_this == 1 and
      thermal.items_to_place_this[1].name == spec.base,
    spec.base .. " thermal mode requires another item")
  check(thermal.mineable_properties.products[1].name == spec.base,
    spec.base .. " thermal mode mines to another item")
end

local function terminal_check()
  script.on_nth_tick(2300, nil)
  for _, spec in ipairs(SPECS) do
    local machine = storage.machines[spec.base]
    check(machine and machine.valid, spec.base .. " thermal machine disappeared")
    if machine and machine.valid then
      observations.machines[spec.base] = {
        prototype = machine.name,
        temperature = machine.temperature,
        energy_usage = machine.prototype.get_max_energy_usage(),
      }
      check(machine.temperature >= spec.min_temperature,
        spec.base .. " did not reach its working temperature")
      if spec.base == "nullius-nanofabricator-1" then
        local output = machine.get_output_inventory()
        local produced = output.get_item_count("nullius-monocrystalline-silicon")
        observations.machines[spec.base].monocrystalline_silicon = produced
        check(produced >= 3,
          spec.base .. " did not complete nanotechnology recipe using heat")
      end
      local position = machine.position
      local surface = machine.surface
      toggle(machine)
      check(surface.find_entity(spec.base, position) ~= nil,
        spec.base .. " did not return to electric mode")
    end
  end
  finish()
end

local function setup()
  script.on_nth_tick(1, nil)
  local force = game.forces.player
  local planet = game.planets["nullius-vulcanus"]
  local surface = planet.surface or planet.create_surface()
  surface.request_to_generate_chunks({0, 0}, 3)
  surface.force_generate_chunk_requests()
  for _, entity in ipairs(surface.find_entities_filtered{
      area = {{-32, -20}, {32, 20}},
      type = {"simple-entity", "tree", "cliff", "resource"},
  }) do entity.destroy() end

  storage.machines = {}
  for index, spec in ipairs(SPECS) do
    validate_prototype(spec)
    local recipe = force.recipes[spec.base]
    check(recipe ~= nil, "missing placement recipe " .. spec.base)
    if not recipe then finish() return end
    recipe.enabled = false
    local position = {(index == 1) and -10 or 10, 0}
    local base = surface.create_entity{
      name = spec.base, position = position, force = force,
    }
    check(base ~= nil, "failed to place " .. spec.base)
    if not base then finish() return end
    if spec.base == "nullius-nanofabricator-1" then
      local process = force.recipes["nullius-monocrystalline-silicon"]
      check(process ~= nil, "missing monocrystalline silicon recipe")
      if not process then finish() return end
      process.enabled = true
      base.set_recipe(process)
      local input = base.get_inventory(defines.inventory.assembling_machine_input)
      check(input.insert{name = "nullius-polycrystalline-silicon", count = 5} == 5,
        "failed to insert polycrystalline silicon")
      local argon_box = input_fluid_box(base, "nullius-argon")
      check(argon_box ~= nil, "nanofabricator has no argon input fluid box")
      if not argon_box then finish() return end
      base.fluidbox[argon_box] = {
        name = "nullius-argon",
        amount = 10,
        temperature = prototypes.fluid["nullius-argon"].default_temperature,
      }
    end
    toggle(base)
    check(base.valid and base.name == spec.base,
      spec.base .. " entered thermal mode before recipe unlock")
    recipe.enabled = true
    toggle(base)
    local thermal = surface.find_entity(spec.base .. "-thermal", position)
    check(thermal ~= nil, spec.base .. " did not enter thermal mode on Vulcanus")
    if thermal then
      storage.machines[spec.base] = thermal
      if spec.base == "nullius-nanofabricator-1" then
        check(thermal.get_recipe() and
            thermal.get_recipe().name == "nullius-monocrystalline-silicon",
          "thermal transition did not preserve nanotechnology recipe")
        check(thermal.get_inventory(
            defines.inventory.assembling_machine_input).get_item_count(
              "nullius-polycrystalline-silicon") == 5,
          "thermal transition did not preserve solid recipe input")
        local argon_box = input_fluid_box(thermal, "nullius-argon")
        local argon = argon_box and thermal.fluidbox[argon_box]
        check(argon and argon.name == "nullius-argon" and argon.amount == 10,
          "thermal transition did not preserve argon recipe input")
      end
      connect_heat(surface, thermal, spec)
    end
  end

  local nauvis = game.surfaces.nauvis
  local witness = nauvis.create_entity{
    name = "nullius-nanofabricator-1", position = {0, 0}, force = force,
  }
  check(witness ~= nil, "failed to place Nauvis transition witness")
  if witness then
    toggle(witness)
    check(witness.valid and witness.name == "nullius-nanofabricator-1",
      "nanofabricator entered Vulcanus thermal mode on Nauvis")
  end

  if #failures > 0 then finish() return end
  script.on_nth_tick(2300, terminal_check)
end

script.on_nth_tick(1, setup)

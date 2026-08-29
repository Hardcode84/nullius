local CASE = "thermal-machines-higher-tiers"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local TIERS = {
  {
    tier = 2,
    technology = "nullius-thermal-engineering-2",
    heat_pipe = "nullius-heat-pipe-2",
    min_temperature = 200,
    max_temperature = 500,
    productivity = 0.10,
    machines = {
      "nullius-crusher-2",
      "nullius-small-furnace-2",
      "nullius-medium-furnace-2",
      "nullius-large-furnace-2",
      "nullius-foundry-2",
    },
  },
  {
    tier = 3,
    technology = "nullius-thermal-engineering-3",
    heat_pipe = "nullius-heat-pipe-3",
    min_temperature = 500,
    max_temperature = 1500,
    productivity = 0.15,
    machines = {
      "nullius-crusher-3",
      "nullius-small-furnace-3",
      "nullius-medium-furnace-3",
      "nullius-foundry-3",
    },
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
    if type(key) == "number" then
      result[value] = true
    elseif value then
      result[key] = true
    end
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

local function toggle(entity)
  check(remote.interfaces["nullius-test-transitions"] ~= nil,
    "transition test interface is missing")
  if remote.interfaces["nullius-test-transitions"] then
    remote.call("nullius-test-transitions", "execute", entity)
  end
end

local function validate_prototype(base_name, tier)
  local base = prototypes.entity[base_name]
  local thermal = prototypes.entity[base_name .. "-thermal"]
  check(base ~= nil, base_name .. " base prototype is missing")
  check(thermal ~= nil, base_name .. " thermal prototype is missing")
  if not base or not thermal then return end

  check_exact(values_to_set(thermal.crafting_categories),
    values_to_set(base.crafting_categories),
    base_name .. " crafting categories")
  check_exact(values_to_set(thermal.allowed_effects),
    values_to_set(base.allowed_effects), base_name .. " allowed effects")
  check(close(thermal.get_crafting_speed(), base.get_crafting_speed()),
    base_name .. " crafting speed changed")
  check(thermal.module_inventory_size == base.module_inventory_size,
    base_name .. " module inventory size changed")
  check(close(thermal.get_max_energy_usage(), base.get_max_energy_usage()),
    base_name .. " energy usage changed")
  check(thermal.electric_energy_source_prototype == nil,
    base_name .. " retained its electric energy source")

  local heat = thermal.heat_energy_source_prototype
  check(heat ~= nil, base_name .. " has no heat energy source")
  if heat then
    check(close(heat.min_working_temperature, tier.min_temperature),
      base_name .. " has wrong minimum temperature")
    check(close(heat.max_temperature, tier.max_temperature),
      base_name .. " has wrong maximum temperature")
    check(#heat.connections > 0,
      base_name .. " has no heat connections")
  end
  check(thermal.effect_receiver ~= nil,
    base_name .. " has no effect receiver")
  if thermal.effect_receiver then
    check(close(thermal.effect_receiver.base_effect.productivity,
        tier.productivity),
      base_name .. " has wrong innate productivity")
  end
  check(#thermal.items_to_place_this == 1 and
      thermal.items_to_place_this[1].name == base_name,
    base_name .. " requires a separate thermal item")
  check(thermal.mineable_properties.products[1].name == base_name,
    base_name .. " mines to the wrong item")
end

local function connection_offset(direction)
  if direction == defines.direction.north then return 0, -1 end
  if direction == defines.direction.east then return 1, 0 end
  if direction == defines.direction.south then return 0, 1 end
  if direction == defines.direction.west then return -1, 0 end
  return nil, nil
end

local function connect_heat(surface, machine, tier)
  local connections = machine.prototype.heat_energy_source_prototype.connections
  local connection = connections[1]
  check(connection ~= nil, machine.name .. " has no runtime heat connection")
  if not connection then return end
  local dx, dy = connection_offset(connection.direction)
  check(dx ~= nil, machine.name .. " has unsupported heat direction")
  if not dx then return end

  local pipe_position = {
    machine.position.x + (connection.position.x or connection.position[1]) + dx,
    machine.position.y + (connection.position.y or connection.position[2]) + dy,
  }
  local pipe = surface.create_entity{
    name = tier.heat_pipe,
    position = pipe_position,
    force = machine.force,
  }
  check(pipe ~= nil, machine.name .. " heat pipe did not fit its connection")
  if not pipe then return end
  local source = surface.create_entity{
    name = "heat-interface",
    position = {pipe_position[1] + dx, pipe_position[2] + dy},
    force = machine.force,
  }
  check(source ~= nil, machine.name .. " heat source could not be placed")
  if source then
    source.set_heat_setting{
      temperature = tier.max_temperature,
      mode = "at-least",
    }
  end
end

local function surface_witnesses(force, tier)
  local base_name = "nullius-crusher-" .. tier.tier
  local other = game.surfaces["thermal-other-" .. tier.tier] or
    game.create_surface("thermal-other-" .. tier.tier)
  other.request_to_generate_chunks({0, 0}, 1)
  other.force_generate_chunk_requests()
  local other_machine = other.create_entity{
    name = base_name, position = {0, 0}, force = force,
  }
  check(other_machine ~= nil, "failed to place tier " .. tier.tier ..
    " other-surface witness")
  if other_machine then
    toggle(other_machine)
    check(other_machine.valid and other_machine.name == base_name,
      base_name .. " transitioned outside Nauvis")
  end

  force.technologies["nullius-pneumatic-technology"].researched = true
  local planet = game.planets["nullius-vulcanus"]
  local vulcanus = planet.surface or planet.create_surface()
  vulcanus.request_to_generate_chunks({tier.tier * 12, 0}, 1)
  vulcanus.force_generate_chunk_requests()
  local vulcanus_machine = vulcanus.create_entity{
    name = base_name, position = {tier.tier * 12, 0}, force = force,
  }
  check(vulcanus_machine ~= nil, "failed to place " .. base_name ..
    " Vulcanus witness")
  if vulcanus_machine then
    local position = vulcanus_machine.position
    toggle(vulcanus_machine)
    check(vulcanus.find_entity(base_name .. "-pneumatic", position) ~= nil,
      base_name .. " toggled to thermal instead of pneumatic on Vulcanus")
  end
end

local function warmed_check()
  script.on_nth_tick(120, nil)
  local surface = game.surfaces.nauvis
  for base_name, machine in pairs(storage.machines) do
    observations.machines[base_name] = {
      prototype = machine.name,
      temperature = machine.temperature,
      productivity_bonus = machine.productivity_bonus,
    }
    check(machine.temperature > 15,
      base_name .. " did not receive heat through its connection")
    local position = machine.position
    toggle(machine)
    check(surface.find_entity(base_name, position) ~= nil,
      base_name .. " did not return to electric mode")
  end
  finish()
end

local function setup()
  script.on_nth_tick(1, nil)
  local surface = game.surfaces.nauvis
  local force = game.forces.player
  surface.request_to_generate_chunks({0, 0}, 3)
  surface.force_generate_chunk_requests()
  for _, entity in ipairs(surface.find_entities_filtered{
      area = {{-42, -24}, {42, 24}},
      type = {"simple-entity", "tree", "cliff", "resource"},
  }) do
    entity.destroy()
  end

  storage.machines = {}
  for tier_index, tier in ipairs(TIERS) do
    local technology = force.technologies[tier.technology]
    check(technology ~= nil, "missing " .. tier.technology)
    if not technology then finish() return end
    technology.researched = false

    local y = (tier_index == 1) and -10 or 10
    for machine_index, base_name in ipairs(tier.machines) do
      validate_prototype(base_name, tier)
      local recipe = force.recipes[base_name]
      check(recipe ~= nil, "missing placement recipe " .. base_name)
      if not recipe then finish() return end
      recipe.enabled = true
      local x = (machine_index - (#tier.machines + 1) / 2) * 14
      local machine = surface.create_entity{
        name = base_name, position = {x, y}, force = force,
      }
      check(machine ~= nil, "failed to place " .. base_name)
      if not machine then finish() return end
      toggle(machine)
      check(machine.valid and machine.name == base_name,
        base_name .. " entered thermal mode before research")
    end

    technology.researched = true
    for machine_index, base_name in ipairs(tier.machines) do
      local x = (machine_index - (#tier.machines + 1) / 2) * 14
      local position = {x, y}
      local machine = surface.find_entity(base_name, position)
      local recipe = force.recipes[base_name]
      recipe.enabled = false
      toggle(machine)
      check(machine.valid and machine.name == base_name,
        base_name .. " ignored its placement-recipe gate")
      recipe.enabled = true
      toggle(machine)
      local thermal = surface.find_entity(base_name .. "-thermal", position)
      check(thermal ~= nil, base_name .. " did not enter thermal mode")
      if thermal then
        storage.machines[base_name] = thermal
        connect_heat(surface, thermal, tier)
      end
    end
    surface_witnesses(force, tier)
  end

  if #failures > 0 then finish() return end
  script.on_nth_tick(120, warmed_check)
end

script.on_nth_tick(1, setup)

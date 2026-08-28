local CASE = "thermal-machines-1"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local TECHNOLOGY = "nullius-thermal-engineering-1"

local cases = {
  {
    id = "crusher",
    base = "nullius-crusher-1",
    recipe = "nullius-crushed-limestone",
    position = {-16, 0},
    heat_pipe_offset = {-1, -2},
    inputs = {["nullius-limestone"] = 8},
    outputs = {["nullius-crushed-limestone"] = 5, stone = 3},
  },
  {
    id = "furnace",
    base = "nullius-small-furnace-1",
    recipe = "nullius-aluminum-ingot",
    position = {0, 0},
    heat_pipe_offset = {-0.5, -1.5},
    inputs = {["nullius-alumina"] = 9, ["nullius-graphite"] = 5},
    outputs = {
      ["nullius-aluminum-ingot"] = 3,
      ["nullius-aluminum-carbide"] = 4,
    },
  },
  {
    id = "foundry",
    base = "nullius-foundry-1",
    recipe = "nullius-iron-plate",
    position = {16, 0},
    heat_pipe_offset = {-1, -2},
    inputs = {["nullius-iron-ingot"] = 4},
    outputs = {["nullius-iron-plate"] = 3},
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

local function inventory_counts(inventory)
  local result = {}
  for _, stack in pairs(inventory.get_contents()) do
    result[stack.name] = (result[stack.name] or 0) + stack.count
  end
  return result
end

local function toggle(entity)
  check(remote.interfaces["nullius-test-transitions"] ~= nil,
    "transition test interface is missing")
  if remote.interfaces["nullius-test-transitions"] then
    remote.call("nullius-test-transitions", "execute", entity)
  end
end

local function entity_at(surface, name, position)
  return surface.find_entity(name, position)
end

local function validate_prototype(test)
  local base = prototypes.entity[test.base]
  local thermal = prototypes.entity[test.base .. "-thermal"]
  check(base ~= nil, test.id .. " base prototype is missing")
  check(thermal ~= nil, test.id .. " thermal prototype is missing")
  if not base or not thermal then return end

  check_exact(values_to_set(thermal.crafting_categories),
    values_to_set(base.crafting_categories), test.id .. " crafting categories")
  check_exact(values_to_set(thermal.allowed_effects),
    values_to_set(base.allowed_effects), test.id .. " allowed effects")
  check(close(thermal.get_crafting_speed(), base.get_crafting_speed()),
    test.id .. " crafting speed changed")
  check(thermal.module_inventory_size == base.module_inventory_size,
    test.id .. " module inventory size changed")
  check(close(thermal.get_max_energy_usage(), base.get_max_energy_usage()),
    test.id .. " energy usage changed")
  check(thermal.electric_energy_source_prototype == nil,
    test.id .. " thermal variant retained electric energy source")
  local heat = thermal.heat_energy_source_prototype
  check(heat ~= nil, test.id .. " thermal variant has no heat energy source")
  if heat then
    check(close(heat.min_working_temperature, 100),
      test.id .. " minimum working temperature differs from 100 C")
    check(close(heat.max_temperature, 250),
      test.id .. " maximum temperature differs from 250 C")
  end
  check(thermal.effect_receiver ~= nil,
    test.id .. " thermal variant has no effect receiver")
  if thermal.effect_receiver then
    check(close(thermal.effect_receiver.base_effect.productivity, 0.05),
      test.id .. " innate productivity differs from 5 percent")
  end
  check(#thermal.items_to_place_this == 1,
    test.id .. " thermal variant has wrong place-item count")
  if #thermal.items_to_place_this == 1 then
    check(thermal.items_to_place_this[1].name == test.base,
      test.id .. " thermal variant requires a separate item")
  end
  check(thermal.mineable_properties.products[1].name == test.base,
    test.id .. " thermal variant mines to the wrong item")
end

local function check_production()
  script.on_nth_tick(3600, nil)
  for _, test in ipairs(cases) do
    local machine = storage.machines[test.id]
    local input_inventory = machine.get_inventory(
      defines.inventory.assembling_machine_input)
    local output_inventory = machine.get_output_inventory()
    local outputs = inventory_counts(output_inventory)
    observations.machines[test.id] = {
      temperature = machine.temperature,
      productivity_bonus = machine.productivity_bonus,
      products_finished = machine.products_finished,
      inputs = inventory_counts(input_inventory),
      outputs = outputs,
    }
    check(machine.name == test.base .. "-thermal",
      test.id .. " machine left thermal mode")
    check(machine.temperature >= 100,
      test.id .. " machine never reached working temperature")
    check(close(machine.productivity_bonus, 0.05),
      test.id .. " runtime productivity bonus differs from 5 percent")
    check(machine.products_finished == 1,
      test.id .. " did not finish exactly one recipe cycle")
    check_exact(inventory_counts(input_inventory), {}, test.id .. " input")
    check_exact(outputs, test.outputs, test.id .. " output")
    local position = machine.position
    local surface = machine.surface
    toggle(machine)
    local electric = entity_at(surface, test.base, position)
    check(electric ~= nil, test.id .. " did not return to electric mode")
    if electric then
      check_exact(inventory_counts(electric.get_output_inventory()), test.outputs,
        test.id .. " output after electric transition")
    end
  end
  finish()
end

local function connect_heat()
  script.on_nth_tick(5, nil)
  local surface = game.surfaces.nauvis
  for _, test in ipairs(cases) do
    local machine = storage.machines[test.id]
    check(close(machine.temperature, 15),
      test.id .. " warmed before delayed heat connection")
    local pipe_position = {
      machine.position.x + test.heat_pipe_offset[1],
      machine.position.y + test.heat_pipe_offset[2],
    }
    local pipe = surface.create_entity{
      name = "nullius-heat-pipe-1",
      position = pipe_position,
      force = game.forces.player,
    }
    check(pipe ~= nil, test.id .. " heat pipe did not connect at expected box edge")
    local source = surface.create_entity{
      name = "heat-interface",
      position = {pipe_position[1], pipe_position[2] - 1},
      force = game.forces.player,
    }
    check(source ~= nil, test.id .. " debug heat source could not be placed")
    if source then source.set_heat_setting{temperature = 250, mode = "at-least"} end
    machine.active = true
  end
  if #failures > 0 then finish() return end
  script.on_nth_tick(3600, check_production)
end

local function prepare_vulcanus(force)
  force.technologies["nullius-pneumatic-technology"].researched = true
  local planet = game.planets["nullius-vulcanus"]
  local surface = planet.surface or planet.create_surface()
  surface.request_to_generate_chunks({0, 0}, 1)
  surface.force_generate_chunk_requests()
  local tiles = {}
  for x = -8, 8 do
    for y = -8, 8 do
      tiles[#tiles + 1] = {name = "volcanic-soil-dark", position = {x, y}}
    end
  end
  surface.set_tiles(tiles, true, false, false, false)
  for _, entity in ipairs(surface.find_entities_filtered{
      area = {{-8, -8}, {8, 8}},
      type = {"simple-entity", "tree", "cliff", "resource"},
  }) do
    entity.destroy()
  end
  local machine = surface.create_entity{
    name = "nullius-crusher-1", position = {0, 0}, force = force,
  }
  check(machine ~= nil, "failed to place Vulcanus transition witness")
  if not machine then return end
  local position = machine.position
  toggle(machine)
  check(entity_at(surface, "nullius-crusher-1-pneumatic", position) ~= nil,
    "Vulcanus crusher toggled to thermal instead of pneumatic mode")
end

local function prepare_other_surface(force)
  local surface = game.create_surface("thermal-other")
  surface.request_to_generate_chunks({0, 0}, 1)
  surface.force_generate_chunk_requests()
  local machine = surface.create_entity{
    name = "nullius-crusher-1", position = {0, 0}, force = force,
  }
  check(machine ~= nil, "failed to place other-surface transition witness")
  if not machine then return end
  toggle(machine)
  check(machine.valid and machine.name == "nullius-crusher-1",
    "crusher transitioned on a non-planet surface")
end

local function setup()
  script.on_nth_tick(1, nil)
  local surface = game.surfaces.nauvis
  local force = game.forces.player
  surface.request_to_generate_chunks({0, 0}, 2)
  surface.force_generate_chunk_requests()
  for _, entity in ipairs(surface.find_entities_filtered{
      area = {{-24, -8}, {24, 8}},
      type = {"simple-entity", "tree", "cliff", "resource"},
  }) do
    entity.destroy()
  end

  local technology = force.technologies[TECHNOLOGY]
  check(technology ~= nil, "missing Thermal Engineering 1")
  if not technology then finish() return end
  technology.researched = false
  for _, test in ipairs(cases) do
    validate_prototype(test)
    force.recipes[test.recipe].enabled = true
    local machine = surface.create_entity{
      name = test.base, position = test.position, force = force,
    }
    check(machine ~= nil, "failed to place " .. test.id)
    if machine then
      toggle(machine)
      check(machine.valid and machine.name == test.base,
        test.id .. " entered thermal mode before research")
      check(machine.set_recipe(test.recipe),
        test.id .. " rejected its production recipe")
      for name, count in pairs(test.inputs) do
        check(machine.insert{name = name, count = count} == count,
          test.id .. " rejected input " .. name)
      end
      machine.active = false
    end
  end

  technology.researched = true
  storage.machines = {}
  for _, test in ipairs(cases) do
    local base = entity_at(surface, test.base, test.position)
    check(base ~= nil, test.id .. " base machine disappeared before transition")
    if base then
      local position = base.position
      toggle(base)
      local thermal = entity_at(surface, test.base .. "-thermal", position)
      check(thermal ~= nil, test.id .. " did not enter thermal mode after research")
      if thermal then
        storage.machines[test.id] = thermal
        check(thermal.get_recipe() and thermal.get_recipe().name == test.recipe,
          test.id .. " transition did not preserve recipe")
        check_exact(inventory_counts(thermal.get_inventory(
          defines.inventory.assembling_machine_input)), test.inputs,
          test.id .. " transitioned input")
      end
    end
  end
  if #failures > 0 then finish() return end
  prepare_other_surface(force)
  prepare_vulcanus(force)
  if #failures > 0 then finish() return end
  script.on_nth_tick(5, connect_heat)
end

script.on_nth_tick(1, setup)

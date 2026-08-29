local GAS = "nullius-compressed-volcanic-gas"
local MACHINE = "nullius-hydro-plant-1-pneumatic"
local VENT_PARTS = {
  "nullius-lava-intake-1-gasvent",
  "nullius-lava-intake-2-gasvent",
  "nullius-gas-vent-drill",
  "nullius-gas-vent-seam",
}

local function run(spec)
  local result_path = "factorio-tests/" .. spec.case .. ".json"
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

  local function finish()
    local result = {
      schema = 1,
      case = spec.case,
      status = (#failures == 0) and "pass" or "fail",
      factorio_version = script.active_mods.base,
      tick = game.tick,
      assertions = assertions,
      failure_count = #failures,
      failures = failures,
      observations = observations,
    }
    helpers.write_file(result_path, helpers.table_to_json(result), false)
    if #failures > 0 then error(helpers.table_to_json(result)) end
  end

  local function box_amount(index, fluid)
    local contents = storage.machine.fluidbox[index]
    if contents and contents.name == fluid then return contents.amount end
    return 0
  end

  local function fluid_total(index, fluid, entities)
    local total = box_amount(index, fluid)
    for _, entity in ipairs(entities) do
      if entity.valid then total = total + entity.get_fluid_count(fluid) end
    end
    return total
  end

  local function gas_total()
    local total = box_amount(1, GAS) + box_amount(3, GAS)
    for _, entity in ipairs(storage.gas_entities) do
      if entity.valid then total = total + entity.get_fluid_count(GAS) end
    end
    return total
  end

  local function item_total(name)
    local total = storage.item_sink.get_item_count(name)
    local output = storage.machine.get_output_inventory()
    if output then total = total + output.get_item_count(name) end
    if storage.inserter.held_stack.valid_for_read
        and storage.inserter.held_stack.name == name then
      total = total + storage.inserter.held_stack.count
    end
    return total
  end

  local function output_state()
    local state = {items = {}, fluids = {}}
    for name in pairs(spec.output_items) do
      state.items[name] = item_total(name)
    end
    if spec.sulfur_dioxide then
      state.fluids["nullius-sulfur-dioxide"] = fluid_total(
        4, "nullius-sulfur-dioxide", storage.so2_output_entities)
    end
    return state
  end

  local function check_terminal()
    script.on_nth_tick(storage.terminal_tick, nil)
    local outputs = output_state()
    local gas = gas_total()
    local lava = fluid_total(2, "lava", storage.lava_entities)
    observations.terminal = {
      elapsed_ticks = game.tick - storage.started_tick,
      cycles = storage.machine.products_finished,
      gas = gas,
      lava = lava,
      outputs = outputs,
      crafting_progress = storage.machine.crafting_progress,
      status = storage.machine.status,
    }

    check(storage.machine.products_finished == 1,
      "terminal did not complete exactly one recipe cycle")
    check(close(lava, 0), "terminal left recipe lava unconsumed")
    for name, expected in pairs(spec.output_items) do
      check(close(outputs.items[name], expected),
        "terminal item output mismatch for " .. name)
    end
    check(close(gas, spec.output_gas),
      "terminal compressed volcanic gas network mismatch")
    if spec.sulfur_dioxide then
      check(close(outputs.fluids["nullius-sulfur-dioxide"], spec.sulfur_dioxide),
        "terminal sulfur dioxide output mismatch")
    end
    check(#storage.surface.find_entities_filtered{name = VENT_PARTS} == 0,
      "terminal depended on a free-gas vent")
    finish()
  end

  local function check_before_terminal()
    script.on_nth_tick(storage.before_tick, nil)
    local outputs = output_state()
    observations.before_terminal = {
      elapsed_ticks = game.tick - storage.started_tick,
      cycles = storage.machine.products_finished,
      outputs = outputs,
      crafting_progress = storage.machine.crafting_progress,
    }
    check(storage.machine.products_finished == 0,
      "recipe completed before its declared duration")
    for name, amount in pairs(outputs.items) do
      check(close(amount, 0), "item appeared before terminal: " .. name)
    end
    for name, amount in pairs(outputs.fluids) do
      check(close(amount, 0), "fluid appeared before terminal: " .. name)
    end
    script.on_nth_tick(storage.terminal_tick, check_terminal)
  end

  local function start_machine()
    script.on_nth_tick(60, nil)
    check(storage.machine.products_finished == 0,
      "machine crafted while the fixture was settling")
    check(close(gas_total(), spec.fuel_gas),
      "fuel gas changed while the fixture was settling")
    check(close(fluid_total(2, "lava", storage.lava_entities), spec.lava),
      "lava changed while the fixture was settling")
    local outputs = output_state()
    for name, amount in pairs(outputs.items) do
      check(close(amount, 0), "fixture contains item output: " .. name)
    end
    for name, amount in pairs(outputs.fluids) do
      check(close(amount, 0), "fixture contains fluid output: " .. name)
    end

    storage.machine.active = true
    storage.started_tick = game.tick
    storage.before_tick = 60 + spec.recipe_ticks
    storage.terminal_tick = 60 + spec.ticks
    script.on_nth_tick(storage.before_tick, check_before_terminal)
  end

  local function offset(origin, x, y)
    return {origin.x + x, origin.y + y}
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

  local function setup()
    script.on_nth_tick(1, nil)
    local planet = game.planets["nullius-vulcanus"]
    check(planet ~= nil, "missing nullius-vulcanus planet")
    if not planet then finish() return end
    local surface = planet.surface or planet.create_surface()
    check(surface ~= nil, "failed to create Vulcanus surface")
    if not surface then finish() return end
    storage.surface = surface

    surface.request_to_generate_chunks({0, 0}, 1)
    surface.force_generate_chunk_requests()
    local tiles = {}
    for x = -16, 16 do
      for y = -16, 16 do
        tiles[#tiles + 1] = {name = "volcanic-soil-dark", position = {x, y}}
      end
    end
    surface.set_tiles(tiles, true, false, false, false)

    local ghost = surface.create_entity{
      name = "entity-ghost",
      inner_name = MACHINE,
      position = {0, 0},
      direction = defines.direction.north,
      force = game.forces.player,
      expires = false,
    }
    check(ghost ~= nil, "failed to create pneumatic hydro-plant ghost")
    if not ghost then finish() return end
    local _, machine = ghost.revive{raise_revive = true}
    check(machine ~= nil, "failed to build pneumatic hydro plant")
    if not machine then finish() return end
    storage.machine = machine
    local origin = machine.position

    local recipe_set = machine.set_recipe(spec.recipe)
    check(recipe_set, "failed to set recipe " .. spec.recipe)
    local recipe = machine.get_recipe()
    check(recipe and recipe.name == spec.recipe,
      "pneumatic hydro plant has the wrong recipe")
    if not recipe_set or not recipe or recipe.name ~= spec.recipe then
      finish()
      return
    end
    check(close(recipe.energy * 60, spec.recipe_ticks),
      "runtime recipe duration differs from the matrix")
    machine.active = false

    local lava_pipe = place(surface, "pipe", offset(origin, -1, -3))
    local lava_tank = place(surface, "storage-tank", offset(origin, -2, -5))
    if not lava_pipe or not lava_tank then finish() return end
    storage.lava_entities = {lava_pipe, lava_tank}

    storage.gas_entities = {}
    local gas_pipe_offsets = {
      {3, 0}, {4, 0}, {5, 0},
      {4, 1}, {4, 2}, {4, 3}, {3, 3}, {2, 3}, {1, 3},
    }
    for _, pipe_offset in ipairs(gas_pipe_offsets) do
      local pipe = place(surface, "pipe",
        offset(origin, pipe_offset[1], pipe_offset[2]))
      if not pipe then finish() return end
      storage.gas_entities[#storage.gas_entities + 1] = pipe
    end
    local gas_tank = place(surface, "storage-tank", offset(origin, 7, 1))
    if not gas_tank then finish() return end
    storage.gas_entities[#storage.gas_entities + 1] = gas_tank

    storage.so2_output_entities = {}
    if spec.sulfur_dioxide then
      local so2_pipe = place(surface, "pipe", offset(origin, -1, 3))
      local so2_tank = place(surface, "storage-tank", offset(origin, -2, 5))
      if not so2_pipe or not so2_tank then finish() return end
      storage.so2_output_entities = {so2_pipe, so2_tank}
    end

    local item_sink = place(surface, "infinity-chest", offset(origin, 0, 4))
    local inserter = place(surface, "inserter", offset(origin, 0, 3),
      defines.direction.south)
    local pole = place(surface, "small-electric-pole", offset(origin, 0, 6))
    local power = place(surface, "electric-energy-interface", offset(origin, 0, 8))
    if not item_sink or not inserter or not pole or not power then finish() return end
    power.power_production = 1000000
    power.electric_buffer_size = 1000000
    storage.item_sink = item_sink
    storage.inserter = inserter

    local inserted_lava = lava_tank.insert_fluid{name = "lava", amount = spec.lava}
    machine.fluidbox[1] = {
      name = GAS,
      amount = spec.fuel_gas,
      temperature = prototypes.fluid[GAS].default_temperature,
    }
    check(close(inserted_lava, spec.lava), "failed to seed exact lava input")
    check(close(gas_total(), spec.fuel_gas),
      "fuel fixture does not contain the declared gas input")
    check(close(fluid_total(2, "lava", storage.lava_entities), spec.lava),
      "lava fixture does not contain the declared input")
    check(#surface.find_entities_filtered{name = VENT_PARTS} == 0,
      "lava-separation fixture contains a free-gas vent")

    script.on_nth_tick(60, start_machine)
  end

  script.on_nth_tick(1, setup)
end

return run

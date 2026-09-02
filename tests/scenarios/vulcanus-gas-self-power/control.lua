local CASE = "vulcanus-gas-self-power"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local MACHINE = "nullius-hydro-plant-1-pneumatic"
local RECIPE = "nullius-lava-gas-extraction"
local GAS = "nullius-compressed-volcanic-gas"
local GAS_PER_CYCLE = 65
local VENT_PARTS = {
  "nullius-lava-intake-1-gasvent",
  "nullius-lava-intake-2-gasvent",
  "nullius-gas-vent-drill",
  "nullius-gas-vent-seam",
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

local function fluid_total(fluid, entities)
  local total = storage.machine.get_fluid_count(fluid)
  for _, entity in pairs(entities) do
    if entity.valid then total = total + entity.get_fluid_count(fluid) end
  end
  return total
end

local function stone_total()
  local total = storage.stone_sink.get_item_count("stone")
  local output = storage.machine.get_output_inventory()
  if output then total = total + output.get_item_count("stone") end
  if storage.inserter.held_stack.valid_for_read
      and storage.inserter.held_stack.name == "stone" then
    total = total + storage.inserter.held_stack.count
  end
  return total
end

local function check_terminal()
  script.on_nth_tick(305, nil)
  local cycles = storage.machine.products_finished
  local gas = fluid_total(GAS, storage.gas_entities)
  local lava = fluid_total("lava", storage.lava_entities)
  local stone = stone_total()
  local gas_produced = cycles * GAS_PER_CYCLE
  local gas_consumed = 24 + gas_produced - gas
  local lava_consumed = 100 - lava
  observations.terminal = {
    elapsed_ticks = game.tick - storage.started_tick,
    cycles = cycles,
    gas_produced = gas_produced,
    gas_consumed = gas_consumed,
    gas = gas,
    lava_consumed = lava_consumed,
    lava = lava,
    stone = stone,
    crafting_progress = storage.machine.crafting_progress,
    crafting_speed = storage.machine.crafting_speed,
    recipe_energy = storage.machine.get_recipe().energy,
    status = storage.machine.status,
  }

  check(cycles == 2, "terminal completed an unexpected number of recipe cycles")
  check(close(gas_produced, 130),
    "terminal produced an unexpected amount of compressed volcanic gas")
  check(gas_consumed + 0.000001 >= 48 and gas_consumed <= 48.1,
    "terminal gas consumption is outside the two-cycle energy range")
  check(gas >= 105.9, "terminal gas reserve is below the self-power threshold")
  check(close(lava_consumed, 100), "terminal did not consume all 100 lava")
  check(close(stone, 6), "terminal produced an unexpected amount of stone")
  check(#storage.surface.find_entities_filtered{name = VENT_PARTS} == 0,
    "terminal depended on a connected free-gas vent")
  finish()
end

local function start_machine()
  script.on_nth_tick(60, nil)
  check(storage.machine.products_finished == 0,
    "machine crafted while the fixture was settling")
  check(close(fluid_total("lava", storage.lava_entities), 100),
    "lava changed while the fixture was settling")
  check(close(fluid_total(GAS, storage.gas_entities), 24),
    "gas changed while the fixture was settling")
  storage.machine.active = true
  storage.started_tick = game.tick
  script.on_nth_tick(305, check_terminal)
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

local function offset(origin, x, y)
  return {origin.x + x, origin.y + y}
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

  check(machine.set_recipe(RECIPE), "failed to set lava gas-extraction recipe")
  check(machine.get_recipe() and machine.get_recipe().name == RECIPE,
    "pneumatic hydro plant has the wrong recipe")
  machine.active = false

  storage.gas_entities = {}
  local gas_pipe_offsets = {
    {3, 0}, {4, 0}, {5, 0},
    {4, 1}, {4, 2}, {4, 3}, {3, 3}, {2, 3}, {1, 3},
  }
  for _, pipe_offset in ipairs(gas_pipe_offsets) do
    local pipe = place(surface, "pipe", offset(origin, pipe_offset[1], pipe_offset[2]))
    if not pipe then finish() return end
    storage.gas_entities[#storage.gas_entities + 1] = pipe
  end
  local gas_tank = place(surface, "storage-tank", offset(origin, 7, 1))
  if not gas_tank then finish() return end
  storage.gas_entities[#storage.gas_entities + 1] = gas_tank

  storage.lava_entities = {}
  for _, pipe_offset in ipairs({{-1, -3}, {-1, -4}}) do
    local pipe = place(surface, "pipe", offset(origin, pipe_offset[1], pipe_offset[2]))
    if not pipe then finish() return end
    storage.lava_entities[#storage.lava_entities + 1] = pipe
  end
  local lava_tank = place(surface, "storage-tank", offset(origin, -2, -6))
  if not lava_tank then finish() return end
  storage.lava_entities[#storage.lava_entities + 1] = lava_tank

  local stone_sink = place(surface, "infinity-chest", offset(origin, 0, 4))
  local inserter = place(surface, "inserter", offset(origin, 0, 3),
    defines.direction.south)
  local pole = place(surface, "small-electric-pole", offset(origin, -2, 4))
  local power = place(surface, "electric-energy-interface", offset(origin, -4, 4))
  if not stone_sink or not inserter or not pole or not power then finish() return end
  power.power_production = 1000000
  power.electric_buffer_size = 1000000
  storage.stone_sink = stone_sink
  storage.inserter = inserter

  local inserted_lava = lava_tank.insert_fluid{name = "lava", amount = 100}
  storage.machine.fluidbox[1] = {
    name = GAS,
    amount = 24,
    temperature = prototypes.fluid[GAS].default_temperature,
  }
  check(close(inserted_lava, 100), "failed to seed exactly 100 lava")
  check(close(fluid_total("lava", storage.lava_entities), 100),
    "lava fixture did not contain exactly 100 fluid")
  check(close(fluid_total(GAS, storage.gas_entities), 24),
    "gas fixture did not contain exactly 24 fluid")
  check(#surface.find_entities_filtered{name = VENT_PARTS} == 0,
    "gas self-power fixture contains a free-gas vent")

  script.on_nth_tick(60, start_machine)
end

script.on_nth_tick(1, setup)

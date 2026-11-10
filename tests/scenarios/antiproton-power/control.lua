-- given: Antimatter Containment researched by a fresh force; a starter platform stopped at Fulgora;
--   one fission cell per refill; water through an infinity pipe; turbine exhaust drained; the
--   reactor, heat pipe, and exchanger start at a declared working temperature.
-- place: a reactor, a heat pipe, a pressure-boiling heat exchanger 3, a steam manifold, four
--   closed turbines 3, and an antiproton collector with one empty trap, all on the platform.
-- connect: the turbines are the collector's only power.
-- run: warm the steam lines, then measure one window.
-- expect: the reactor chain powers the collector in Fulgora orbit; fission cells burned per
--   filled trap, from fuel and stored heat over the window, exceed the trap's fuel value many
--   times over.
local fluids = require("__nullius-star__/scenarios/fluid-api")
local CASE = "antiproton-power"
local COLLECTOR = "nullius-antiproton-collector"
local CELL = "nullius-fission-cell"
local START_TEMPERATURE = 1000
local WARMUP = 1200
local WINDOW = 6000
local TURBINES = 4
local MIN_MULTIPLE = 10
local OUTWARD = {[defines.direction.north] = {0, -1}, [defines.direction.east] = {1, 0},
  [defines.direction.south] = {0, 1}, [defines.direction.west] = {-1, 0}}

local function check(ok, message)
  storage.assertions = storage.assertions + 1
  assert(ok, message)
end

local function place(surface, force, name, position, direction)
  if not surface.can_place_entity{name = name, position = position, direction = direction, force = force} then
    local x, y = position.x or position[1], position.y or position[2]
    local blocking = {}
    for _, entity in pairs(surface.find_entities_filtered{area = {{x - 3, y - 3}, {x + 3, y + 3}}}) do
      blocking[#blocking + 1] = entity.name .. "@" .. entity.position.x .. "," .. entity.position.y
    end
    check(false, "placement " .. name .. " at " .. x .. "," .. y .. " near " .. table.concat(blocking, " ") ..
      " tile " .. surface.get_tile(x, y).name)
  end
  return assert(surface.create_entity{name = name, position = position, direction = direction, force = force,
    raise_built = true}, "failed to place " .. name)
end

-- Target tile of the machine port that carries the fluid in the given direction.
local function port(machine, fluid, production_type)
  for index = 1, fluids.count(machine) do
    local filter = fluids.filter(machine, index)
    if fluids.prototype(machine, index).production_type == production_type and (not filter or filter.name == fluid) then
      return assert(fluids.connections(machine, index)[1], machine.name .. " has no " .. fluid .. " port").target_position
    end
  end
  error(machine.name .. " has no " .. production_type .. " port for " .. fluid)
end

local function infinity(surface, force, position, fluid, mode)
  local pipe = place(surface, force, "infinity-pipe", position)
  pipe.set_infinity_pipe_filter{name = fluid, percentage = mode == "at-least" and 1 or 0, mode = mode,
    temperature = prototypes.fluid[fluid].default_temperature}
end

-- Heat held by an entity relative to zero degrees; only differences are used.
local function stored_heat(entity)
  local prototype = entity.prototype
  local heat = prototype.heat_buffer_prototype or prototype.heat_energy_source_prototype
    or (prototype.burner_prototype and nil)
  return entity.temperature * heat.specific_heat
end

local function fuel_energy(reactor)
  local cells = reactor.get_fuel_inventory().get_item_count(CELL)
  return cells * prototypes.item[CELL].fuel_value + reactor.burner.remaining_burning_fuel
end

local function setup()
  storage.assertions = 0
  local force = game.create_force(CASE)
  force.technologies["nullius-antimatter-containment"].researched = true
  force.recipes["nullius-pressure-boiling-water"].enabled = true
  force.unlock_space_location("nullius-fulgora")
  local platform = assert(force.create_space_platform{name = CASE, planet = "nullius-fulgora",
    starter_pack = "space-platform-starter-pack"})
  platform.apply_starter_pack(true)
  local surface = platform.surface
  local tiles = {}
  for x = -24, 40 do for y = 6, 52 do tiles[#tiles + 1] = {name = "space-platform-foundation", position = {x, y}} end end
  surface.set_tiles(tiles)

  local exchanger = place(surface, force, "nullius-heat-exchanger-3", {0, 20})
  exchanger.set_recipe("nullius-pressure-boiling-water")
  -- The heat pipe sits on the exchanger's first heat connection; the reactor's
  -- side connection meets it from three tiles further out.
  local connection = assert(exchanger.prototype.heat_energy_source_prototype.connections[1], "exchanger heat connection")
  local step = OUTWARD[connection.direction]
  check(step ~= nil, "exchanger heat connection faces a cardinal direction")
  local offset = connection.position
  local pipe_position = {exchanger.position.x + (offset.x or offset[1]) + step[1],
    exchanger.position.y + (offset.y or offset[2]) + step[2]}
  local heat_pipe = place(surface, force, "nullius-heat-pipe-3", pipe_position)
  local reactor = place(surface, force, "nullius-reactor",
    {pipe_position[1] + 3 * step[1], pipe_position[2] + 3 * step[2]})
  check(reactor.get_fuel_inventory().insert{name = CELL, count = 1} == 1, "reactor accepts a fission cell")
  for _, entity in ipairs({reactor, heat_pipe, exchanger}) do entity.temperature = START_TEMPERATURE end

  infinity(surface, force, port(exchanger, "nullius-water", "input"), "nullius-water", "at-least")
  local steam = port(exchanger, "nullius-pressure-steam", "output")
  -- Turbines start clear of the reactor, which may sit beside the exchanger.
  local turbines = {}
  for i = 1, TURBINES do
    local x = steam.x + 3 + 3 * i
    turbines[i] = place(surface, force, "nullius-turbine-closed-standard-3", {x, steam.y + 3}, defines.direction.north)
    infinity(surface, force, port(turbines[i], "nullius-water", "output"), "nullius-water", "exactly")
  end
  for x = steam.x, steam.x + 3 + 3 * TURBINES do place(surface, force, "pipe", {x, steam.y}) end

  local collector = place(surface, force, COLLECTOR, {steam.x + 10, steam.y + 14})
  check(collector.insert{name = "nullius-antimatter-trap", count = 1} == 1, "collector accepts an empty trap")
  place(surface, force, "substation", {steam.x + 10, steam.y + 9})
  storage.platform, storage.reactor, storage.collector = platform, reactor, collector
  storage.heat = {reactor, heat_pipe, exchanger}
  storage.turbines = turbines
end

local function snapshot()
  local heat = 0
  for _, entity in ipairs(storage.heat) do heat = heat + stored_heat(entity) end
  local collector = storage.collector
  return {tick = game.tick, fuel = fuel_energy(storage.reactor), heat = heat,
    progress = collector.products_finished + collector.crafting_progress}
end

local function refuel()
  local inventory = storage.reactor.get_fuel_inventory()
  if inventory.get_item_count(CELL) == 0 then
    check(inventory.insert{name = CELL, count = 1} == 1, "refill")
    storage.cells = (storage.cells or 0) + 1
  end
end

script.on_nth_tick(30, function(event)
  if event.tick == 0 then return end
  if not storage.reactor then setup() return end
  -- Refills are counted as fuel added, so a refill inside the window adds its energy back.
  local before = storage.reactor.get_fuel_inventory().get_item_count(CELL)
  refuel()
  if storage.start and storage.reactor.get_fuel_inventory().get_item_count(CELL) > before then
    storage.added = (storage.added or 0) + prototypes.item[CELL].fuel_value
  end
  if not storage.start and game.tick >= WARMUP then
    storage.start = snapshot()
    storage.added = 0
    return
  end
  if not storage.start or game.tick < storage.start.tick + WINDOW then return end
  local finish = snapshot()
  local start = storage.start
  local burned = start.fuel + storage.added - finish.fuel
  local heat = burned - (finish.heat - start.heat)
  local progress = finish.progress - start.progress
  local collector = storage.collector
  check(storage.platform.space_location.name == "nullius-fulgora", "measured in Fulgora orbit")
  check(not collector.disabled_by_script, "collector runs at Fulgora")
  check(progress > 0, "the reactor chain powers the collector")
  local per_trap = heat / progress
  local fuel_value = prototypes.item["nullius-antimatter"].fuel_value
  local cells = per_trap / prototypes.item[CELL].fuel_value
  check(per_trap >= MIN_MULTIPLE * fuel_value, "a filled trap costs at least " .. MIN_MULTIPLE ..
    " times its fuel value in reactor heat: " .. per_trap)
  -- Conservation: no plant delivers more electricity than the heat it burns.
  local electric = collector.prototype.get_max_energy_usage() * 60 * prototypes.recipe["nullius-antiproton-capture"].energy
  check(per_trap >= electric, "reactor heat per trap covers the collector's electricity: " .. per_trap .. " < " .. electric)
  helpers.write_file("factorio-tests/" .. CASE .. ".json", helpers.table_to_json{
    schema = 1, case = CASE, status = "pass", failure_count = 0, assertions = storage.assertions,
    tick = game.tick, factorio_version = script.active_mods.base,
    observations = {window_ticks = WINDOW, reactor_heat_joules = heat, capture_progress = progress,
      heat_per_trap_joules = per_trap, fission_cells_per_trap = cells,
      fuel_value_multiple = per_trap / fuel_value, chain_efficiency = electric / per_trap,
      average_collector_power_watts = heat / (WINDOW / 60),
      reactor_temperature = {start = START_TEMPERATURE, finish = storage.reactor.temperature}}}, false)
  script.on_nth_tick(30, nil)
end)

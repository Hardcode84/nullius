-- given: Seawater Uranium Adsorption researched by a fresh force on Nauvis.
-- place: nanofabricator 1, hydro plant 1, and two flotation cells 1, each on a 10 MW grid.
-- connect: infinity pipes supply each fluid ingredient at its port and drain each fluid product.
-- act: insert one batch of each item ingredient; the item ingredient limits each machine to one craft.
-- run: until every machine has finished its craft.
-- expect: one craft per recipe, exact item outputs, recorded fluid production and consumption,
--   and the drained products gone from the machines.
local CASE = "seawater-uranium"
local TECHNOLOGY = "nullius-seawater-uranium-adsorption"
local SETUP_TICK = 30
-- The slowest recipe takes 12 seconds at crafting speed 1.
local CHECK_TICK = SETUP_TICK + 720 + 60
local fluids = require("__nullius-star__/scenarios/fluid-api")
local ROWS = {
  {machine = "nullius-nanofabricator-1", recipe = "nullius-uranyl-binding-fiber",
    items = {["nullius-acrylic-fiber"] = 4}, sources = {"nullius-amino-acids"}, sinks = {},
    outputs = {["nullius-uranyl-binding-fiber"] = 4}},
  {machine = "nullius-hydro-plant-1", recipe = "nullius-loaded-uranyl-fiber",
    items = {["nullius-uranyl-binding-fiber"] = 1}, sources = {"nullius-seawater"}, sinks = {"nullius-seawater"},
    outputs = {["nullius-loaded-uranyl-fiber"] = 1}},
  {machine = "nullius-flotation-cell-1", recipe = "nullius-uranyl-solution",
    items = {["nullius-loaded-uranyl-fiber"] = 10}, sources = {"nullius-acid-hydrochloric"},
    sinks = {"nullius-uranyl-solution"}, outputs = {["nullius-uranyl-binding-fiber"] = 9}},
  {machine = "nullius-flotation-cell-1", recipe = "nullius-yellowcake-precipitation",
    items = {["nullius-sodium-hydroxide"] = 1}, sources = {"nullius-uranyl-solution"},
    sinks = {"nullius-wastewater"}, outputs = {["nullius-yellowcake"] = 1}},
}
-- Fluid amounts every recipe above produces and consumes, summed per fluid.
local PRODUCED = {["nullius-seawater"] = 1000, ["nullius-uranyl-solution"] = 20, ["nullius-wastewater"] = 10}
local CONSUMED = {["nullius-amino-acids"] = 2, ["nullius-seawater"] = 1000, ["nullius-acid-hydrochloric"] = 25,
  ["nullius-uranyl-solution"] = 10}

local function check(ok, message)
  storage.assertions = storage.assertions + 1
  assert(ok, message)
end

local function build(surface, force, name, x, y)
  return assert(surface.create_entity{name = name, position = {x, y}, force = force}, "failed to place " .. name)
end

-- Place an infinity pipe on the machine port whose filter matches the fluid.
local function connect(surface, force, machine, fluid, mode)
  for index = 1, fluids.count(machine) do
    local filter = fluids.filter(machine, index)
    local prototype = fluids.prototype(machine, index)
    local wanted = mode == "at-least" and "input" or "output"
    if filter and filter.name == fluid and prototype.production_type == wanted then
      local connection = assert(fluids.connections(machine, index)[1], machine.name .. " has no port for " .. fluid)
      local pipe = build(surface, force, "infinity-pipe", connection.target_position.x, connection.target_position.y)
      pipe.set_infinity_pipe_filter{name = fluid, percentage = mode == "at-least" and 1 or 0, mode = mode,
        temperature = prototypes.fluid[fluid].default_temperature}
      return
    end
  end
  check(false, machine.name .. " has no " .. mode .. " port for " .. fluid)
end

local function setup()
  storage.assertions = 0
  local force = game.create_force(CASE)
  force.technologies["nullius-biochemistry-4"].researched = true
  for _, row in ipairs(ROWS) do
    check(not force.recipes[row.recipe].enabled, "Biochemistry 4 unlocked " .. row.recipe)
  end
  force.technologies[TECHNOLOGY].researched = true
  local surface = game.surfaces.nauvis
  surface.request_to_generate_chunks({0, 0}, 3)
  surface.force_generate_chunk_requests()
  local tiles = {}
  for x = -40, 40 do for y = -12, 12 do tiles[#tiles + 1] = {name = "concrete", position = {x, y}} end end
  surface.set_tiles(tiles, true)
  for _, entity in pairs(surface.find_entities_filtered{area = {{-40, -12}, {40, 12}}}) do entity.destroy() end
  storage.machines = {}
  for i, row in ipairs(ROWS) do
    check(force.recipes[row.recipe].enabled, TECHNOLOGY .. " did not unlock " .. row.recipe)
    local x = i * 18 - 45
    local machine = build(surface, force, row.machine, x, 0)
    machine.set_recipe(row.recipe)
    check(machine.get_recipe().name == row.recipe, row.machine .. " selects " .. row.recipe)
    local grid = build(surface, force, "factorio-test-planner-grid", x + 7, 0)
    grid.power_production = 10000000
    grid.electric_buffer_size = 10000000
    build(surface, force, "substation", x + 5, 4)
    for _, fluid in ipairs(row.sources) do connect(surface, force, machine, fluid, "at-least") end
    for _, fluid in ipairs(row.sinks) do connect(surface, force, machine, fluid, "exactly") end
    for name, count in pairs(row.items) do
      check(machine.insert{name = name, count = count} == count, row.machine .. " accepts " .. name)
    end
    storage.machines[i] = machine
  end
  storage.force = force
  storage.surface = surface
end

local function verify()
  local states = {}
  for i, row in ipairs(ROWS) do
    local machine = storage.machines[i]
    local status
    for name, value in pairs(defines.entity_status) do if value == machine.status then status = name end end
    states[#states + 1] = row.recipe .. ": " .. machine.products_finished .. " crafts, " .. tostring(status) ..
      ", fluids " .. helpers.table_to_json(machine.get_fluid_contents())
  end
  for i, row in ipairs(ROWS) do
    local machine = storage.machines[i]
    check(machine.products_finished == 1, "each recipe crafts once:\n" .. table.concat(states, "\n"))
    local output = machine.get_output_inventory()
    for name, count in pairs(row.outputs) do
      check(output.get_item_count(name) == count, row.recipe .. " output " .. name .. ": " .. output.get_item_count(name))
    end
    check(machine.get_inventory(defines.inventory.crafter_input).is_empty(), row.recipe .. " consumed its items")
    for _, fluid in ipairs(row.sinks) do
      if fluid ~= "nullius-seawater" then
        check(machine.get_fluid_count(fluid) < 0.001, row.recipe .. " drained " .. fluid)
      end
    end
  end
  local statistics = storage.force.get_fluid_production_statistics(storage.surface)
  for fluid, amount in pairs(PRODUCED) do
    local actual = statistics.get_input_count(fluid)
    check(math.abs(actual - amount) < 0.001, "produced " .. fluid .. ": " .. actual)
  end
  for fluid, amount in pairs(CONSUMED) do
    local actual = statistics.get_output_count(fluid)
    check(math.abs(actual - amount) < 0.001, "consumed " .. fluid .. ": " .. actual)
  end
  helpers.write_file("factorio-tests/" .. CASE .. ".json", helpers.table_to_json{
    schema = 1, case = CASE, status = "pass", failure_count = 0, assertions = storage.assertions,
    tick = game.tick, factorio_version = script.active_mods.base}, false)
end

-- Nth-tick handlers also fire at tick 0.
script.on_nth_tick(SETUP_TICK, function(event)
  if event.tick == 0 then return end
  script.on_nth_tick(SETUP_TICK, nil)
  setup()
end)
script.on_nth_tick(CHECK_TICK, function(event)
  if event.tick == 0 then return end
  script.on_nth_tick(CHECK_TICK, nil)
  verify()
end)

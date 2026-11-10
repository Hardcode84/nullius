-- Recipe rows: one placed machine per recipe, crafting one batch on a test grid.
--
-- spec.case: scenario name for the result file.
-- spec.prerequisites: technologies researched before the stages.
-- spec.stages: ordered {technology = name, rows = {...}}. Each stage's recipes
--   must be locked until its technology is researched and unlocked after.
-- spec.check_tick: tick of the final check, after setup_tick and every row's craft.
-- row.machine, row.recipe: the placed machine and its selected recipe.
-- row.items: item batch inserted into the machine; it limits the row to one craft.
-- row.fluids: fluid batch inserted into the machine instead of piped, for
--   recipes without an item ingredient.
-- row.sources: fluid ingredient amounts, supplied through infinity pipes.
-- row.sinks: fluid product amounts, drained through infinity pipes.
-- row.outputs: exact item products left in the machine.
local fluids = require("__nullius-star__/scenarios/fluid-api")
local SETUP_TICK = 30
local SPACING = 18

local function check(ok, message)
  storage.assertions = storage.assertions + 1
  assert(ok, message)
end

local function build(surface, force, name, x, y)
  return assert(surface.create_entity{name = name, position = {x, y}, force = force}, "failed to place " .. name)
end

-- Place an infinity pipe on the machine port whose filter matches the fluid.
local function connect(surface, force, machine, fluid, mode)
  local wanted = mode == "at-least" and "input" or "output"
  for index = 1, fluids.count(machine) do
    local filter = fluids.filter(machine, index)
    if filter and filter.name == fluid and fluids.prototype(machine, index).production_type == wanted then
      local connection = assert(fluids.connections(machine, index)[1], machine.name .. " has no port for " .. fluid)
      local pipe = build(surface, force, "infinity-pipe", connection.target_position.x, connection.target_position.y)
      pipe.set_infinity_pipe_filter{name = fluid, percentage = mode == "at-least" and 1 or 0, mode = mode,
        temperature = prototypes.fluid[fluid].default_temperature}
      return
    end
  end
  check(false, machine.name .. " has no " .. wanted .. " port for " .. fluid)
end

local function rows_of(spec)
  local rows = {}
  for _, stage in ipairs(spec.stages) do
    for _, row in ipairs(stage.rows) do rows[#rows + 1] = row end
  end
  return rows
end

local function setup(spec)
  storage.assertions = 0
  local force = game.create_force(spec.case)
  for _, technology in ipairs(spec.prerequisites) do force.technologies[technology].researched = true end
  for _, stage in ipairs(spec.stages) do
    for _, row in ipairs(stage.rows) do
      check(not force.recipes[row.recipe].enabled, row.recipe .. " unlocked before " .. stage.technology)
    end
    force.technologies[stage.technology].researched = true
    for _, row in ipairs(stage.rows) do
      check(force.recipes[row.recipe].enabled, stage.technology .. " did not unlock " .. row.recipe)
    end
  end
  local rows = rows_of(spec)
  local half_width = #rows * SPACING / 2 + 10
  local surface = game.surfaces.nauvis
  surface.request_to_generate_chunks({0, 0}, math.ceil(half_width / 32) + 1)
  surface.force_generate_chunk_requests()
  local area = {{-half_width, -12}, {half_width, 12}}
  local tiles = {}
  for x = -half_width, half_width do
    for y = -12, 12 do tiles[#tiles + 1] = {name = "concrete", position = {x, y}} end
  end
  surface.set_tiles(tiles, true)
  for _, entity in pairs(surface.find_entities_filtered{area = area}) do entity.destroy() end
  storage.machines = {}
  for i, row in ipairs(rows) do
    local x = (i - 0.5) * SPACING - #rows * SPACING / 2
    local machine = build(surface, force, row.machine, x, 0)
    machine.set_recipe(row.recipe)
    check(machine.get_recipe().name == row.recipe, row.machine .. " selects " .. row.recipe)
    local grid = build(surface, force, "factorio-test-planner-grid", x + 7, 0)
    grid.power_production = 10000000
    grid.electric_buffer_size = 10000000
    build(surface, force, "substation", x + 5, 4)
    for fluid in pairs(row.sources or {}) do connect(surface, force, machine, fluid, "at-least") end
    for fluid in pairs(row.sinks or {}) do connect(surface, force, machine, fluid, "exactly") end
    for name, count in pairs(row.items or {}) do
      check(machine.insert{name = name, count = count} == count, row.machine .. " accepts " .. name)
    end
    for name, amount in pairs(row.fluids or {}) do
      check(machine.insert_fluid{name = name, amount = amount} == amount, row.machine .. " holds " .. name)
    end
    storage.machines[i] = machine
  end
  storage.force = force
  storage.surface = surface
end

local function add(totals, amounts)
  for name, amount in pairs(amounts or {}) do totals[name] = (totals[name] or 0) + amount end
end

local function verify(spec)
  local rows = rows_of(spec)
  local states = {}
  for i, row in ipairs(rows) do
    local machine = storage.machines[i]
    local status
    for name, value in pairs(defines.entity_status) do if value == machine.status then status = name end end
    states[#states + 1] = row.recipe .. ": " .. machine.products_finished .. " crafts, " .. tostring(status) ..
      ", fluids " .. helpers.table_to_json(machine.get_fluid_contents())
  end
  local produced, consumed = {}, {}
  for i, row in ipairs(rows) do
    local machine = storage.machines[i]
    check(machine.products_finished == 1, "each recipe crafts once:\n" .. table.concat(states, "\n"))
    local output = machine.get_output_inventory()
    for name, count in pairs(row.outputs or {}) do
      check(output.get_item_count(name) == count, row.recipe .. " output " .. name .. ": " .. output.get_item_count(name))
    end
    check(machine.get_inventory(defines.inventory.crafter_input).is_empty(), row.recipe .. " consumed its items")
    -- Flow out of a port slows as the machine's box empties, so a connected
    -- port has removed most of the batch; a disconnected one keeps all of it.
    for fluid, amount in pairs(row.sinks or {}) do
      local left = machine.get_fluid_count(fluid)
      check(left < amount / 2, row.recipe .. " drains " .. fluid .. " through its port, left " .. left)
    end
    add(produced, row.sinks)
    add(consumed, row.sources)
    add(consumed, row.fluids)
  end
  local statistics = storage.force.get_fluid_production_statistics(storage.surface)
  for fluid, amount in pairs(produced) do
    local actual = statistics.get_input_count(fluid)
    check(math.abs(actual - amount) < 0.001, "produced " .. fluid .. ": " .. actual)
  end
  for fluid, amount in pairs(consumed) do
    local actual = statistics.get_output_count(fluid)
    check(math.abs(actual - amount) < 0.001, "consumed " .. fluid .. ": " .. actual)
  end
  helpers.write_file("factorio-tests/" .. spec.case .. ".json", helpers.table_to_json{
    schema = 1, case = spec.case, status = "pass", failure_count = 0, assertions = storage.assertions,
    tick = game.tick, factorio_version = script.active_mods.base}, false)
end

local function run(spec)
  assert(spec.check_tick > SETUP_TICK, "check after setup")
  script.on_nth_tick(SETUP_TICK, function(event)
    if event.tick == 0 then return end
    script.on_nth_tick(SETUP_TICK, nil)
    setup(spec)
  end)
  script.on_nth_tick(spec.check_tick, function(event)
    if event.tick == 0 then return end
    script.on_nth_tick(spec.check_tick, nil)
    verify(spec)
  end)
end

return {setup_tick = SETUP_TICK, run = run}

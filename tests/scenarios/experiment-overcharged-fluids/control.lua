-- given: real overcharged assemblers on Nauvis with an external surge-capable grid.
-- place: each medium and large overcharged variant with two-fluid item-only recipes.
-- act: insert fluids for exactly one craft; probe small variants without fluid boxes.
-- run: one check at tick 600.
-- expect: every medium and large overcharged tier finishes one two-fluid craft, including
-- amounts above the 500 prototype volume; each input box holds 4x its recipe amount;
-- built-in productivity is 0.2, 0.4, or 0.6; small variants select no fluid recipe.
local fluid_api = require("__nullius-star__/scenarios/fluid-api")
local CASE = "experiment-overcharged-fluids"
local CASES = {
  {machine = "nullius-medium-assembler-1-overcharged", recipe = "nullius-diesel-canister"},
  {machine = "nullius-medium-assembler-1-overcharged", recipe = "nullius-boxed-diesel-canister"},
  {machine = "nullius-medium-assembler-1-overcharged", recipe = "factorio-test-em-two-fluid"},
  {machine = "nullius-medium-assembler-1-overcharged", recipe = "factorio-test-em-two-fluid-bulk"},
  {machine = "nullius-medium-assembler-2-overcharged", recipe = "factorio-test-em-two-fluid"},
  {machine = "nullius-medium-assembler-2-overcharged", recipe = "factorio-test-em-two-fluid-bulk"},
  {machine = "nullius-medium-assembler-3-overcharged", recipe = "factorio-test-em-two-fluid"},
  {machine = "nullius-medium-assembler-3-overcharged", recipe = "factorio-test-em-two-fluid-bulk"},
  {machine = "nullius-large-assembler-1-overcharged", recipe = "factorio-test-em-two-fluid"},
  {machine = "nullius-large-assembler-1-overcharged", recipe = "factorio-test-em-two-fluid-bulk"},
  {machine = "nullius-large-assembler-2-overcharged", recipe = "factorio-test-em-two-fluid"},
  {machine = "nullius-large-assembler-2-overcharged", recipe = "factorio-test-em-two-fluid-bulk"},
}
local PRODUCTIVITY = {
  ["nullius-medium-assembler-1-overcharged"] = 0.2, ["nullius-medium-assembler-2-overcharged"] = 0.4,
  ["nullius-medium-assembler-3-overcharged"] = 0.6, ["nullius-large-assembler-1-overcharged"] = 0.4,
  ["nullius-large-assembler-2-overcharged"] = 0.6,
}
local SMALL = {"nullius-small-assembler-1-overcharged", "nullius-small-assembler-2-overcharged",
  "nullius-small-assembler-3-overcharged"}

local function check(ok, message)
  storage.assertions = storage.assertions + 1
  if not ok then storage.failures[#storage.failures + 1] = message end
end

local function status_name(entity)
  for name, value in pairs(defines.entity_status) do
    if value == entity.status then return name end
  end
  return tostring(entity.status)
end

local function place(name, x)
  local surface = game.surfaces.nauvis
  local grid = assert(surface.create_entity{name = "factorio-test-planner-grid",
    position = {x, 10}, force = "player"})
  grid.power_production = 1e8
  grid.electric_buffer_size = 1e8
  assert(surface.create_entity{name = "substation", position = {x, 5}, force = "player"})
  return assert(surface.create_entity{name = name, position = {x, 0}, force = "player"})
end

script.on_nth_tick(1, function()
  script.on_nth_tick(1, nil)
  storage.assertions = 0; storage.failures = {}; storage.rows = {}
  local surface = game.surfaces.nauvis
  -- Entities only update in generated chunks.
  surface.request_to_generate_chunks({200, 0}, 8)
  surface.force_generate_chunk_requests()
  for _, entity in pairs(surface.find_entities_filtered{area = {{-20, -20}, {420, 30}}}) do
    if entity.type ~= "character" then entity.destroy() end
  end
  local tiles = {}
  for x = -20, 420 do for y = -20, 30 do tiles[#tiles + 1] = {name = "landfill", position = {x, y}} end end
  surface.set_tiles(tiles)
  game.forces.player.technologies["nullius-overcharged-assembly-2"].researched = true
  game.forces.player.technologies["nullius-overcharged-assembly-3"].researched = true
  local recipes = game.forces.player.recipes
  for _, row in ipairs(CASES) do recipes[row.recipe].enabled = true end
  for index, row in ipairs(CASES) do
    local entity = place(row.machine, index * 24)
    entity.set_recipe(row.recipe)
    local selected = entity.get_recipe()
    local result = {machine = row.machine, recipe = row.recipe,
      selected = selected and selected.name or "none", boxes = fluid_api.count(entity),
      capacity = {}, accepted = {}, requested = {}}
    for slot = 1, fluid_api.count(entity) do
      local filter = fluid_api.filter(entity, slot)
      result.capacity[slot] = {fluid = filter and filter.name or "none",
        capacity = fluid_api.capacity(entity, slot)}
    end
    for _, part in pairs(prototypes.recipe[row.recipe].ingredients) do
      if part.type == "fluid" then
        result.requested[part.name] = part.amount
        result.accepted[part.name] = entity.insert_fluid{name = part.name, amount = part.amount}
      else
        check(entity.insert{name = part.name, count = part.amount} == part.amount,
          row.recipe .. " item input")
      end
    end
    storage.rows[index] = {entity = entity, result = result}
  end
  storage.small = {}
  for index, name in ipairs(SMALL) do
    local entity = place(name, 300 + index * 24)
    local ok, err = pcall(entity.set_recipe, "factorio-test-em-two-fluid")
    local selected = entity.get_recipe()
    storage.small[name] = {boxes = fluid_api.count(entity), call_ok = ok, error = not ok and tostring(err) or nil,
      selected = selected and selected.name or "none"}
  end
end)

script.on_nth_tick(600, function()
  -- on_nth_tick also fires at tick 0, before any power has flowed.
  if game.tick == 0 then return end
  script.on_nth_tick(600, nil)
  local observations = {}
  for index, row in ipairs(storage.rows) do
    local entity, result = row.entity, row.result
    result.finished = entity.products_finished
    result.status = status_name(entity)
    result.productivity = entity.productivity_bonus
    result.priority = entity.prototype.electric_energy_source_prototype.usage_priority
    result.remaining = entity.get_fluid_contents()
    observations[index] = result
    local label = row.result.machine .. " " .. row.result.recipe
    check(result.selected == result.recipe, label .. " recipe selected")
    check(result.boxes == 2, label .. " two fluid boxes")
    check(result.priority == "tertiary", label .. " surge priority")
    check(math.abs(result.productivity - PRODUCTIVITY[result.machine]) < 1e-9, label .. " productivity")
    for _, box in pairs(result.capacity) do
      check(box.capacity == 4 * result.requested[box.fluid],
        label .. " " .. box.fluid .. " capacity " .. box.capacity)
    end
    for name, amount in pairs(result.requested) do
      check(result.accepted[name] == amount, label .. " accepted " .. name)
    end
    check(result.finished == 1, label .. " finished " .. result.finished)
    check(next(result.remaining) == nil, label .. " consumed both fluids")
  end
  for name, row in pairs(storage.small) do
    check(row.boxes == 0 and row.call_ok and row.selected == "none", name .. " rejects fluid recipe")
  end
  local result = {schema = 1, case = CASE, status = #storage.failures == 0 and "pass" or "fail",
    tick = game.tick, factorio_version = script.active_mods.base, assertions = storage.assertions,
    failure_count = #storage.failures, failures = storage.failures,
    observations = {machines = observations, small = storage.small}}
  helpers.write_file("factorio-tests/" .. CASE .. ".json", helpers.table_to_json(result), false)
  if #storage.failures > 0 then error(helpers.table_to_json(result)) end
end)

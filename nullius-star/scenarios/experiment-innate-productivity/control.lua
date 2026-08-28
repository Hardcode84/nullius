local CASE = "experiment-innate-productivity"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local MACHINE = "factorio-test-innate-productivity-machine"
local INPUT = "factorio-test-productivity-input"
local OUTPUT = "factorio-test-productivity-output"
local MODULE = "nullius-productivity-module-1"
local CYCLES = 100

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

local function create_machine(surface, position, recipe_name, insert_module)
  local machine = surface.create_entity{
    name = MACHINE,
    position = position,
    force = game.forces.player,
  }
  check(machine ~= nil, "failed to create " .. recipe_name .. " machine")
  if not machine then return nil, 0 end
  check(machine.set_recipe(recipe_name), "failed to set recipe " .. recipe_name)
  local inserted = 0
  if insert_module then
    inserted = machine.get_module_inventory().insert{name = MODULE, count = 1}
  end
  check(machine.insert{name = INPUT, count = CYCLES} == CYCLES,
    "failed to insert experiment inputs for " .. recipe_name)
  return machine, inserted
end

local function validate()
  script.on_nth_tick(180, nil)
  local cases = {
    {id = "rejected_without_module", machine = storage.rejected_plain,
      inserted = 0, expected_bonus = 0.5, expected_output = 150},
    {id = "allowed_without_module", machine = storage.allowed_plain,
      inserted = 0, expected_bonus = 0.5, expected_output = 150},
    {id = "rejected_with_module_attempt", machine = storage.rejected_module,
      inserted = storage.rejected_module_inserted,
      expected_inserted = 0, expected_bonus = 0.5, expected_output = 150},
    {id = "allowed_with_module", machine = storage.allowed_module,
      inserted = storage.allowed_module_inserted,
      expected_inserted = 1, expected_bonus = 0.54, expected_output = 154},
    {id = "capped_with_module", machine = storage.capped_module,
      inserted = storage.capped_module_inserted,
      expected_inserted = 1, expected_bonus = 0.54, expected_output = 152},
  }
  for _, case in ipairs(cases) do
    local output = case.machine.get_output_inventory().get_item_count(OUTPUT)
    observations.machines[case.id] = {
      module_inserted = case.inserted,
      productivity_bonus = case.machine.productivity_bonus,
      products_finished = case.machine.products_finished,
      input_remaining = case.machine.get_item_count(INPUT),
      output = output,
    }
    if case.expected_inserted ~= nil then
      check(case.inserted == case.expected_inserted,
        case.id .. " module insertion expected " .. case.expected_inserted ..
        ", found " .. case.inserted)
    end
    check(close(case.machine.productivity_bonus, case.expected_bonus),
      case.id .. " productivity bonus mismatch: " .. case.machine.productivity_bonus)
    check(case.machine.get_item_count(INPUT) == 0,
      case.id .. " retained experiment input")
    check(case.machine.products_finished == case.expected_output,
      case.id .. " products_finished expected " .. case.expected_output .. ", found " ..
      case.machine.products_finished)
    check(output == case.expected_output,
      case.id .. " expected " .. case.expected_output .. " output, found " .. output)
  end
  finish()
end

script.on_nth_tick(1, function()
  script.on_nth_tick(1, nil)
  local force = game.forces.player
  force.recipes["factorio-test-productivity-rejected"].enabled = true
  force.recipes["factorio-test-productivity-allowed"].enabled = true
  force.recipes["factorio-test-productivity-capped"].enabled = true
  local surface = game.surfaces.nauvis
  storage.rejected_plain = create_machine(surface, {0, 0},
    "factorio-test-productivity-rejected", false)
  storage.allowed_plain = create_machine(surface, {4, 0},
    "factorio-test-productivity-allowed", false)
  storage.rejected_module, storage.rejected_module_inserted =
    create_machine(surface, {8, 0}, "factorio-test-productivity-rejected", true)
  storage.allowed_module, storage.allowed_module_inserted =
    create_machine(surface, {12, 0}, "factorio-test-productivity-allowed", true)
  storage.capped_module, storage.capped_module_inserted =
    create_machine(surface, {16, 0}, "factorio-test-productivity-capped", true)

  script.on_nth_tick(180, function()
    validate()
  end)
end)

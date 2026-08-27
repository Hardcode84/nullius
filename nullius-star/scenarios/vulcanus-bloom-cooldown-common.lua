local CHEST = "iron-chest"

local function run(spec)
  local result_path = "factorio-tests/" .. spec.case .. ".json"
  local assertions = 0
  local failures = {}
  local observations = {}

  local function check(condition, message)
    assertions = assertions + 1
    if not condition then failures[#failures + 1] = message end
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

  local function item_counts()
    local result = {}
    for _, stack in pairs(storage.inventory.get_contents()) do
      result[stack.name] = (result[stack.name] or 0) + stack.count
    end
    return result
  end

  local function check_exact_counts(actual, expected, label)
    for name, count in pairs(expected) do
      check(actual[name] == count,
        label .. " expected " .. count .. " " .. name ..
        ", found " .. tostring(actual[name] or 0))
    end
    for name, count in pairs(actual) do
      check(expected[name] == count,
        label .. " contained unexpected " .. count .. " " .. name)
    end
  end

  local function check_terminal()
    script.on_nth_tick(storage.terminal_tick, nil)
    local contents = item_counts()
    observations.terminal = {
      elapsed_ticks = game.tick - storage.started_tick,
      inventory = contents,
    }
    check_exact_counts(contents, {[spec.output] = spec.count}, "terminal inventory")
    check(storage.inventory.get_item_count(spec.input) == 0,
      "terminal inventory retained bloom input")
    finish()
  end

  local function check_before_terminal()
    script.on_nth_tick(storage.before_tick, nil)
    local contents = item_counts()
    observations.before_terminal = {
      elapsed_ticks = game.tick - storage.started_tick,
      inventory = contents,
    }
    check_exact_counts(contents, {[spec.input] = spec.count},
      "pre-terminal inventory")
    check(storage.inventory.get_item_count(spec.output) == 0,
      "cooldown product appeared before the declared duration")
    script.on_nth_tick(storage.terminal_tick, check_terminal)
  end

  local function setup()
    script.on_nth_tick(1, nil)

    local input = prototypes.item[spec.input]
    local output = prototypes.item[spec.output]
    check(input ~= nil, "missing bloom prototype " .. spec.input)
    check(output ~= nil, "missing cooldown product prototype " .. spec.output)
    if not input or not output then finish() return end
    check(input.spoil_result ~= nil, "bloom has no spoil result")
    check(input.spoil_result and input.spoil_result.name == spec.output,
      "runtime bloom spoil result differs from the matrix")
    check(input.get_spoil_ticks() == spec.spoil_ticks,
      "runtime bloom spoil duration differs from the matrix")

    local planet = game.planets["nullius-vulcanus"]
    check(planet ~= nil, "missing nullius-vulcanus planet")
    if not planet then finish() return end
    local surface = planet.surface or planet.create_surface()
    check(surface ~= nil, "failed to create Vulcanus surface")
    if not surface then finish() return end
    surface.request_to_generate_chunks({0, 0}, 1)
    surface.force_generate_chunk_requests()

    local position = surface.find_non_colliding_position(CHEST, {0, 0}, 64, 1)
    check(position ~= nil, "no valid cooldown inventory position")
    if not position then finish() return end
    local chest = surface.create_entity{
      name = CHEST,
      position = position,
      force = game.forces.player,
    }
    check(chest ~= nil, "failed to place cooldown inventory")
    if not chest then finish() return end
    local inventory = chest.get_inventory(defines.inventory.chest)
    check(inventory ~= nil, "cooldown container has no chest inventory")
    if not inventory then finish() return end
    storage.inventory = inventory

    local inserted = inventory.insert{name = spec.input, count = spec.count}
    check(inserted == spec.count, "failed to insert exact bloom input")
    check_exact_counts(item_counts(), {[spec.input] = spec.count},
      "initial inventory")

    storage.started_tick = game.tick
    storage.before_tick = game.tick + spec.spoil_ticks
    storage.terminal_tick = game.tick + spec.ticks
    script.on_nth_tick(storage.before_tick, check_before_terminal)
  end

  script.on_nth_tick(1, setup)
end

return run

-- given: two test planets whose native lightning reads one storm-intensity property.
-- place: void-powered recorders whose recipe requires intensity <= 50, selected by
--   Lua set_recipe or natively through a constant-combinator recipe signal.
-- act: hold the control surface at 25; step the experiment surface 25, 100, 0, 200, 25;
--   at 100 reselect, place, and natively select recorders; script-disable one recorder.
-- run: 1200-tick windows with scheduled checks; counts come from native strike triggers.
--   during the storm, amortized visits every 150 ticks dither two recorders
--   (1 s recipe at duty 0.4, 10 s recipe at duty 0.5) through disabled_by_script.
-- expect: strikes scale linearly with the property; recipe conditions apply only at
-- native selection; disabled_by_script stops and restores output at storm edges;
-- dithered work equals enabled ticks, so crafting progress survives each disable.
local CASE = "experiment-storm-interference"
local PROPERTY = "factorio-test-storm-intensity"
local RECORDER = "factorio-test-storm-recorder"
local RECIPE = "factorio-test-storm-recording"
local INPUT = "factorio-test-storm-input"
local WINDOW = 1200
local STEPS = {25, 100, 0, 200, 25}
local VISIT = 150
local STORM_START, STORM_END = 1200, 4800

local function check(ok, message)
  storage.assertions = storage.assertions + 1
  if not ok then storage.failures[#storage.failures + 1] = message end
end

local function between(value, low, high, message)
  check(value >= low and value <= high,
    message .. ": " .. value .. " outside [" .. low .. ", " .. high .. "]")
end

local function status_name(entity)
  for name, value in pairs(defines.entity_status) do
    if value == entity.status then return name end
  end
  return tostring(entity.status)
end

local function prepare(planet)
  local surface = game.planets[planet].create_surface()
  surface.request_to_generate_chunks({0, 0}, 5)
  surface.force_generate_chunk_requests()
  for _, entity in pairs(surface.find_entities()) do entity.destroy() end
  local tiles = {}
  for x = -160, 191 do for y = -160, 191 do
    tiles[#tiles + 1] = {name = "grass-1", position = {x, y}}
  end end
  surface.set_tiles(tiles, true, false, false, false)
  surface.ignore_surface_conditions = false
  surface.freeze_daytime = true
  surface.daytime = 0.5
  surface.set_property(PROPERTY, 25)
  return surface
end

local function select_recipe(entity, recipe_name)
  entity.set_recipe(recipe_name or RECIPE)
  local recipe = entity.get_recipe()
  return entity, recipe ~= nil and recipe.name == (recipe_name or RECIPE)
end

local function recorder(surface, x, recipe_name)
  return select_recipe(assert(surface.create_entity{name = RECORDER, position = {x, 0},
    force = game.forces.player}), recipe_name)
end

-- Amortized control under test: each visit adds the duty to an error-diffusion
-- accumulator and enables the machine for the next interval when it reaches one.
local function visit_dithered()
  for _, row in pairs(storage.dithered) do
    row.accumulator = row.accumulator + row.duty
    local enabled = row.accumulator >= 1
    if enabled then row.accumulator = row.accumulator - 1 end
    row.entity.disabled_by_script = not enabled
    if enabled then row.enabled_ticks = row.enabled_ticks + VISIT end
  end
end

local function dithered(x, recipe_name, duty, seconds)
  local entity, ok = recorder(storage.surface, x, recipe_name)
  check(ok, "dithered recipe " .. recipe_name)
  check(entity.insert{name = INPUT, count = 1000} == 1000, "dithered input")
  return {entity = entity, duty = duty, seconds = seconds, accumulator = 0, enabled_ticks = 0}
end


-- Native recipe selection: a constant combinator requests the recipe over a red wire.
local function circuit_recorder(surface, x)
  local entity = assert(surface.create_entity{name = RECORDER, position = {x, 0},
    force = game.forces.player})
  entity.get_or_create_control_behavior().circuit_set_recipe = true
  local signal = assert(surface.create_entity{name = "constant-combinator",
    position = {x, 4}, force = game.forces.player})
  local behavior = signal.get_or_create_control_behavior()
  local section = behavior.get_section(1) or behavior.add_section()
  section.set_slot(1, {value = {type = "recipe", name = RECIPE, quality = "normal"}, min = 1})
  local red = defines.wire_connector_id.circuit_red
  check(entity.get_wire_connector(red, true).connect_to(signal.get_wire_connector(red, true)),
    "recipe signal wire")
  storage.unfed[#storage.unfed + 1] = entity
  return entity
end

local function recipe_name(entity)
  local recipe = entity and entity.get_recipe()
  return recipe and recipe.name or "none"
end

local function machine_state(entity)
  return {status = status_name(entity), progress = entity.crafting_progress,
    finished = entity.products_finished}
end

script.on_event(defines.events.on_script_trigger_effect, function(event)
  if event.effect_id ~= "storm-interference-strike" or not storage.window then return end
  local key = event.surface_index == storage.surface.index and "experiment" or "control"
  local row = storage.counts[storage.window]
  row[key] = row[key] + 1
end)

local function begin_window(index)
  storage.window = index
  storage.counts[index] = {experiment = 0, control = 0}
  storage.surface.set_property(PROPERTY, STEPS[index])
  storage.window_start[index] = machine_state(storage.recorder)
  storage.probe_start[index] = {toggled = storage.toggled.products_finished,
    reset = storage.reset.products_finished,
    blocked = storage.blocked and storage.blocked.products_finished or 0,
    default = storage.default and storage.default.products_finished or 0,
    circuit = storage.circuit.products_finished,
    circuit_late = storage.circuit_late and storage.circuit_late.products_finished or 0}
  storage.control_start[index] = storage.control_recorder.products_finished
end

local function close_window(index)
  local row = storage.counts[index]
  row.intensity = STEPS[index]
  row.ratio = row.control > 0 and row.experiment / row.control or -1
  row.recorded = storage.recorder.products_finished - storage.window_start[index].finished
  row.control_recorded = storage.control_recorder.products_finished - storage.control_start[index]
  row.start = storage.window_start[index]
  row.finish = machine_state(storage.recorder)
  row.end_status = {circuit = status_name(storage.circuit), circuit_recipe = recipe_name(storage.circuit),
    circuit_late = storage.circuit_late and status_name(storage.circuit_late),
    circuit_late_recipe = recipe_name(storage.circuit_late)}
  local start = storage.probe_start[index]
  row.toggled = storage.toggled.products_finished - start.toggled
  row.reset = storage.reset.products_finished - start.reset
  row.blocked = storage.blocked and storage.blocked.products_finished - start.blocked or -1
  row.circuit = storage.circuit.products_finished - start.circuit
  row.circuit_late = storage.circuit_late and storage.circuit_late.products_finished - start.circuit_late or -1
  row.default = storage.default and storage.default.products_finished - start.default or -1
  check(storage.surface.get_property(PROPERTY) == STEPS[index],
    "experiment property readback in window " .. index)
  check(storage.control.get_property(PROPERTY) == 25,
    "control property changed in window " .. index)
  check(row.control > 0, "control surface produced no strikes in window " .. index)
  between(row.control_recorded, 19, 20, "control recorder output in window " .. index)
end

local function finish()
  local c = storage.counts
  -- Native lightning: frequency is linear in value/default, unclamped above default.
  between(c[1].ratio, 0.8, 1.25, "equal properties give equal strike rates")
  between(c[2].ratio, 3.2, 4.8, "intensity 100 gives four times intensity 25")
  check(c[3].experiment == 0, "intensity 0 gives no strikes: " .. c[3].experiment)
  between(c[4].ratio, 6.4, 9.6, "intensity 200 gives eight times intensity 25")
  between(c[5].ratio, 0.8, 1.25, "restored property restores strike rate")
  -- Recipe surface conditions are not re-evaluated after selection.
  for index = 1, 5 do
    between(c[index].recorded, 19, 20, "Lua-selected recorder output in window " .. index)
    between(c[index].circuit, 19, 20, "natively selected recorder output in window " .. index)
  end
  check(storage.blocked_set_recipe.placed_at_100 and storage.blocked_set_recipe.reset_at_100 and
    storage.blocked_set_recipe.nauvis_default, "Lua set_recipe accepts blocked conditions")
  for index = 2, 5 do
    -- A constant signal does not retry selection after the property becomes valid.
    check(c[index].end_status.circuit_late_recipe == "none",
      "native selection refused at 100 stays refused in window " .. index)
    between(c[index].reset, 19, 20, "Lua reselection at 100 bypasses conditions in window " .. index)
    between(c[index].blocked, 19, 20, "Lua placement at 100 bypasses conditions in window " .. index)
    between(c[index].default, 19, 20, "Lua selection at prototype default bypasses conditions in window " .. index)
  end
  check(storage.blocked_set_recipe.nauvis_property == 100, "Nauvis reads the property default")
  -- Fallback: scripted disable at storm edges stops and restores output.
  between(c[1].toggled, 19, 20, "toggled recorder output before storm")
  for index = 2, 4 do
    check(c[index].toggled == 0, "disabled recorder crafted in window " .. index)
    check(storage.probe_status[index].toggled == "disabled_by_script" and
      storage.probe_status[index].toggled_custom, "disabled status and custom status in window " .. index)
  end
  between(c[5].toggled, 19, 20, "re-enabled recorder output")
  storage.dither_result = {}
  for name, row in pairs(storage.dithered) do
    local work = row.finished + row.progress
    local expected = row.enabled_ticks / (60 * row.seconds)
    storage.dither_result[name] = {enabled_ticks = row.enabled_ticks, finished = row.finished,
      progress = row.progress, work = work, expected = expected}
    -- Error diffusion enables floor(visits * duty) intervals.
    local visits = (STORM_END - STORM_START) / VISIT
    check(row.enabled_ticks == math.floor(visits * row.duty + 1e-9) * VISIT,
      name .. " enabled ticks follow duty: " .. row.enabled_ticks)
    between(work, expected - 0.05, expected + 0.05, name .. " work equals enabled ticks")
  end
  local result = {schema = 1, case = CASE, status = #storage.failures == 0 and "pass" or "fail",
    tick = game.tick, factorio_version = script.active_mods.base,
    assertions = storage.assertions, failure_count = #storage.failures,
    failures = storage.failures, observations = {windows = c,
      blocked_set_recipe = storage.blocked_set_recipe, dithered = storage.dither_result, fed_tick = storage.fed_tick, probe_status = storage.probe_status}}
  helpers.write_file("factorio-tests/" .. CASE .. ".json", helpers.table_to_json(result), false)
  if #storage.failures > 0 then error(helpers.table_to_json(result)) end
end

script.on_nth_tick(1, function()
  script.on_nth_tick(1, nil)
  storage.assertions = 0; storage.failures = {}; storage.counts = {}
  storage.window_start = {}; storage.control_start = {}
  storage.probe_start = {}; storage.unfed = {}; storage.fed_tick = {}
  -- Nullius resets force recipes; enable the fixture explicitly.
  game.forces.player.recipes[RECIPE].enabled = true
  game.forces.player.recipes["factorio-test-storm-recording-long"].enabled = true
  storage.surface = prepare("factorio-test-storm-planet")
  storage.control = prepare("factorio-test-storm-control-planet")
  local ok
  storage.recorder, ok = recorder(storage.surface, 0)
  check(ok, "recipe accepted at intensity 25")
  storage.control_recorder, ok = recorder(storage.control, 0)
  check(ok, "control recipe accepted at intensity 25")
  storage.toggled = recorder(storage.surface, 16)
  storage.reset = recorder(storage.surface, 24)
  storage.circuit = circuit_recorder(storage.surface, 32)
  for _, entity in pairs({storage.recorder, storage.toggled, storage.reset}) do
    check(entity.insert{name = INPUT, count = 1000} == 1000, "experiment input")
  end
  check(storage.control_recorder.insert{name = INPUT, count = 1000} == 1000, "control input")
  begin_window(1)
end)

local function feed()
  local waiting = {}
  for _, entity in pairs(storage.unfed) do
    if entity.get_recipe() then
      check(entity.insert{name = INPUT, count = 1000} == 1000, "circuit recorder input")
      storage.fed_tick[entity.position.x] = game.tick
    else
      waiting[#waiting + 1] = entity
    end
  end
  storage.unfed = waiting
end

script.on_nth_tick(30, function()
  local tick = game.tick
  if tick < 30 then return end
  feed()
  if tick == STORM_START then
    storage.dithered = {short = dithered(48, RECIPE, 0.4, 1),
      long = dithered(56, "factorio-test-storm-recording-long", 0.5, 10)}
  end
  if tick >= STORM_START and tick < STORM_END and tick % VISIT == 0 then
    visit_dithered()
  elseif tick == STORM_END then
    for _, row in pairs(storage.dithered) do
      row.finished = row.entity.products_finished
      row.progress = row.entity.crafting_progress
      row.entity.disabled_by_script = false
    end
  end
  local index = math.floor(tick / WINDOW)
  if tick % WINDOW == 0 then
    close_window(index)
    if index == #STEPS then
      storage.window = nil
      script.on_nth_tick(30, nil)
      return finish()
    end
    begin_window(index + 1)
    if index == 1 then
      -- Fallback under test: script disables the machine at the storm edge.
      storage.toggled.disabled_by_script = true
      storage.toggled.custom_status = {diode = defines.entity_status_diode.red,
        label = "Storm interference"}
      storage.reset.set_recipe(nil)
      local reset_ok = select(2, select_recipe(storage.reset))
      storage.reset.insert{name = INPUT, count = 1000}
      local entity, ok = recorder(storage.surface, 8)
      entity.insert{name = INPUT, count = 1000}
      storage.blocked = entity
      local default, default_ok = recorder(game.surfaces.nauvis, 0)
      default.insert{name = INPUT, count = 1000}
      storage.default = default
      storage.circuit_late = circuit_recorder(storage.surface, 40)
      storage.blocked_set_recipe = {placed_at_100 = ok, reset_at_100 = reset_ok,
        nauvis_default = default_ok,
        nauvis_property = game.surfaces.nauvis.get_property(PROPERTY)}
    elseif index == 4 then
      storage.toggled.disabled_by_script = false
      storage.toggled.custom_status = nil
    end
    storage.probe_status = storage.probe_status or {}
    storage.probe_status[index + 1] = {toggled = status_name(storage.toggled),
      toggled_custom = storage.toggled.custom_status ~= nil,
      reset = status_name(storage.reset),
      blocked = storage.blocked and status_name(storage.blocked),
      default = storage.default and status_name(storage.default),
      circuit = status_name(storage.circuit), circuit_recipe = recipe_name(storage.circuit),
      circuit_late = storage.circuit_late and status_name(storage.circuit_late),
      circuit_late_recipe = recipe_name(storage.circuit_late)}
  end
end)

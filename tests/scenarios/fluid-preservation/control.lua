require("__nullius-star__/scripts/mirror")
local fluids = require("__nullius-star__/scenarios/fluid-api")
local assertions = 0
local function check(ok, message)
  assertions = assertions + 1
  assert(ok, message)
end
local function expect(entity, index, wanted)
  local actual = fluids.get(entity, index)
  if not wanted then
    check(actual == nil, "slot " .. index .. " must be empty")
  else
    check(actual and actual.name == wanted.name, "fluid identity at slot " .. index)
    check(math.abs(actual.amount - wanted.amount) < 0.000001, "fluid amount at slot " .. index)
    check(math.abs(actual.temperature - wanted.temperature) < 0.000001, "fluid temperature at slot " .. index)
  end
end
script.on_nth_tick(1, function()
  script.on_nth_tick(1, nil)
  local surface = game.surfaces.nauvis
  surface.request_to_generate_chunks({0,0}, 1)
  surface.force_generate_chunk_requests()
  for _, entity in pairs(surface.find_entities_filtered{area={{-5,-5},{5,5}}}) do entity.destroy() end
  local water = {name="water", amount=37, temperature=72}
  local steam = {name="steam", amount=83, temperature=165}
  -- Leading empty, trailing empty, both occupied, and both empty snapshots.
  for _, pattern in ipairs({{false, steam}, {water, false}, {water, steam}, {false, false}}) do
    local source = surface.create_entity{name="compat-fluid-source", position={0,0}, force="player"}
    check(source ~= nil, "source placement")
    source.disabled_by_script = true
    check(fluids.count(source) == 2, "fixture has two fluid slots")
    for index=1,2 do fluids.set(source, index, pattern[index] or nil) end
    local snapshot = save_fluid_contents(source)
    check(snapshot.count == 2, "snapshot retains empty slots")
    -- Restore must clear empty slots, including trailing empty slots.
    fluids.set(source, 1, water)
    fluids.set(source, 2, steam)
    restore_fluid_contents(source, snapshot)
    for index=1,2 do expect(source, index, pattern[index]) end
    local target = replace_fluid_entity(source, "compat-fluid-target", game.forces.player)
    check(target and target.valid, "replacement succeeds")
    check(not source.valid, "replacement removes original entity")
    check(target.name == "compat-fluid-target", "replacement has requested prototype")
    for index=1,2 do expect(target, index, pattern[index]) end
    target.destroy()
  end
  check(save_fluid_contents(nil).count == 0, "nil entity has no fluid slots")
  local pipe = surface.create_entity{name="pipe", position={0,0}, force="player"}
  check(pipe ~= nil and fluids.count(pipe) == 1, "one-slot destination")
  local source = surface.create_entity{name="compat-fluid-source", position={3,0}, force="player"}
  source.disabled_by_script = true
  fluids.set(source, 1, water)
  fluids.set(source, 2, steam)
  local ok, message = pcall(restore_fluid_contents, pipe, save_fluid_contents(source))
  check(not ok and string.find(message, "replacement has no fluid slot 2", 1, true),
    "occupied missing slot must fail before restoration")
  expect(pipe, 1, nil)
  source.destroy()
  check(save_fluid_contents(source).count == 0, "invalid entity has no fluid slots")
  restore_fluid_contents(source, nil)
  restore_fluid_contents(nil, save_fluid_contents(pipe))
  pipe.destroy()
  local result = {schema=1, case="fluid-preservation", status="pass",
    factorio_version=script.active_mods.base, tick=game.tick, assertions=assertions,
    failure_count=0, failures={}, observations={patterns=4}}
  helpers.write_file("factorio-tests/fluid-preservation.json", helpers.table_to_json(result), false)
end)

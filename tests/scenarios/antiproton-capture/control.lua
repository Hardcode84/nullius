-- given: Antimatter Containment researched by a fresh force; a starter platform stopped at Fulgora;
--   a collector whose capture is declared nearly complete, because one capture outlasts the
--   scenario tick limit.
-- place: a powered antiproton collector and a thruster with one declared propellant batch on the
--   platform; a powered priority electrolyzer and a reactor on Nauvis; a chest of nearly spoiled
--   antimatter.
-- act: fill a trap at Fulgora, schedule the platform to Nauvis, then place it at Nauvis and back at
--   Fulgora; recharge a nearly spoiled trap.
-- run: through one capture at Fulgora and one recharge, then each location change.
-- expect: collectors place only on the platform and run only at Fulgora, with a status elsewhere;
--   antimatter outlasts the recording spoil time and spoils to an empty trap at the prototype
--   time; recharge returns it fresh;
--   reactors reject traps.
local transit = require("__nullius-star__/shared/reference-transit")
local CASE = "antiproton-capture"
local COLLECTOR = "nullius-antiproton-collector"
local SPOIL_MARGIN = 120
-- Native capture ticks left after the declared progress.
local CAPTURE_REMAINDER = 300
-- The collector's full draw, so it captures at full speed.
local GRID_POWER = 50000000

local function check(ok, message)
  storage.assertions = storage.assertions + 1
  assert(ok, message)
end

local function power(surface, force, x, y)
  local grid = assert(surface.create_entity{name = "factorio-test-planner-grid", position = {x + 8, y}, force = force})
  grid.power_production = GRID_POWER
  grid.electric_buffer_size = GRID_POWER
  assert(surface.create_entity{name = "substation", position = {x + 5, y + 4}, force = force})
end

-- Ticks one craft takes in a placed machine.
local function craft_ticks(entity, recipe)
  return math.ceil(prototypes.recipe[recipe].energy / entity.crafting_speed * 60)
end

local function named(values, value)
  for name, number in pairs(values) do if number == value then return name end end
end

local function status(entity)
  return named(defines.entity_status, entity.status)
end

local function stage(name)
  storage.stage = name
  storage.stage_tick = game.tick
end

local function gated(collector, stopped, where)
  check(collector.disabled_by_script == stopped, "collector disabled " .. tostring(stopped) .. " " .. where)
  local status = collector.custom_status
  check((status ~= nil) == stopped, "collector status " .. where)
end

local function setup()
  storage.assertions = 0
  storage.states = {}
  local force = game.create_force(CASE)
  for _, name in ipairs({COLLECTOR, "nullius-antiproton-capture", "nullius-antimatter-recharge", "nullius-antimatter-trap"}) do
    check(not force.recipes[name].enabled, name .. " locked before research")
  end
  force.technologies["nullius-antimatter-containment"].researched = true
  for _, name in ipairs({COLLECTOR, "nullius-antiproton-capture", "nullius-antimatter-recharge", "nullius-antimatter-trap"}) do
    check(force.recipes[name].enabled, name .. " unlocked by Antimatter Containment")
  end
  local item = prototypes.item["nullius-antimatter"]
  storage.spoil_ticks = item.get_spoil_ticks()
  check(storage.spoil_ticks > transit.spoil_ticks, "antimatter outlasts the recording spoil time, so deliveries need no recharge en route")
  check(item.spoil_result and item.spoil_result.name == "nullius-antimatter-trap", "antimatter spoils to an empty trap")
  check(prototypes.item["nullius-antimatter-trap"].fuel_value == 0, "the trap is not fuel")

  local ground = game.surfaces.nauvis
  ground.request_to_generate_chunks({0, 0}, 2)
  ground.force_generate_chunk_requests()
  for _, entity in pairs(ground.find_entities_filtered{area = {{-30, -30}, {30, 30}}}) do entity.destroy() end
  local tiles = {}
  for x = -30, 30 do for y = -30, 30 do tiles[#tiles + 1] = {name = "concrete", position = {x, y}} end end
  ground.set_tiles(tiles)
  check(not ground.can_place_entity{name = COLLECTOR, position = {-20, -20}, force = force}, "no collector on a planet")
  local reactor = assert(ground.create_entity{name = "nullius-reactor", position = {-20, 10}, force = force})
  check(reactor.get_fuel_inventory().insert{name = "nullius-antimatter-trap", count = 1} == 0, "reactors reject traps")

  local electrolyzer = assert(ground.create_entity{name = "nullius-priority-electrolyzer-1", position = {0, 0}, force = force})
  power(ground, force, 0, 0)
  electrolyzer.set_recipe("nullius-antimatter-recharge")
  check(electrolyzer.insert{name = "nullius-antimatter", count = 1, spoil_percent = 0.9} == 1, "nearly spoiled trap accepted")
  storage.electrolyzer = electrolyzer
  storage.recharge_tick = game.tick + math.ceil(craft_ticks(electrolyzer, "nullius-antimatter-recharge") / 30) * 30 + 60
  storage.spoil_tick = game.tick

  local chest = assert(ground.create_entity{name = "wooden-chest", position = {10, 20}, force = force})
  local stack = chest.get_inventory(defines.inventory.chest)[1]
  stack.set_stack{name = "nullius-antimatter", count = 1}
  stack.spoil_percent = 1 - SPOIL_MARGIN / storage.spoil_ticks
  storage.chest = chest

  force.unlock_space_location("nullius-fulgora")
  force.unlock_space_location("nauvis")
  local platform = assert(force.create_space_platform{name = CASE, planet = "nullius-fulgora",
    starter_pack = "space-platform-starter-pack"})
  platform.apply_starter_pack(true)
  local surface = platform.surface
  local foundation = {}
  for x = -12, 16 do for y = 6, 22 do foundation[#foundation + 1] = {name = "space-platform-foundation", position = {x, y}} end end
  surface.set_tiles(foundation)
  check(surface.can_place_entity{name = COLLECTOR, position = {0, 12}, force = force}, "collector on the platform")
  local collector = assert(surface.create_entity{name = COLLECTOR, position = {0, 12}, force = force, raise_built = true})
  power(surface, force, 0, 12)
  check(collector.get_recipe().name == "nullius-antiproton-capture", "collector has its fixed recipe")
  check(collector.insert{name = "nullius-antimatter-trap", count = 2} == 2, "collector accepts empty traps")
  -- A platform without thrust waits for departure, so leaving orbit needs propellant.
  check(surface.can_place_entity{name = "thruster", position = {-8, 20.5}, force = force}, "thruster placement")
  local thruster = assert(surface.create_entity{name = "thruster", position = {-8, 20.5}, force = force})
  for _, fluid in ipairs({"thruster-fuel", "thruster-oxidizer"}) do
    check(thruster.insert_fluid{name = fluid, amount = 1000} > 0, "declared " .. fluid)
  end
  gated(collector, false, "at Fulgora")
  storage.platform = platform
  storage.collector = collector
  storage.capture_ticks = craft_ticks(collector, "nullius-antiproton-capture")
  stage("capture")
end

local function finish()
  helpers.write_file("factorio-tests/" .. CASE .. ".json", helpers.table_to_json{
    schema = 1, case = CASE, status = "pass", failure_count = 0, assertions = storage.assertions,
    tick = game.tick, factorio_version = script.active_mods.base,
    observations = {platform_states = storage.states}}, false)
  stage("done")
end

script.on_event(defines.events.on_space_platform_changed_state, function(event)
  if storage.states then
    storage.states[#storage.states + 1] = {tick = event.tick, state = event.platform.state, old = event.old_state}
  end
end)

-- Spoilage and recharge run on their own clocks beside the collector stages.
local function check_ground()
  local elapsed = game.tick - storage.spoil_tick
  if elapsed == SPOIL_MARGIN / 2 then
    check(storage.chest.get_item_count("nullius-antimatter") == 1, "antimatter before its spoil time")
  end
  if elapsed == SPOIL_MARGIN + 60 then
    check(storage.chest.get_item_count("nullius-antimatter") == 0, "antimatter spoiled at its spoil time")
    check(storage.chest.get_item_count("nullius-antimatter-trap") == 1, "spoilage left an empty trap")
  end
  if game.tick == storage.recharge_tick then
    local electrolyzer = storage.electrolyzer
    check(electrolyzer.products_finished == 1, "one recharge: " .. tostring(status(electrolyzer)))
    local recharged = electrolyzer.get_output_inventory().find_item_stack("nullius-antimatter")
    check(recharged ~= nil, "recharged trap in the output")
    check(recharged.spoil_percent < 60 / storage.spoil_ticks + 0.001, "recharge resets spoilage: " .. recharged.spoil_percent)
    storage.recharged = true
  end
end

script.on_nth_tick(30, function(event)
  if event.tick == 0 then return end
  if not storage.stage then setup() return end
  check_ground()
  local elapsed = game.tick - storage.stage_tick
  local collector, platform = storage.collector, storage.platform
  if storage.stage == "capture" then
    if not storage.declared then
      check(collector.is_crafting(), "collector started a capture")
      collector.crafting_progress = 1 - CAPTURE_REMAINDER / storage.capture_ticks
      storage.declared = game.tick
      return
    end
    if game.tick - storage.declared < CAPTURE_REMAINDER + 60 then return end
    check(collector.products_finished == 1, "one capture at Fulgora: " .. tostring(status(collector)))
    check(collector.get_output_inventory().get_item_count("nullius-antimatter") == 1, "a filled trap")
    platform.schedule = {current = 1, records = {{station = "nauvis"}}}
    platform.paused = false
    stage("departing")
  elseif storage.stage == "departing" then
    if platform.space_location then
      check(elapsed < 600, "platform left Fulgora orbit: " .. tostring(named(defines.space_platform_state, platform.state)))
      return
    end
    gated(collector, true, "in transit")
    storage.progress = collector.crafting_progress
    stage("transit")
  elseif storage.stage == "transit" then
    if elapsed < 300 then return end
    check(collector.crafting_progress == storage.progress, "no capture progress in transit")
    platform.paused = true
    platform.space_location = "nauvis"
    stage("nauvis")
  elseif storage.stage == "nauvis" then
    gated(collector, true, "at Nauvis")
    platform.space_location = "nullius-fulgora"
    stage("return")
  elseif storage.stage == "return" then
    gated(collector, false, "back at Fulgora")
    stage("recharge")
  elseif storage.stage == "recharge" then
    if storage.recharged then finish() end
  end
end)

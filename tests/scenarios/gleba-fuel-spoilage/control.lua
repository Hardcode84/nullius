-- given: Gleba access, declared goop and cultures near the end of their spoil
-- time, declared crushed rock, and declared electricity for one inserter.
-- place: nutrient labs, a nutrient flotation cell, a nutrient chemical plant,
-- an inserter and chests on cleared Gleba ground.
-- act: let fuel and cultures spoil, then empty one lab with the inserter and
-- run sludge digestion and digestate recycling.
-- run: 1900 ticks.
-- expect: spoiled goop moves to free burnt-result space and otherwise blocks
-- the fuel slot until removed; dead culture returns to goop through digestate.
local research = require("__nullius-star__/scripts/research")
local CASE = "gleba-fuel-spoilage"
local GOOP, DIGESTATE, WILD = "nullius-nutrient-goop", "nullius-digestate", "nullius-wild-culture"
local SLUDGE = "nullius-culture-sludge"
local NEAR_SPOILED = 0.997

local function check(ok, message)
  storage.assertions = storage.assertions + 1
  if not ok then storage.failures[#storage.failures + 1] = message end
end

local function finish(tick)
  local failed = #storage.failures > 0
  helpers.write_file("factorio-tests/" .. CASE .. ".json", helpers.table_to_json{
    schema = 1, case = CASE, status = failed and "fail" or "pass", failure_count = #storage.failures,
    failures = storage.failures, assertions = storage.assertions, tick = tick,
    factorio_version = script.active_mods.base}, false)
  script.on_nth_tick(1, nil)
  if failed then error(helpers.table_to_json(storage.failures)) end
end

local function count(inventory, name) return inventory.get_item_count(name) end
local function fuel(e) return e.get_fuel_inventory() end
local function burnt(e) return e.get_burnt_result_inventory() end

local function create(name, position)
  return assert(storage.surface.create_entity{name = name, position = position, force = "player"}, name)
end

local function prepare()
  local s = game.planets["nullius-gleba"].surface
  storage.surface = s
  s.request_to_generate_chunks({60, 60}, 2)
  s.force_generate_chunk_requests()
  for _, e in pairs(s.find_entities_filtered{area = {{40, 40}, {90, 90}}}) do
    if e.type ~= "character" then e.destroy() end
  end
  local tiles = {}
  for x = 40, 90 do for y = 40, 90 do tiles[#tiles + 1] = {name = "highland-dark-rock", position = {x, y}} end end
  s.set_tiles(tiles)

  -- The idle lab has burnt-result space; the blocked lab has none.
  storage.idle = create("nullius-lab-1-nutrient", {50, 50})
  fuel(storage.idle).insert{name = GOOP, count = 5, spoil_percent = NEAR_SPOILED}
  storage.blocked = create("nullius-lab-1-nutrient", {70, 50})
  burnt(storage.blocked).insert{name = DIGESTATE, count = 100}
  fuel(storage.blocked).insert{name = GOOP, count = 5, spoil_percent = NEAR_SPOILED}

  storage.cultures = create("iron-chest", {50, 70})
  storage.cultures.insert{name = WILD, count = 4, spoil_percent = NEAR_SPOILED}
  storage.cell = create("nullius-flotation-cell-1-nutrient", {60, 70})
  storage.chemical = create("nullius-chemical-plant-1-nutrient", {70, 70})
  for _, machine in ipairs({storage.cell, storage.chemical}) do fuel(machine).insert{name = GOOP, count = 2} end
end

-- An ordinary inserter, powered by a declared interface, empties the blocked lab.
local function drain()
  local power = create("electric-energy-interface", {75, 55})
  power.power_production, power.electric_buffer_size, power.energy = 1e7, 1e9, 1e9
  create("small-electric-pole", {72, 53})
  storage.inserter = assert(storage.surface.create_entity{name = "inserter", position = {70, 52},
    direction = defines.direction.north, force = "player"})
  storage.drain = create("iron-chest", {70, 53})
  local box, pickup = storage.blocked.bounding_box, storage.inserter.pickup_position
  check(pickup.x > box.left_top.x and pickup.x < box.right_bottom.x and pickup.y > box.left_top.y
    and pickup.y < box.right_bottom.y, "inserter does not pick up from the blocked lab")
end

script.on_init(function() storage.assertions, storage.failures = 0, {} end)

script.on_nth_tick(1, function(event)
  if event.tick == 0 then return end
  if event.tick == 1 then
    research.complete_with_prerequisites(game.forces.player.technologies["nullius-probe-gleba"])
  elseif event.tick == 2 then
    prepare()
  elseif event.tick == 600 then
    -- expect: spoiled goop in the idle lab moved to its burnt-result slot.
    check(count(fuel(storage.idle), GOOP) == 0 and count(fuel(storage.idle), DIGESTATE) == 0,
      "spoiled goop stayed in the idle lab's fuel slot")
    check(count(burnt(storage.idle), DIGESTATE) == 4, "idle lab did not receive spoiled goop as digestate")
    check(fuel(storage.idle).insert{name = GOOP, count = 1} == 1, "idle lab refused fresh goop")
    -- expect: with a full burnt-result slot the digestate stays in the fuel slot.
    check(count(fuel(storage.blocked), DIGESTATE) == 4, "blocked lab moved spoiled goop out of its fuel slot")
    check(fuel(storage.blocked).insert{name = GOOP, count = 1} == 0, "blocked fuel slot accepted goop")
    -- expect: the cultures died into culture sludge.
    local box = storage.cultures.get_inventory(defines.inventory.chest)
    check(count(box, WILD) == 0 and count(box, SLUDGE) == 4, "wild culture did not spoil into culture sludge")
    storage.cell.set_recipe("nullius-gleba-sludge-digestion")
    check(storage.cell.insert{name = SLUDGE, count = 4} == 4, "flotation cell refused culture sludge")
    box.clear()
    drain()
  elseif event.tick == 1200 then
    local digested = storage.cell.get_output_inventory()
    check(count(digested, DIGESTATE) == 2, "sludge digestion did not make digestate")
    storage.chemical.set_recipe("nullius-gleba-digestate-recycling")
    -- Declared inputs: the two digested units plus spent fuel from the idle lab.
    local spent = count(burnt(storage.idle), DIGESTATE)
    check(storage.chemical.insert{name = DIGESTATE, count = 2} == 2, "chemical plant refused digestate")
    check(storage.chemical.insert{name = DIGESTATE, count = 3} == 3 and spent >= 3, "missing spent digestate")
    burnt(storage.idle).remove{name = DIGESTATE, count = 3}
    digested.clear()
    check(storage.chemical.insert{name = "nullius-crushed-gleba-rock", count = 1} == 1, "chemical plant refused rock")
    check(storage.chemical.insert{name = WILD, count = 1} == 1, "chemical plant refused wild culture")
  elseif event.tick == 1900 then
    -- expect: the inserter cleared the fuel slot first, then started on spent fuel.
    local drained = count(storage.drain.get_inventory(defines.inventory.chest), DIGESTATE)
    check(count(fuel(storage.blocked), DIGESTATE) == 0, "inserter left digestate in the fuel slot")
    local held = storage.inserter.held_stack.valid_for_read and storage.inserter.held_stack.count or 0
    check(drained > 4 and count(burnt(storage.blocked), DIGESTATE) + drained + held == 104,
      "inserter did not continue with the burnt-result slot")
    check(fuel(storage.blocked).insert{name = GOOP, count = 1} == 1, "emptied fuel slot refused goop")
    check(count(storage.chemical.get_output_inventory(), GOOP) == 4, "digestate recycling did not return goop")
    finish(event.tick)
  end
end)

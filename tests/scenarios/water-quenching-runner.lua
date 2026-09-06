return function(CASE, spec)
local BLOOM = "nullius-molten-" .. spec.metal .. "-bloom"
local PRODUCT = "nullius-" .. spec.metal .. "-" .. spec.shape
local WET = "nullius-quenched-" .. spec.metal .. "-" .. spec.shape
local BULK = "nullius-boxed-quenched-" .. spec.metal .. "-" .. spec.shape
local BOX = "nullius-box-" .. spec.metal .. "-" .. spec.shape
local COOLED = spec.metal == "iron" and "nullius-iron-ingot" or "nullius-alumina"
local WATER = "nullius-water"
local assertions, failures = 0, {}
local observations = {}
local function check(ok, message)
  assertions = assertions + 1
  if not ok then failures[#failures + 1] = message end
end
local function finish()
  local result = {schema = 1, case = CASE, tick = game.tick, factorio_version = script.active_mods.base,
    status = #failures == 0 and "pass" or "fail", assertions = assertions,
    failure_count = #failures, failures = failures, observations = observations}
  helpers.write_file("factorio-tests/" .. CASE .. ".json", helpers.table_to_json(result), false)
  if #failures > 0 then error(helpers.table_to_json(result)) end
end
local function build(name, x, y, direction)
  local ghost = storage.surface.create_entity{name = "entity-ghost", inner_name = name,
    position = {1000 + x, 1000 + y}, direction = direction, force = game.forces.player, expires = false}
  assert(ghost, "Cannot place " .. name)
  local _, entity = ghost.revive{raise_revive = true}
  assert(entity, "Cannot revive " .. name)
  return entity
end
local function research(technology, visited)
  if visited[technology.name] then return end
  visited[technology.name] = true
  for _, prerequisite in pairs(technology.prerequisites) do research(prerequisite, visited) end
  technology.researched = true
end
local offsets = {[defines.direction.north] = {0, -1}, [defines.direction.east] = {1, 0},
  [defines.direction.south] = {0, 1}, [defines.direction.west] = {-1, 0}}
local function foundry(x, recipe, blooms, water)
  local machine = build("nullius-foundry-1-thermal", x, 0)
  machine.set_recipe(recipe)
  check(machine.get_recipe().name == recipe, "Foundry rejected " .. recipe)
  local connection = machine.prototype.heat_energy_source_prototype.connections[1]
  local delta = offsets[connection.direction]
  local hx, hy = x + connection.position[1] + delta[1], connection.position[2] + delta[2]
  build("nullius-heat-pipe-1", hx, hy)
  local heat = build("heat-interface", hx + delta[1], hy + delta[2])
  heat.set_heat_setting{temperature = 250, mode = "at-least"}
  machine.temperature = 250
  local pipe = build("pipe", x - 2, 1)
  if water > 0 then
    check(pipe.insert_fluid{name = WATER, amount = water} == water, "Water fixture did not fit")
  end
  check(machine.insert{name = BLOOM, count = blooms} == blooms, "Bloom fixture did not fit")
  return {machine = machine, pipe = pipe}
end
local function fuel(inserter)
  inserter.fluidbox[1] = {name = "nullius-compressed-volcanic-gas", amount = 200, temperature = 200}
end
local function snapshot(cell)
  return {cycles = cell.machine.products_finished,
    input = cell.machine.get_inventory(defines.inventory.assembling_machine_input).get_contents(),
    output = cell.machine.get_output_inventory().get_contents(),
    water = cell.machine.get_fluid_count(WATER) + cell.pipe.get_fluid_count(WATER)}
end
script.on_nth_tick(1, function()
  if game.tick == 0 then return end
  script.on_nth_tick(1, nil)
  local planet = game.planets["nullius-vulcanus"]
  storage.surface = planet.surface or planet.create_surface()
  local surface = storage.surface
  surface.request_to_generate_chunks({1024, 1000}, 2)
  surface.force_generate_chunk_requests()
  local tiles = {}
  for x = -8, 60 do for y = -8, 8 do
    tiles[#tiles + 1] = {name = "volcanic-soil-dark", position = {1000 + x, 1000 + y}}
  end end
  surface.set_tiles(tiles, true, false, false, false)
  for _, entity in pairs(surface.find_entities_filtered{area = {{992, 992}, {1060, 1008}},
      type = {"simple-entity", "tree", "cliff", "resource"}}) do entity.destroy() end
  local force = game.forces.player
  research(force.technologies["nullius-hot-metalworking"], {})
  check(not force.recipes[WET].enabled, "Quenching unlocked with dry casting")
  research(force.technologies["nullius-water-quenching"], {})
  check(force.recipes[WET].enabled, "Quenching research did not unlock recipe")
  check(not force.recipes[BULK].enabled, "Bulk quenching unlocked before mass production")
  -- Do not research later productivity bonuses in this exact-yield fixture.
  force.technologies["nullius-mass-production-4"].researched = true
  check(force.recipes[BULK].enabled, "Mass production did not unlock bulk quenching")
  local dry = force.recipes["nullius-hot-" .. spec.metal .. "-" .. spec.shape]
  local wet = force.recipes[WET]
  check(dry.energy == wet.energy and wet.energy == spec.seconds, "Dry and wet cycle times differ")
  storage.dry = foundry(0, dry.name, 4, 0)
  storage.wet = foundry(12, wet.name, 4, 2)
  storage.bulk = foundry(24, BULK, 20, 10)
  storage.outage = foundry(40, wet.name, 4, 0)
  -- Real pneumatic inserters remove products and cooled input. No scripted clearing.
  storage.sink = build("iron-chest", 40, 3)
  storage.output_inserter = build("inserter-pneumatic", 40, 2, defines.direction.north)
  fuel(storage.output_inserter)
  storage.source = build("iron-chest", 43, 0)
  storage.input_inserter = build("inserter-pneumatic", 42, 0, defines.direction.east)
  fuel(storage.input_inserter)
end)
script.on_nth_tick(300, function()
  if game.tick == 0 then return end
  script.on_nth_tick(300, nil)
  observations.first_cycle = {dry = snapshot(storage.dry), wet = snapshot(storage.wet)}
  check(storage.dry.machine.products_finished == 1, "Dry casting did not finish one cycle")
  check(storage.wet.machine.products_finished == 1, "Wet casting did not finish one cycle")
  check(storage.dry.machine.get_output_inventory().get_item_count(PRODUCT) == spec.dry, "Wrong dry product yield")
  check(storage.wet.machine.get_output_inventory().get_item_count(PRODUCT) == spec.wet, "Wrong quenched yield")
  check(observations.first_cycle.wet.water < 0.000001, "Quenching did not consume exactly 2 water")
  check(storage.outage.machine.products_finished == 0, "Quenching ran without water")
end)
script.on_nth_tick(2700, function()
  if game.tick == 0 then return end
  script.on_nth_tick(2700, nil)
  observations.outage = snapshot(storage.outage)
  observations.outage.inserter = {pickup = storage.output_inserter.pickup_position,
    drop = storage.output_inserter.drop_position, status = storage.output_inserter.status,
    energy = storage.output_inserter.energy, fuel = storage.output_inserter.fluidbox[1]}
  observations.outage.recovered_items = storage.sink.get_item_count(COOLED)
  check(storage.outage.machine.products_finished == 0, "Dry outage produced quenched products")
  check(observations.outage.recovered_items == 4, "Inserter did not remove four cooled blooms")
  observations.bulk = snapshot(storage.bulk)
  check(storage.bulk.machine.products_finished == 1, "Bulk recipe did not finish one cycle")
  check(storage.bulk.machine.get_output_inventory().get_item_count(BOX) == spec.wet,
    "Bulk recipe did not produce the expected boxes")
  check(observations.bulk.water < 0.000001, "Bulk recipe did not consume exactly 10 water")
  check(storage.source.insert{name = BLOOM, count = 4} == 4, "Restart bloom fixture did not fit")
  check(storage.outage.pipe.insert_fluid{name = WATER, amount = 2} == 2, "Restart water fixture did not fit")
end)
script.on_nth_tick(3600, function()
  if game.tick == 0 then return end
  script.on_nth_tick(3600, nil)
  observations.restart = snapshot(storage.outage)
  observations.restart.products = storage.sink.get_item_count(PRODUCT)
  observations.restart.cooled_items = storage.sink.get_item_count(COOLED)
  check(storage.outage.machine.products_finished == 1, "Foundry did not restart after water returned")
  check(observations.restart.products == spec.wet, "Restart products did not reach the output chest")
  check(observations.restart.cooled_items == 4, "Recovery lost cooled items")
  check(storage.source.get_item_count(BLOOM) == 0, "Input inserter did not deliver new blooms")
  finish()
end)
end

-- given: one rocket stage, ten logistic bots, a storage chest holding iron
--   plates, a declared external grid, and a platform above Nauvis.
-- place: production silo, hangar, storage chest, and substation on Nauvis.
-- connect: the silo inside the hangar's logistic network; one powered grid.
-- act: the platform hub requests exactly ten iron plates from Nauvis with that
--   minimum payload; the silo requests items for platforms in orbit. The
--   toggle reads back false unless the silo has a logistic trash inventory.
-- run: check every 60 ticks until the deadline.
-- expect: robots load the silo for the request, the silo launches without a
--   script launch call, and the hub receives exactly the requested plates.
local CASE = "silo-platform-request"
local REQUEST = 10
local STOCK = 100
local DEADLINE = 8940

local function check(ok, message)
  storage.assertions = storage.assertions + 1
  assert(ok, message)
end

local function hub_plates()
  return storage.hub.get_inventory(defines.inventory.hub_main).get_item_count("iron-plate")
end

script.on_init(function()
  storage.assertions = 0
  local surface = game.surfaces.nauvis
  surface.request_to_generate_chunks({0, 0}, 2)
  surface.force_generate_chunk_requests()
  for _, entity in pairs(surface.find_entities_filtered{area = {{-20, -20}, {20, 20}}}) do
    entity.destroy()
  end
  local tiles = {}
  for x = -20, 20 do for y = -20, 20 do
    tiles[#tiles + 1] = {name = "grass-1", position = {x, y}}
  end end
  surface.set_tiles(tiles)
  local force = game.forces.player
  force.technologies["nullius-rocket-science-2"].researched = true

  local platform = assert(force.create_space_platform{
    name = CASE, planet = "nauvis", starter_pack = "space-platform-starter-pack"})
  storage.hub = assert(platform.apply_starter_pack(true))
  local section = storage.hub.get_logistic_sections().add_section()
  section.set_slot(1, {value = {type = "item", name = "iron-plate", quality = "normal"},
    min = REQUEST, max = REQUEST, minimum_delivery_count = REQUEST, import_from = "nauvis"})

  local grid = assert(surface.create_entity{
    name = "factorio-test-planner-grid", position = {12, 10}, force = force})
  grid.power_production = 1e9
  grid.electric_buffer_size = 1e9
  assert(surface.create_entity{name = "substation", position = {7, 5}, force = force})
  storage.silo = assert(surface.create_entity{name = "nullius-silo", position = {0, 0}, force = force})
  storage.hangar = assert(surface.create_entity{name = "nullius-hangar-2", position = {8, 0}, force = force})
  storage.chest = assert(surface.create_entity{
    name = "nullius-large-storage-chest-1", position = {11, 0}, force = force})
  check(storage.hangar.insert{name = "nullius-logistic-bot-1", count = 10} == 10, "bots in hangar")
  check(storage.chest.insert{name = "iron-plate", count = STOCK} == STOCK, "plate stock")
  storage.silo.use_transitional_requests = true
  check(storage.silo.use_transitional_requests, "silo supports platform requests")
  check(storage.silo.insert{name = "nullius-rocket-stage", count = 1} == 1, "rocket stage")
end)

script.on_nth_tick(60, function()
  if game.tick == 0 then return end
  if hub_plates() >= REQUEST then
    check(hub_plates() == REQUEST, "hub received " .. hub_plates() .. " plates, chest kept "
      .. storage.chest.get_item_count("iron-plate"))
    check(storage.silo.products_finished == 1, "one rocket built")
    check(storage.chest.get_item_count("iron-plate") == STOCK - REQUEST, "plates came from the network")
    helpers.write_file("factorio-tests/" .. CASE .. ".json", helpers.table_to_json{
      schema = 1, case = CASE, status = "pass", assertions = storage.assertions, failure_count = 0,
      tick = game.tick, factorio_version = script.active_mods.base}, false)
    script.on_nth_tick(60, nil)
  elseif game.tick >= DEADLINE then
    local rocket = storage.silo.get_inventory(defines.inventory.rocket_silo_rocket)
    local target = storage.silo.transitional_request_target
    error(helpers.table_to_json{
      silo_status = storage.silo.rocket_silo_status, rockets = storage.silo.products_finished,
      rocket_cargo = rocket and rocket.get_contents() or "no rocket inventory",
      request_target = target and target.name or "none",
      chest_plates = storage.chest.get_item_count("iron-plate"), hub_plates = hub_plates(),
      platform_state = storage.hub.surface.platform.state})
  end
end)

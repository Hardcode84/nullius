-- given: one rocket stage, ten clockwork bots, 100 plates and finite volcanic gas.
-- place/connect: pneumatic silo, tank, clockwork roboport and storage on Vulcanus.
-- act/run: an orbital platform requests ten plates; robots load and launch them.
-- expect: the requested cargo reaches orbit without an electric grid.
local CASE = "vulcanus-silo-request"
local REQUEST = 10
local STOCK = 100
local DEADLINE = 6600

local function check(ok, message)
  storage.assertions = storage.assertions + 1
  assert(ok, message)
end

local function hub_plates()
  return storage.hub.get_inventory(defines.inventory.hub_main).get_item_count("iron-plate")
end

script.on_nth_tick(1,function()
  script.on_nth_tick(1,nil)
  storage.assertions = 0
  local planet = game.planets["nullius-vulcanus"]
  local surface = planet.surface or planet.create_surface()
  surface.request_to_generate_chunks({0, 0}, 2)
  surface.force_generate_chunk_requests()
  for _, entity in pairs(surface.find_entities_filtered{area = {{-20, -20}, {20, 20}}}) do
    entity.destroy()
  end
  local tiles = {}
  for x = -20, 20 do for y = -20, 20 do
    tiles[#tiles + 1] = {name = "volcanic-soil-dark", position = {x, y}}
  end end
  surface.set_tiles(tiles)
  local force = game.forces.player
  force.technologies["nullius-rocket-science-2"].researched = true

  local platform = assert(force.create_space_platform{
    name = CASE, planet = "nullius-vulcanus", starter_pack = "space-platform-starter-pack"})
  storage.hub = assert(platform.apply_starter_pack(true))
  local section = storage.hub.get_logistic_sections().add_section()
  section.set_slot(1, {value = {type = "item", name = "iron-plate", quality = "normal"},
    min = REQUEST, max = REQUEST, minimum_delivery_count = REQUEST, import_from = "nullius-vulcanus"})

  force.technologies["nullius-pneumatic-technology"].researched = true
  local tank = assert(surface.create_entity{
    name = "nullius-medium-tank-2", position = {-6, -1}, force = force})
  tank.set_fluid(1, {name="nullius-compressed-volcanic-gas", amount=30000, temperature=200})
  storage.silo = assert(surface.create_entity{name = "nullius-silo", position = {0, 0}, force = force})
  check(remote.call("nullius-test-transitions", "execute", storage.silo), "pneumatic switch")
  storage.silo = assert(surface.find_entity("nullius-silo-pneumatic", {0,0}))
  storage.hangar = assert(surface.create_entity{name = "nullius-clockwork-roboport", position = {8, 0}, force = force})
  storage.chest = assert(surface.create_entity{
    name = "nullius-primitive-storage-chest", position = {11, 0}, force = force})
  check(storage.hangar.insert{name = "nullius-clockwork-logistic-robot", count = 10} == 10, "bots in hangar")
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
    check(storage.silo.electric_network_id == nil, "no electric grid")
    check(storage.silo.get_fluid_segment_fluid(1).amount > 0, "finite gas supplied launch")
    local heat = assert(storage.silo.surface.find_entity("nullius-pneumatic-heat-large", {0,0}))
    check(heat.temperature > 200, "silo emits process heat")
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

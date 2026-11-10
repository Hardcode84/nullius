-- given: one real client in god mode on Nauvis; a chest of the client's force holding a stack of
--   filled antimatter traps one spoil margin from their spoil time.
-- act: let the stack spoil.
-- expect: one detonation that destroys the chest, and one "Antimatter containment failed" alert
--   for the client, anchored on the indestructible annihilation site.
local CASE = "antimatter-annihilation"
local SITE = "nullius-annihilation-site"
local MESSAGE = {"nullius-antiproton.containment-failed"}
local CHEST = {120, 0}
local SPOIL_MARGIN = 120

local function check(ok, message)
  storage.assertions = storage.assertions + 1
  assert(ok, message)
end

local function alerts(player)
  local result = {}
  for _, surface in pairs(player.get_alerts{type = defines.alert_type.custom, message = MESSAGE}) do
    for _, list in pairs(surface) do for _, alert in pairs(list) do result[#result + 1] = alert end end
  end
  return result
end

script.on_init(function() storage.assertions = 0 end)

script.on_nth_tick(30, function(event)
  if event.tick == 0 then return end
  local player = game.get_player("nullius-test-a")
  if not player or not player.connected then return end
  if not storage.chest then
    player.set_controller{type = defines.controllers.god}
    local surface = game.surfaces.nauvis
    surface.request_to_generate_chunks(CHEST, 2)
    surface.force_generate_chunk_requests()
    local chest = assert(surface.create_entity{name = "wooden-chest", position = CHEST, force = player.force})
    local stack = chest.get_inventory(defines.inventory.chest)[1]
    stack.set_stack{name = "nullius-antimatter", count = 3}
    stack.spoil_percent = 1 - SPOIL_MARGIN / prototypes.item["nullius-antimatter"].get_spoil_ticks()
    check(#alerts(player) == 0, "no alert before the spoil time")
    storage.chest = chest
    storage.spoil_tick = game.tick + SPOIL_MARGIN
    return
  end
  if game.tick < storage.spoil_tick + 60 then return end
  check(not storage.chest.valid, "the annihilation destroyed its chest")
  local sites = game.surfaces.nauvis.find_entities_filtered{name = SITE}
  check(#sites == 1, "one detonation for a spoiled stack: " .. #sites)
  local list = alerts(player)
  check(#list == 1, "one containment alert, got " .. #list)
  local alert = list[1]
  check(alert.target and alert.target.valid and alert.target == sites[1], "alert anchored on the site")
  check(alert.icon.name == "nullius-antimatter", "alert icon")
  helpers.write_file("factorio-tests/" .. CASE .. ".json", helpers.table_to_json{
    schema = 1, case = CASE, status = "pass", failure_count = 0, assertions = storage.assertions,
    tick = game.tick, factorio_version = script.active_mods.base}, false)
  script.on_nth_tick(30, nil)
end)

-- given: default Alignment mode and one real multiplayer client.
-- place: the production Alignment landing and probe activation create entities.
-- connect: the runner joins the first client.
-- act: request quick-start before and after the faction landing.
-- run: wait for the production landing queue; do not inject force state.
-- expect: no probe before landing; one shared body in the final faction.
local CASE = "vulcanus-probe-alignment"
local function check(condition, message)
  storage.assertions = storage.assertions + 1
  if not condition then error(CASE .. ": " .. message) end
end
script.on_init(function()
  storage.assertions = 0
  storage.stage = "join"
end)
script.on_event(defines.events.on_player_joined_game, function(event)
  storage.player_index = event.player_index
end)
script.on_nth_tick(30, function()
  if not storage.player_index then return end
  local player = game.get_player(storage.player_index)
  if storage.stage == "join" then
    check(settings.startup["nullius-alignment"].value, "fixture requires default Alignment mode")
    local completed, message = remote.call("nullius-test-bodies", "quick_start", player.index)
    check(completed == nil and message[1] == "nullius-probe.alignment-pending",
      "quick-start must wait for the faction landing")
    check(not player.force.technologies["nullius-probe-vulcanus"].researched,
      "pending quick-start changed research")
    check(game.planets["nullius-vulcanus"].surface == nil, "pending quick-start created Vulcanus")
    storage.stage = "landing"
  elseif storage.stage == "landing" and player.force.name ~= "player" and
      player.surface.name == "nauvis" then
    local force = player.force
    check(remote.call("nullius-test-bodies", "quick_start", player.index) ~= nil,
      "quick-start failed after faction landing")
    local body = remote.call("nullius-test-bodies", "snapshot", player.index).body
    check(body and body.valid and body == player.character, "caller did not receive the probe body")
    check(body.force == force and body.surface.name == "nullius-vulcanus", "probe has wrong faction or surface")
    check(body.surface.count_entities_filtered{name = "nullius-landing-main", force = force} == 1,
      "faction must receive one probe wreck")
    check(body.surface.count_entities_filtered{name = "nullius-landing-main", force = "player"} == 0,
      "lobby force received probe supplies")
    helpers.write_file("factorio-tests/" .. CASE .. ".json", helpers.table_to_json{
      schema = 1, case = CASE, status = "pass", failure_count = 0,
      assertions = storage.assertions, tick = game.tick,
      factorio_version = script.active_mods.base,
    }, false)
    script.on_nth_tick(30, nil)
  end
end)

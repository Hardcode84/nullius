-- given: cooperative mode (nullius-alignment=false), two real clients,
-- Nauvis starting bodies, and probe research.
-- place: the production probe creates its body and wreck.
-- connect: the runner joins, disconnects, and rejoins real clients.
-- act: use production research, quick-start, upload, cycle, and respawn paths.
-- run: bounded multiplayer ticks, followed by a server save and reload.
-- expect: shared idle access, occupied exclusion, stable stock, tags, and queues.
local research = require("__nullius-star__/scripts/research")
local CASE = "vulcanus-shared-body"
local function call(method, ...)
  return remote.call("nullius-test-bodies", method, ...)
end
local function check(condition, message)
  storage.assertions = storage.assertions + 1
  if not condition then error(CASE .. ": " .. message) end
end
local function action(operation, player)
  storage.action_id = storage.action_id + 1
  helpers.write_file("factorio-tests/multiplayer-action.json", helpers.table_to_json{
    id = storage.action_id, action = operation, player = player,
  }, false)
end
local function snapshot(player) return call("snapshot", player.index) end
local function stock()
  local surface = game.planets["nullius-vulcanus"].surface
  check(surface.count_entities_filtered{name = "nullius-landing-main", force = "player"} == 1,
    "player force must have one wreck")
  local wreck = surface.find_entities_filtered{name = "nullius-landing-main", force = "player"}[1]
  check(wreck.get_item_count("nullius-seawater-intake-1") == 2, "wreck supplies changed")
end
local function queue(player)
  local nodes = snapshot(player).nodes
  local count = 0
  for unit, node in pairs(nodes) do
    count = count + 1
    check(node.valid, "invalid body in queue: " .. unit)
    check(node.linked, "broken queue links: " .. unit)
    check(nodes[node.next] ~= nil and nodes[node.prev] ~= nil, "link outside queue")
  end
  check(count > 0, "empty queue")
end
local function tags(body)
  local count = 0
  for _, tag in pairs(body.force.find_chart_tags(body.surface)) do
    if tag.position.x == body.position.x and tag.position.y == body.position.y then
      count = count + 1
    end
  end
  return count
end
script.on_init(function()
  storage.assertions = 0
  storage.action_id = 0
  storage.stage = "first-join"
  storage.joins = {}
end)
script.on_event(defines.events.on_player_joined_game, function(event)
  local name = game.get_player(event.player_index).name
  storage.joins[name] = (storage.joins[name] or 0) + 1
end)
script.on_event(defines.events.on_player_respawned, function(event)
  storage.respawned = event.player_index
end)
script.on_nth_tick(30, function()
  check(game.tick < 30000, "multiplayer tick deadline")
  local a = game.get_player("nullius-test-a")
  local b = game.get_player("nullius-test-b")
  local stage = storage.stage
  if stage == "first-join" and a and a.connected and storage.joins[a.name] then
    check(game.is_multiplayer(), "requires multiplayer simulation")
    storage.a_home = a.character
    check(storage.a_home ~= nil, "first client has no character")
    research.complete_with_prerequisites(a.force.technologies["nullius-pneumatic-technology"])
    storage.stage = "activation"
  elseif stage == "activation" then
    local body = snapshot(a).body
    check(body and body.valid and not body.player, "research must create an idle body")
    check(a.character == storage.a_home, "research transferred the player")
    check(tags(body) == 1, "idle probe needs one map tag")
    storage.probe = body
    check(call("quick_start", a.index) ~= nil, "first quick-start failed")
    check(a.character == body, "first caller did not receive probe body")
    check(tags(body) == 0, "occupied probe retains a tag")
    storage.stage = "late-join"
    action("join", "nullius-test-b")
  elseif stage == "late-join" and b and b.connected and storage.joins[b.name] then
    storage.b_home = b.character
    check(snapshot(b).nodes[storage.probe.unit_number] ~= nil, "late join missed shared probe " .. helpers.table_to_json(snapshot(b).nodes) .. " unit=" .. storage.probe.unit_number .. " force=" .. b.force.name .. " bodyforce=" .. storage.probe.force.name)
    local completed, message = call("quick_start", b.index)
    check(completed == nil and message[1] == "nullius-probe.body-occupied", "busy command must report occupied")
    call("upload", b.index, storage.probe)
    call("cycle", b.index, false)
    check(b.character == storage.b_home and a.character == storage.probe, "occupied body was stolen")
    call("upload", a.index, storage.a_home)
    call("cycle", b.index, false)
    check(b.character == storage.probe, "late join cannot cycle into vacated probe")
    call("cycle", a.index, false)
    check(a.character == storage.a_home, "cycling stole occupied probe")
    call("upload", b.index, storage.b_home)
    call("quick_start", a.index)
    call("upload", b.index, storage.a_home)
    check(b.character == storage.a_home, "previous body is not shared")
    call("upload", a.index, storage.b_home)
    call("upload", b.index, storage.probe)
    check(b.character == storage.probe, "manual shared transfer failed")
    call("upload", b.index, storage.a_home)
    call("activate", a.force)
    call("activate", a.force)
    check(tags(storage.probe) == 1, "repeated activation duplicated tags")
    stock()
    local other = game.create_force("probe-other-force")
    call("activate", other)
    check(snapshot(a).body == storage.probe, "second force overwrote first probe")
    local other_body = storage.probe.surface.find_entities_filtered{type = "character", force = other}[1]
    check(other_body and other_body ~= storage.probe, "second force has no independent probe")
    call("upload", a.index, other_body)
    check(a.character == storage.b_home, "cross-force body transfer succeeded")
    storage.other_body = other_body
    b.force = other
    storage.stage = "force-change"
  elseif stage == "force-change" then
    check(snapshot(b).body == storage.other_body, "force change selected the wrong probe")
    check(call("quick_start", b.index) ~= nil and b.character == storage.other_body,
      "second force quick-start failed")
    check(snapshot(a).body == storage.probe, "second force quick-start changed first lookup")
    call("upload", b.index, storage.a_home)
    check(tags(storage.other_body) == 1, "second force has duplicate or missing idle tag")
    b.force = game.forces.player
    storage.stage = "force-return"
  elseif stage == "force-return" then
    check(snapshot(b).body == storage.probe, "return to force lost shared probe")
    queue(a)
    queue(b)
    storage.a_home_unit = storage.a_home.unit_number
    storage.stage = "disconnect"
    action("leave", "nullius-test-b")
  elseif stage == "disconnect" and not b.connected then
    check(storage.probe.valid and storage.probe.associated_player == nil,
      "idle shared probe belongs to a disconnected player")
    check(storage.probe.surface.count_entities_filtered{
      type = "character", force = "player", position = storage.probe.position,
    } == 1, "disconnect removed idle probe from the surface")
    storage.stage = "reconnect"
    action("join", "nullius-test-b")
  elseif stage == "reconnect" and b.connected and storage.joins[b.name] == 2 then
    check(b.character and b.character.unit_number == storage.a_home_unit,
      "reconnect changed the controlled body identity")
    storage.a_home = b.character
    check(snapshot(b).body == storage.probe, "reconnect replaced probe")
    check(tags(storage.probe) == 1, "reconnect duplicated idle tags")
    stock()
    call("quick_start", b.index)
    check(b.character == storage.probe, "reconnected player cannot transfer")
    -- Replace a body through the public character-swap integration path.
    call("upload", b.index, storage.a_home)
    local old = storage.probe
    local replacement = old.surface.create_entity{
      name = "character", position = {10, 10}, force = b.force,
    }
    check(replacement ~= nil, "replacement fixture failed")
    remote.call("nullius", "on_character_swapped", {
      old_unit_number = old.unit_number, new_character = replacement,
    })
    check(tags(replacement) == 1, "replacement did not move the idle tag")
    old.destroy()
    call("quick_start", b.index)
    check(b.character == replacement, "replacement body cannot be used")
    storage.probe = replacement
    check(snapshot(a).body == replacement and snapshot(b).body == replacement,
      "character replacement left stale probe lookup")
    -- An unrelated dead queued body must not receive the respawn mapping.
    storage.a_home.destroy()
    storage.dead_unit = replacement.unit_number
    replacement.die()
    b.ticks_to_respawn = 1
    storage.stage = "respawn"
  elseif stage == "respawn" and storage.respawned == b.index then
    check(b.character and b.character.valid, "respawn failed")
    check(snapshot(b).body == b.character, "respawn did not replace exact probe body")
    check(snapshot(a).nodes[storage.dead_unit] == nil, "old probe unit remains in peer queue")
    -- Visit both directions so invalid historical nodes are pruned.
    call("cycle", a.index, false)
    call("cycle", a.index, true)
    call("cycle", b.index, false)
    call("cycle", b.index, true)
    queue(a)
    queue(b)
    stock()
    storage.probe = snapshot(b).body
    storage.probe_unit = storage.probe.unit_number
    storage.stage = "reload"
    action("reload")
  elseif stage == "reload" and a.connected and b.connected and
      storage.joins[a.name] >= 2 and storage.joins[b.name] >= 3 then
    storage.probe = snapshot(a).body
    check(storage.probe and storage.probe.valid and
      storage.probe.unit_number == storage.probe_unit, "reload lost probe lookup")
    queue(a)
    queue(b)
    stock()
    -- Destroy the idle probe. Quick-start must not mint another landing.
    if storage.probe.player then
      local player = storage.probe.player
      local spare = storage.probe.surface.create_entity{
        name = "character", position = {15, 15}, force = player.force,
      }
      check(spare ~= nil, "spare fixture failed")
      call("upload", player.index, spare)
    end
    storage.probe.destroy()
    storage.stage = "destroyed"
  elseif stage == "destroyed" then
    local completed, message = call("quick_start", a.index)
    check(completed == nil and message[1] == "nullius-probe.body-unavailable", "destroyed body was recreated")
    call("activate", a.force)
    stock()
    helpers.write_file("factorio-tests/" .. CASE .. ".json", helpers.table_to_json{
      schema = 1, case = CASE, status = "pass", failure_count = 0,
      assertions = storage.assertions, tick = game.tick,
      factorio_version = script.active_mods.base,
    }, false)
    script.on_nth_tick(30, nil)
  end
end)

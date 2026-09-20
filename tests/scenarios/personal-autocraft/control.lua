-- given: one real player, primitive robotics, declared finite crafting inputs.
-- place: personal logistics requests for production gears and belts.
-- connect: the runner joins a real client without a desktop session.
-- act: toggle the production shortcut and checkbox, research, and request switch.
-- run: production polling and native crafting events.
-- expect: native recursive crafting, idle-only scheduling, and synchronized UI.
local NAME = "nullius-autocraft"
local GEAR = "nullius-iron-gear"
local function check(value, message)
  storage.assertions = storage.assertions + 1
  if not value then error("personal-autocraft: " .. message) end
end
local function shortcut(player)
  remote.call("nullius-test-autocraft", "shortcut", {
    player_index = player.index, prototype_name = NAME,
  })
end
local function request(player, name, count, quality)
  local section = player.character.get_requester_point().get_section(1)
  section.set_slot(1, {value = {type = "item", name = name, quality = quality or "normal"},
    min = count, max = count})
end
local function inputs(player, items)
  player.character.get_main_inventory().clear()
  for name, count in pairs(items) do
    check(player.character.insert{name = name, count = count} == count, "fixture inventory insertion failed")
  end
end
local function phase(name)
  storage.phase = name
  storage.since = game.tick
  log("personal-autocraft phase: " .. name)
end
script.on_init(function() storage.assertions = 0 end)
script.on_event(defines.events.on_player_joined_game, function(event)
  storage.player = event.player_index
  phase("locked")
end)
script.on_event(defines.events.on_player_crafted_item, function(event)
  if storage.phase == "remote" and not storage.first_completion then
    storage.first_completion = game.tick
  end
end)
script.on_nth_tick(1, function()
  if not storage.player or storage.finished then return end
  local player = game.get_player(storage.player)
  local elapsed = game.tick - storage.since
  if elapsed >= 1200 then
    error("phase timed out: " .. storage.phase .. "; queue=" ..
      player.crafting_queue_size .. "; requests=" ..
      helpers.table_to_json(player.character.get_requester_point().filters))
  end
  local frame = player.gui.top[NAME]
  if storage.phase == "locked" and elapsed >= 35 then
    check(not player.force.character_logistic_requests, "fixture already unlocked personal requests")
    check(not frame or not frame.visible, "GUI visible before logistics research")
    shortcut(player)
    check(not player.is_shortcut_toggled(NAME), "locked shortcut enabled crafting")
    player.force.technologies["nullius-primitive-robotics"].researched = true
    player.force.recipes[GEAR].enabled = true
    player.force.recipes["transport-belt"].enabled = true
    local point = player.character.get_requester_point()
    point.enabled = true
    if not point.get_section(1) then point.add_section() end
    request(player, GEAR, 4)
    inputs(player, {["nullius-iron-plate"] = 4, ["nullius-iron-rod"] = 2})
    phase("show")
  elseif storage.phase == "show" and elapsed >= 35 then
    check(frame and frame.visible, "GUI did not appear after research")
    check(not frame[NAME].state, "auto-crafting enabled without player action")
    frame[NAME].state = true
    remote.call("nullius-test-autocraft", "checkbox", {player_index = player.index, element = frame[NAME]})
    check(player.is_shortcut_toggled(NAME), "checkbox did not update shortcut")
    storage.body = player.character
    player.set_controller{type = defines.controllers.remote}
    check(player.character == storage.body, "remote view lost the physical character")
    check(player.get_main_inventory() == nil, "remote view did not reproduce the missing inventory")
    phase("remote")
  elseif storage.phase == "remote" then
    if storage.first_completion and game.tick == storage.first_completion + 2 then
      check(storage.body.crafting_queue_size == 1,
        "remote completion did not enqueue the next craft on the next tick")
    end
    if storage.body.get_item_count(GEAR) == 4 and storage.body.crafting_queue_size == 0 then
      check(storage.first_completion ~= nil, "remote crafting did not raise the player completion event")
      check(player.controller_type == defines.controllers.remote, "crafting exited remote view")
      check(frame.visible and frame[NAME].state and player.is_shortcut_toggled(NAME),
        "remote crafting lost the auto-crafting preference")
      check(storage.body.get_item_count("nullius-iron-plate") == 0,
        "remote crafting did not consume the physical inventory")
      phase("satisfied")
    end
  elseif storage.phase == "satisfied" and elapsed >= 35 then
    check(storage.body.crafting_queue_size == 0, "satisfied request kept crafting")
    request(player, "transport-belt", 1)
    inputs(player, {["nullius-motor-1"] = 1, ["nullius-iron-plate"] = 2,
      ["nullius-iron-rod"] = 3, ["nullius-iron-sheet"] = 2})
    check(storage.body.get_craftable_count("transport-belt") == 1,
      "native craftability did not include recursive gears")
    phase("recursive")
  elseif storage.phase == "recursive" then
    if storage.body.crafting_queue_size > 1 then storage.recursive_queue = true end
    if storage.body.get_item_count("transport-belt") >= 15 then
      check(storage.recursive_queue, "native intermediate crafts were not queued")
      check(storage.body.get_item_count("transport-belt") == 15, "one recipe execution did not produce one batch")
      check(player.controller_type == defines.controllers.remote, "recursive crafting exited remote view")
      player.exit_remote_view()
      request(player, GEAR, 2)
      inputs(player, {["nullius-iron-plate"] = 4, ["nullius-iron-rod"] = 2})
      check(player.begin_crafting{recipe = GEAR, count = 1} == 1, "manual craft could not start")
      phase("manual")
    end
  elseif storage.phase == "manual" and elapsed >= 35 then
    check(player.crafting_queue_size == 1 and player.crafting_queue[1].count == 1,
      "auto-crafting appended work to a manual queue")
    player.cancel_crafting{index = 1, count = 1}
    check(not player.is_shortcut_toggled(NAME) and not frame[NAME].state,
      "cancellation did not pause both controls")
    phase("cancelled")
  elseif storage.phase == "cancelled" and elapsed >= 35 then
    check(player.crafting_queue_size == 0, "cancelled craft was requeued")
    inputs(player, {})
    shortcut(player)
    phase("missing")
  elseif storage.phase == "missing" and elapsed >= 35 then
    check(player.crafting_queue_size == 0, "craft queued without ingredients")
    inputs(player, {["nullius-iron-plate"] = 2, ["nullius-iron-rod"] = 1})
    request(player, GEAR, 2, "uncommon")
    phase("quality")
  elseif storage.phase == "quality" and elapsed >= 35 then
    check(player.crafting_queue_size == 0, "normal handcraft queued for uncommon request")
    request(player, GEAR, 2)
    player.character.get_requester_point().get_section(1).active = false
    phase("section-off")
  elseif storage.phase == "section-off" and elapsed >= 35 then
    check(player.crafting_queue_size == 0, "disabled section caused crafting")
    player.character.get_requester_point().enabled = false
    phase("requests-off")
  elseif storage.phase == "requests-off" and elapsed >= 35 then
    check(not frame.visible, "GUI visible with requests disabled")
    shortcut(player)
    check(not player.is_shortcut_toggled(NAME), "disabled request shortcut was handled")
    check(player.crafting_queue_size == 0, "disabled requests caused crafting")
    storage.finished = true
    helpers.write_file("factorio-tests/personal-autocraft.json", helpers.table_to_json{
      schema = 1, case = "personal-autocraft", status = "pass", failure_count = 0,
      assertions = storage.assertions, tick = game.tick, factorio_version = script.active_mods.base,
    }, false)
  end
end)

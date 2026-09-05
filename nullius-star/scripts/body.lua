local function tag_key(tag)
  return tag.force.index .. ":" .. tag.tag_number
end

function add_chart_tag(player, character)
  if ((player == nil) or (character == nil)) then
    return
  end
  if not character.valid or character.player then return end
  local existing = storage.nullius_android_tag and
      storage.nullius_android_tag[character.unit_number]
  if existing and existing.valid then return end
  script.register_on_object_destroyed(character)
  --local icon = "nullius-android-1"
  local icon = "character"
  if (character.name == "nullius-android-2") then
    icon = "nullius-android-2"
  end

  local name = nil
  if (storage.nullius_android_name ~= nil) then
    name = storage.nullius_android_name[character.unit_number]
  end
  if (name == nil) then
    name = player.name
  end

  local ctag = player.force.add_chart_tag(character.surface,
      {position=character.position, icon={type="item", name=icon},
      text=name, last_user=player})
  if (ctag ~= nil) then
    if (storage.nullius_tag_android == nil) then
      storage.nullius_tag_android = {}
      storage.nullius_android_tag = {}
    end
    storage.nullius_tag_android[tag_key(ctag)] = character
    storage.nullius_android_tag[character.unit_number] = ctag
  end
end

local function is_rolling_stock(vehicle)
  if ((vehicle.type == "locomotive") or
      (vehicle.type == "cargo-wagon") or
	  (vehicle.type == "fluid-wagon") or
	  (vehicle.type == "artillery-wagon")) then
	return true
  end
  return false
end

function switch_body(player, target)
  if not target.valid or target.type ~= "character" or target.player or
      target.force ~= player.force then return end
  local target_vehicle = nil
  if ((target.vehicle ~= nil) and ((target.vehicle.type == "car") or
      (target.vehicle.type == "spider-vehicle"))) then
    target_vehicle = target.vehicle
  end

  if (storage.nullius_android_tag ~= nil) then
    local tag = storage.nullius_android_tag[target.unit_number]
    if (tag ~= nil) then
      storage.nullius_android_tag[target.unit_number] = nil
      if (tag.valid) then
        if (storage.nullius_android_name == nil) then
          storage.nullius_android_name = {}
        end
        storage.nullius_android_name[target.unit_number] = tag.text
        storage.nullius_tag_android[tag_key(tag)] = nil
        tag.destroy()
      end
    end
  end

  local oldchar = player.character
  local vehicle = player.vehicle  
  if (target.surface ~= player.surface) then
    player.set_controller{type=defines.controllers.ghost}
    if (not player.teleport(target.position, target.surface)) then
	  player.set_controller{type=defines.controllers.character, character=oldchar}
	  return
	end
  end

  if ((player.force ~= nil) and player.force.valid) then
    if (storage.nullius_switch_body_count == nil) then
	  storage.nullius_switch_body_count = { }
	end
    local count = storage.nullius_switch_body_count[player.force.name]
	if (count == nil) then count = 0 end
	count = count + 1
	storage.nullius_switch_body_count[player.force.name] = count
  end

  player.set_controller{type=defines.controllers.character, character=target}
  update_player_upgrades(player)
  update_queue(player, oldchar)
  if ((oldchar ~= nil) and oldchar.valid and (oldchar.player == nil)) then
    if probe.is_body(oldchar.unit_number) then
      oldchar.associated_player = nil
    else
      player.associate_character(oldchar)
    end
  end

  local do_set_tag = true
  local old_passenger = nil
  if ((vehicle ~= nil) and (oldchar ~= nil)) then
    if ((vehicle.type == "car") or (vehicle.type == "spider-vehicle")) then
	  old_passenger = vehicle.get_passenger()
	  if ((old_passenger == nil) or (old_passenger == target)) then
        vehicle.set_passenger(oldchar)
	    do_set_tag = false
	  end
    elseif (is_rolling_stock(vehicle)) then
	  if (vehicle.get_driver() == nil) then
        vehicle.set_driver(oldchar)
	    do_set_tag = false
	  end
    end
  end
  if (do_set_tag) then
    add_chart_tag(player, oldchar)
  end

  if (storage.nullius_body_queue ~= nil) then
    local queue = storage.nullius_body_queue[player.index]
    if (queue ~= nil) then
      queue.last_index = target.unit_number
    end
  end

  if ((target_vehicle ~= nil) and (target_vehicle.get_driver() == nil)) then
    if ((target_vehicle == vehicle) and (old_passenger == target) and
	    (oldchar == target_vehicle.get_passenger())) then
	  target_vehicle.set_driver(target)
    elseif (target == target_vehicle.get_passenger()) then
      target_vehicle.set_passenger(nil)
      target_vehicle.set_driver(target)
	end
  end
end

-- Each queue records access history. It does not grant exclusive ownership.
function add_body_to_queue(player, body)
  if not body.valid or body.force ~= player.force then return end
  storage.nullius_body_queue = storage.nullius_body_queue or {}
  local queue = storage.nullius_body_queue[player.index]
  if not queue then
    queue = {nodes = {}}
    storage.nullius_body_queue[player.index] = queue
  end
  local function insert(character, anchor)
    local unit = character.unit_number
    local node = queue.nodes[unit]
    if node then return node end
    node = {body = character, unit = unit}
    queue.nodes[unit] = node
    if anchor then
      node.next = anchor.next
      node.prev = anchor
      anchor.next.prev = node
      anchor.next = node
    else
      node.next = node
      node.prev = node
    end
    return node
  end
  local anchor = queue.last_index and queue.nodes[queue.last_index]
  local current = player.character
  if current and current.valid then
    anchor = insert(current, anchor)
    queue.last_index = current.unit_number
  end
  local node = insert(body, anchor)
  if not queue.last_index then queue.last_index = node.unit end
end

function update_queue(player, oldchar)
  if oldchar and oldchar.valid then add_body_to_queue(player, oldchar) end
end

function upload_mind(player, target)
  if ((target.type == "car") or (target.type == "spider-vehicle")) then
    target = target.get_passenger()
    if ((target == nil) or (not target.valid)) then return end
  elseif (is_rolling_stock(target)) then
    target = target.get_driver()
    if ((target == nil) or (not target.valid)) then return end
  end
  if ((target.type ~= "character") or (target.player ~= nil) or
      (target.force ~= player.force)) then
    return
  end
  local oldchar = player.character
  if ((target == oldchar) or (oldchar == nil)) then return end

  switch_body(player, target)
end

function cycle_body(player, rev)
  if (storage.nullius_body_queue == nil) then return end
  local queue = storage.nullius_body_queue[player.index]
  if (queue == nil) then return end

  if (player.character == nil) then return end
  local node = queue.nodes[player.character.unit_number]
  if ((node == nil) and (queue.last_index ~= nil)) then
    node = queue.nodes[queue.last_index]
  end
  if (node == nil) then return end
  local orgnode = node

  if (rev) then
    node = node.prev
  else
    node = node.next
  end
  if (node == nil) then
    storage.nullius_body_queue[player.index] = nil
    return
  end

  local body = node.body
  while ((body == nil) or (not body.valid) or (body.type ~= "character") or
      (body.player ~= nil) or (body.force ~= player.force)) do
    local np = node.prev
    local nn = node.next
    if ((nn == nil) or (np == nil) or (nn.prev == nil) or
        (np.next == nil) or (nn == node) or (np == node)) then
      storage.nullius_body_queue[player.index] = nil
      return
    end
    if ((body == nil) or (not body.valid) or (body.type ~= "character")) then
      queue.nodes[node.unit] = nil
      np.next = nn
      nn.prev = np
      node.next = node
      node.prev = node
    end
    if (node == orgnode) then return end
    if (rev) then node = np else node = nn end
    body = node.body
  end

  switch_body(player, body)
end


script.on_event("nullius-upload-mind", function(event)
  local player = game.players[event.player_index]
  local target = player.selected
  if ((target ~= nil) and target.valid) then
    upload_mind(player, target)
  end
end)

script.on_event("nullius-previous-body", function(event)
  local player = game.players[event.player_index]
  cycle_body(player, true)
end)

script.on_event("nullius-next-body", function(event)
  local player = game.players[event.player_index]
  cycle_body(player, false)
end)

script.on_event(defines.events.on_chart_tag_removed, function(event)
  if ((storage.nullius_tag_android ~= nil) and
      (event.tag ~= nil) and event.tag.valid) then
    local android = storage.nullius_tag_android[tag_key(event.tag)]
  if (android ~= nil) then
    storage.nullius_tag_android[tag_key(event.tag)] = nil
    if (android.valid) then
    storage.nullius_android_tag[android.unit_number] = nil
    if (event.player_index ~= nil) then
      local player = game.players[event.player_index]
      if (player ~= nil) then
        upload_mind(player, android)
      end
    end
    end
  end
  end
end)

function change_character_entity(oldunit, newchar)
  local newunit = newchar.unit_number
  if (oldunit == nil) then return end
  probe.replace_body(oldunit, newchar)

  if ((storage.nullius_android_tag ~= nil) and
      (storage.nullius_tag_android ~= nil)) then
    local tag = storage.nullius_android_tag[oldunit]
    if ((tag ~= nil) and tag.valid and (tag.tag_number ~= nil)) then
      storage.nullius_android_tag[oldunit] = nil
      storage.nullius_android_tag[newunit] = tag
      storage.nullius_tag_android[tag_key(tag)] = newchar
      tag.position = newchar.position
      tag.surface = newchar.surface
      script.register_on_object_destroyed(newchar)
    end

    if (storage.nullius_android_name ~= nil) then
	  local name = storage.nullius_android_name[oldunit]
      if (name ~= nil) then
        storage.nullius_android_name[oldunit] = nil
        storage.nullius_android_name[newunit] = name
      end
	end
  end

  if (storage.nullius_body_queue ~= nil) then
    for _,queue in pairs(storage.nullius_body_queue) do
      local node = queue.nodes[oldunit]
      if (node ~= nil) then
        node.body = newchar
        node.unit = newunit
        queue.nodes[oldunit] = nil
        queue.nodes[newunit] = node
      end
      if (queue.last_index == oldunit) then
        queue.last_index = newunit
      end
    end
  end
end

script.on_event(defines.events.on_pre_player_died, function(event)
  local character = game.get_player(event.player_index).character
  storage.nullius_dead_body = storage.nullius_dead_body or {}
  storage.nullius_dead_body[event.player_index] = character.unit_number
end)

script.on_event(defines.events.on_player_respawned, function(event)
  local player = game.get_player(event.player_index)
  update_player_upgrades(player)
  local oldunit = storage.nullius_dead_body and
      storage.nullius_dead_body[player.index]
  if oldunit then
    storage.nullius_dead_body[player.index] = nil
    change_character_entity(oldunit, player.character)
    add_body_to_queue(player, player.character)
  end
  probe.attach_player(player)
end)

script.on_event(defines.events.on_player_removed, function(event)
  if storage.nullius_body_queue then
    storage.nullius_body_queue[event.player_index] = nil
  end
  if storage.nullius_dead_body then
    storage.nullius_dead_body[event.player_index] = nil
  end
end)

-- The build event dispatcher also receives registered character destruction.
function remove_body_tag(unit)
  local tags = storage.nullius_android_tag
  local tag = tags and tags[unit]
  if not tag then return end
  tags[unit] = nil
  if tag.valid then
    storage.nullius_tag_android[tag_key(tag)] = nil
    tag.destroy()
  end
  if storage.nullius_android_name then storage.nullius_android_name[unit] = nil end
end

function rematerialize_body(event)
  local player = game.get_player(event.player_index)
  update_player_upgrades(player)
  -- Reconnect can replace a LuaEntity reference without changing its unit ID.
  -- Refresh every queue that records the body, including other players' queues.
  if player.character and player.character.valid then
    change_character_entity(player.character.unit_number, player.character)
  end
  for _, body in pairs(player.surface.find_entities_filtered{
      type = "character", force = player.force}) do
    change_character_entity(body.unit_number, body)
  end
  for _, body in pairs(player.get_associated_characters()) do
    change_character_entity(body.unit_number, body)
  end
end

script.on_event(defines.events.on_player_toggled_map_editor,
    rematerialize_body)

if script.active_mods["factorio-test-support"] then
  local quick_start = require("scripts.debug").quick_start_vulcanus
  remote.add_interface("nullius-test-bodies", {
    quick_start = function(player_index)
      return quick_start(game.get_player(player_index))
    end,
    upload = function(player_index, body)
      upload_mind(game.get_player(player_index), body)
    end,
    cycle = function(player_index, reverse)
      cycle_body(game.get_player(player_index), reverse)
    end,
    activate = function(force)
      probe.on_probe_researched("nullius-probe-vulcanus", force)
    end,
    snapshot = function(player_index)
      local player = game.get_player(player_index)
      local landing = probe.get_landing(player.force)
      local queue = storage.nullius_body_queue and storage.nullius_body_queue[player.index]
      local nodes = {}
      for unit, node in pairs(queue and queue.nodes or {}) do
        nodes[unit] = {
          valid = node.body.valid, next = node.next.unit, prev = node.prev.unit,
          linked = node.next.prev == node and node.prev.next == node,
        }
      end
      return {body = landing and landing.android, nodes = nodes}
    end,
  })
end

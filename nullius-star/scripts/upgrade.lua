local upgrade = {}

-- Cold path: convert the first release's body records on configuration change.
function upgrade.from_0_0_1(event)
  local change = event.mod_changes and event.mod_changes["nullius-star"]
  if not change or change.old_version ~= "0.0.1" then return end

  storage.nullius_probe_landings = {}
  for _, force in pairs(game.forces) do
    if force.technologies["nullius-probe-vulcanus"].researched then
      -- Research already supplied a wreck. Never supply a second one on upgrade,
      -- including when the old body was destroyed or its reference was replaced.
      storage.nullius_probe_landings[force.index] = {}
    end
  end
  for _, body in pairs(storage.nullius_probe_androids or {}) do
    if body.valid then
      storage.nullius_probe_landings[body.force.index] = {
        android = body, unit = body.unit_number,
      }
      if not body.player then body.associated_player = nil end
    end
  end
  storage.nullius_probe_androids = nil

  local queues = storage.nullius_body_queue or {}
  storage.nullius_body_queue = {}
  for index, queue in pairs(queues) do
    local player = game.get_player(index)
    if player then
      local units = {}
      for unit in pairs(queue.nodes) do units[#units + 1] = unit end
      table.sort(units)
      for _, unit in ipairs(units) do
        local body = queue.nodes[unit].body
        if body and body.valid then add_body_to_queue(player, body) end
      end
    end
  end

  storage.nullius_tag_android = {}
  for unit, tag in pairs(storage.nullius_android_tag or {}) do
    local body = game.get_entity_by_unit_number(unit)
    if tag.valid and body and body.valid and not body.player then
      storage.nullius_tag_android[tag.force.index .. ":" .. tag.tag_number] = body
      script.register_on_object_destroyed(body)
    else
      storage.nullius_android_tag[unit] = nil
      if tag.valid then tag.destroy() end
    end
  end
  for _, player in pairs(game.players) do probe.attach_player(player) end
end

return upgrade

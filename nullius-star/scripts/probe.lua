-- Probe reactivation system for Nullius*.
-- When a probe tech is researched, create the planet surface,
-- spawn a dormant android and probe wreckage, then offer body switch.

local probe = {}

-- Vulcanus probe landing site: spawn broken equipment.
local function vulcanus_landing_site(surface, pos, force)
  -- Clear area around landing position.
  for _, entity in pairs(surface.find_entities_filtered{
      area = {{pos.x - 16, pos.y - 16}, {pos.x + 16, pos.y + 16}},
      force = "neutral", collision_mask = "player"}) do
    if entity.valid then
      entity.destroy()
    end
  end

  -- Spawn probe wreck (container with starting supplies).
  local wreck_pos = surface.find_non_colliding_position(
      "nullius-landing-main", pos, 32, 2)
  if wreck_pos == nil then wreck_pos = pos end

  local wreck = surface.create_entity{
    name = "nullius-landing-main",
    position = wreck_pos,
    force = force,
  }
  if wreck and wreck.valid then
    -- Vulcanus probe supplies: heat-resistant components survived.
    -- No electronics (melted). Gas-powered bootstrap.
    wreck.insert({name = "nullius-small-furnace-1", count = 3})
    wreck.insert({name = "nullius-heat-pipe-1", count = 6})
    wreck.insert({name = "pipe", count = 12})
    wreck.insert({name = "inserter", count = 4})
    wreck.insert({name = "iron-chest", count = 2})
  end
end

-- Create a dormant android on the target surface.
local function spawn_android(surface, pos, force)
  local spawn_pos = surface.find_non_colliding_position(
      "character", pos, 32, 1)
  if spawn_pos == nil then spawn_pos = pos end

  local android = surface.create_entity{
    name = "character",
    position = spawn_pos,
    force = force,
  }
  return android
end

-- Called when probe reactivation tech is completed.
function probe.on_probe_researched(tech_name, force)
  if tech_name == "nullius-probe-vulcanus" then
    -- Create Vulcanus surface if it doesn't exist.
    local surface = game.surfaces["nullius-vulcanus"]
    if surface == nil then
      surface = game.create_surface("nullius-vulcanus", {})
    end

    -- Find a good landing position.
    local pos = {x = 0, y = 0}

    -- Spawn probe wreckage with supplies.
    vulcanus_landing_site(surface, pos, force)

    -- Spawn a dormant android body.
    local android = spawn_android(surface, pos, force)
    if android and android.valid then
      -- Store reference so players can switch to it.
      if storage.nullius_probe_androids == nil then
        storage.nullius_probe_androids = {}
      end
      storage.nullius_probe_androids["nullius-vulcanus"] = android

      -- Associate android with all players and add to body queue.
      for _, player in pairs(force.players) do
        player.associate_character(android)

        -- Initialize the body cycle queue so Ctrl+U / Shift+U work.
        local current = player.character
        if current and current.valid then
          if storage.nullius_body_queue == nil then
            storage.nullius_body_queue = {}
          end
          local queue = storage.nullius_body_queue[player.index]
          if queue == nil then
            queue = { nodes = {} }
            storage.nullius_body_queue[player.index] = queue
          end

          -- Add current body to queue if not there.
          local node1 = queue.nodes[current.unit_number]
          if node1 == nil then
            node1 = { body = current, unit = current.unit_number }
            node1.next = node1
            node1.prev = node1
            queue.nodes[current.unit_number] = node1
          end

          -- Add android to queue, linked after current body.
          local node2 = { body = android, unit = android.unit_number }
          queue.nodes[android.unit_number] = node2
          local nn = node1.next
          node2.next = nn
          node2.prev = node1
          nn.prev = node2
          node1.next = node2
          queue.last_index = current.unit_number
        end

        -- Tag the android on the map.
        add_chart_tag(player, android)
      end

      -- Notify all players.
      for _, player in pairs(force.players) do
        player.print({"", "[color=yellow]", {"technology-name.nullius-probe-vulcanus"}, ": ",
          "Probe activated. Dormant android located on surface. Consciousness transfer available.",
          "[/color]"})
      end
    end
  end
end

return probe

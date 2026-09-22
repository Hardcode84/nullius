local research = require("scripts.research")

local debug = {}
local destinations = {
  vulcanus = {planet = "nullius-vulcanus", technology = "nullius-pneumatic-technology", label = "Vulcanus"},
  fulgora = {planet = "nullius-fulgora", technology = "nullius-probe-fulgora", label = "Fulgora"},
}

function debug.quick_start(player, destination)
  local target = assert(destinations[destination], "Unknown probe destination")
  if not player or not player.valid then error("Probe quick-start requires a valid player") end
  -- Alignment assigns the final force after its queued landing completes.
  if storage.nullius_alignment and player.surface == storage.nullius_align_lobby then
    return nil, {"nullius-probe.alignment-pending"}
  end

  local force = player.force
  local technology = assert(force.technologies[target.technology], "Missing " .. target.technology)
  local completed = research.complete_with_prerequisites(technology)
  local landing = probe.get_landing(force, target.planet)
  if not landing then
    probe.on_probe_researched("nullius-probe-" .. destination, force)
    landing = probe.get_landing(force, target.planet)
  end
  local android = landing.android
  if not android or not android.valid or android.force ~= force or
      android.surface.name ~= target.planet then
    return nil, {"nullius-probe.body-unavailable"}
  end
  if android.player and android.player ~= player then
    return nil, {"nullius-probe.body-occupied", android.player.name}
  end
  probe.attach_player(player)
  if player.character ~= android then switch_body(player, android) end
  if player.character ~= android or player.surface.name ~= target.planet then
    error("Failed to switch player to the " .. target.label .. " android")
  end
  return completed
end

function debug.quick_start_vulcanus(player)
  return debug.quick_start(player, "vulcanus")
end

for _, name in ipairs({"vulcanus", "fulgora"}) do
  local destination = name
  local label = destinations[destination].label
  commands.add_command("nullius-" .. destination,
    "Complete " .. label .. " access research and switch to its idle probe android.",
    function(command)
      if not command.player_index then error("/nullius-" .. destination .. " must be run by a player") end
      local player = game.get_player(command.player_index)
      local completed, message = debug.quick_start(player, destination)
      if not completed then player.print(message) return end
      player.print(label .. " quick-start complete (" .. completed .. " technologies researched).")
    end)
end

return debug

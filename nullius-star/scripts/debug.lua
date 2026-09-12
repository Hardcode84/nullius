local research = require("scripts.research")

local debug = {}

local PNEUMATIC_TECHNOLOGY = "nullius-pneumatic-technology"
local VULCANUS_PROBE = "nullius-probe-vulcanus"
local VULCANUS = "nullius-vulcanus"

function debug.quick_start_vulcanus(player)
  if not player or not player.valid then
    error("Vulcanus quick-start requires a valid player")
  end

  -- Alignment assigns the final force after its queued landing completes.
  if storage.nullius_alignment and player.surface == storage.nullius_align_lobby then
    return nil, {"nullius-probe.alignment-pending"}
  end

  local force = player.force
  local pneumatic = force.technologies[PNEUMATIC_TECHNOLOGY]
  if not pneumatic then
    error("Missing technology " .. PNEUMATIC_TECHNOLOGY)
  end

  local completed = research.complete_with_prerequisites(pneumatic)
  local landing = probe.get_landing(force)
  if not landing then
    probe.on_probe_researched(VULCANUS_PROBE, force)
    landing = probe.get_landing(force)
  end
  local android = landing.android
  if not android or not android.valid or android.force ~= force or
      android.surface.name ~= VULCANUS then
    return nil, {"nullius-probe.body-unavailable"}
  end
  if android.player and android.player ~= player then
    return nil, {"nullius-probe.body-occupied", android.player.name}
  end
  probe.attach_player(player)

  if player.character ~= android then
    switch_body(player, android)
  end
  if player.character ~= android or player.surface.name ~= VULCANUS then
    error("Failed to switch player to the Vulcanus android")
  end

  return completed
end

commands.add_command(
  "nullius-vulcanus",
  "Research pneumatic technology and its prerequisites, activate the Vulcanus probe, and switch to its android.",
  function(command)
    if not command.player_index then
      error("/nullius-vulcanus must be run by a player")
    end
    local player = game.get_player(command.player_index)
    local completed, message = debug.quick_start_vulcanus(player)
    if not completed then
      player.print(message)
      return
    end
    player.print("Vulcanus quick-start complete (" .. completed ..
      " technologies researched).")
  end)

return debug

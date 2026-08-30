local research = require("scripts.research")

local debug = {}

local PNEUMATIC_TECHNOLOGY = "nullius-pneumatic-technology"
local VULCANUS_PROBE = "nullius-probe-vulcanus"
local VULCANUS = "nullius-vulcanus"

local function vulcanus_android(force)
  local androids = storage.nullius_probe_androids
  local android = androids and androids[VULCANUS]
  if android and android.valid and android.force == force then
    return android
  end
  return nil
end

function debug.quick_start_vulcanus(player)
  if not player or not player.valid then
    error("Vulcanus quick-start requires a valid player")
  end

  local force = player.force
  local pneumatic = force.technologies[PNEUMATIC_TECHNOLOGY]
  if not pneumatic then
    error("Missing technology " .. PNEUMATIC_TECHNOLOGY)
  end

  local completed = research.complete_with_prerequisites(pneumatic)
  local android = vulcanus_android(force)
  if not android then
    probe.on_probe_researched(VULCANUS_PROBE, force)
    android = vulcanus_android(force)
  end
  if not android then
    error("Vulcanus probe activation did not create an android")
  end
  if android.player and android.player ~= player then
    error("Vulcanus android is currently controlled by " .. android.player.name)
  end

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
    local completed = debug.quick_start_vulcanus(player)
    player.print("Vulcanus quick-start complete (" .. completed ..
      " technologies researched).")
  end)

return debug

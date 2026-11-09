-- Client startup takes wall time, not game time. A scenario that waits for
-- clients pauses ticks until every awaited player has joined, so its tick
-- deadlines measure only game behaviour. The engine processes joins while
-- ticks are paused.
local join = {}

-- Pause game time until the named players are connected. Called before a
-- reload, the pause is saved, so the restarted server waits for every client.
function join.await(names)
  storage.awaited_players = names
  game.tick_paused = true
end

-- Resume game time once every awaited player is connected; call from
-- on_player_joined_game. Returns whether the wait ended with this join.
function join.joined()
  local names = storage.awaited_players
  if not names then return false end
  for _, name in pairs(names) do
    local player = game.get_player(name)
    if not (player and player.connected) then return false end
  end
  storage.awaited_players = nil
  game.tick_paused = false
  return true
end

return join

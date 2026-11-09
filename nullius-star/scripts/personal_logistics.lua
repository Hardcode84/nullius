local logistics = {}

function logistics.requester(player)
  if not player.connected or not player.character or
      not player.force.character_logistic_requests then return nil end
  local point = player.character.get_requester_point()
  if point and point.enabled then return point end
end

function logistics.matches_quality(filter, quality)
  if not filter.quality then return true end
  local actual = prototypes.quality[quality].level
  local wanted = prototypes.quality[filter.quality].level
  local comparison = filter.comparator or "="
  if comparison == "=" then return actual == wanted end
  if comparison == ">" then return actual > wanted end
  if comparison == "<" then return actual < wanted end
  if comparison == "≥" or comparison == ">=" then return actual >= wanted end
  if comparison == "≤" or comparison == "<=" then return actual <= wanted end
  if comparison == "≠" or comparison == "!=" then return actual ~= wanted end
  error("Unexpected logistic quality comparator: " .. comparison)
end

return logistics

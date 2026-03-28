-- Shared utilities for Vulcanus prototypes.

local vulcanus_util = {}

-- Generate heat connections along all edges of an entity, following the
-- nuclear reactor pattern: positions on each edge, direction facing outward.
-- Connections at corners serve two edges (duplicated with both directions).
function vulcanus_util.make_heat_connections(half)
  local c = {}
  local large = half > 2.0
  -- North edge.
  table.insert(c, {position = {-half, -half}, direction = defines.direction.north})
  if large then
    table.insert(c, {position = {0, -half}, direction = defines.direction.north})
  end
  table.insert(c, {position = {half, -half}, direction = defines.direction.north})
  -- East edge.
  table.insert(c, {position = {half, -half}, direction = defines.direction.east})
  if large then
    table.insert(c, {position = {half, 0}, direction = defines.direction.east})
  end
  table.insert(c, {position = {half, half}, direction = defines.direction.east})
  -- South edge.
  table.insert(c, {position = {half, half}, direction = defines.direction.south})
  if large then
    table.insert(c, {position = {0, half}, direction = defines.direction.south})
  end
  table.insert(c, {position = {-half, half}, direction = defines.direction.south})
  -- West edge.
  table.insert(c, {position = {-half, half}, direction = defines.direction.west})
  if large then
    table.insert(c, {position = {-half, 0}, direction = defines.direction.west})
  end
  table.insert(c, {position = {-half, -half}, direction = defines.direction.west})
  return c
end

return vulcanus_util

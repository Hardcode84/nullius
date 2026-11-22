local surface = game.planets["nullius-gleba"].surface
if not surface then return end

local resources = {"nullius-gleba-rock", "nullius-microbial-mat"}
local reserved = {}
local function reserve_patch(drill, prototype)
  local radius = prototype.mining_drill_radius
  local x, y = drill.position.x, drill.position.y
  local area = {{x - radius, y - radius}, {x + radius, y + radius}}
  for _, ore in pairs(surface.find_entities_filtered{name = resources, area = area}) do
    local pos = ore.position
    reserved[pos.x] = reserved[pos.x] or {}
    reserved[pos.x][pos.y] = true
  end
end

for _, drill in pairs(surface.find_entities_filtered{type = "mining-drill"}) do
  reserve_patch(drill, drill.prototype)
end
for _, ghost in pairs(surface.find_entities_filtered{ghost_type = "mining-drill"}) do
  reserve_patch(ghost, ghost.ghost_prototype)
end

-- Keep the resources in reach of installed and planned drills.
for chunk in surface.get_chunks() do
  for _, ore in pairs(surface.find_entities_filtered{name = resources, area = chunk.area}) do
    local pos = ore.position
    if not (reserved[pos.x] and reserved[pos.x][pos.y]) then ore.destroy() end
  end
end
surface.regenerate_entity(resources)

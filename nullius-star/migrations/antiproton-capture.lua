-- Antimatter traps are no longer nuclear fuel. The engine keeps them in the fuel
-- slots of burners that accepted them, where they block real fuel: a reactor
-- or car has one slot. Move every such trap next to its owner for pickup.
local TRAP = "nullius-antimatter-trap"

local function nuclear(burner)
  return burner and burner.fuel_categories["nullius-nuclear"]
end

local entities, equipment = {}, {}
for name, prototype in pairs(prototypes.entity) do
  if nuclear(prototype.burner_prototype) then entities[#entities + 1] = name end
end
for name, prototype in pairs(prototypes.equipment) do
  if nuclear(prototype.burner_prototype) then equipment[name] = true end
end

local function spill(surface, position, force, count)
  surface.spill_item_stack{position = position, stack = {name = TRAP, count = count}, force = force,
    enable_looted = true, allow_belts = false}
end

local function purge(inventory, surface, position, force)
  local count = inventory and inventory.get_item_count(TRAP) or 0
  if count > 0 then
    inventory.remove{name = TRAP, count = count}
    spill(surface, position, force, count)
  end
end

local function purge_grid(grid, surface, position, force)
  if not grid then return end
  for _, item in pairs(grid.equipment) do
    if equipment[item.name] then purge(item.burner.inventory, surface, position, force) end
  end
end

-- Armor and other gridded items may lie in any inventory.
local function purge_stacks(inventory, surface, position, force)
  if not inventory then return end
  for index = 1, #inventory do
    local stack = inventory[index]
    if stack.valid_for_read and stack.grid then purge_grid(stack.grid, surface, position, force) end
  end
end

local function purge_inventories(owner, surface, position, force)
  for index = 1, owner.get_max_inventory_index() do
    purge_stacks(owner.get_inventory(index), surface, position, force)
  end
end

local HOLDERS = {"container", "logistic-container", "linked-container", "infinity-container",
  "temporary-container", "character", "character-corpse", "car", "spider-vehicle", "locomotive",
  "cargo-wagon", "space-platform-hub", "cargo-landing-pad", "rocket-silo"}

for _, surface in pairs(game.surfaces) do
  if #entities > 0 then
    for _, entity in pairs(surface.find_entities_filtered{name = entities}) do
      purge(entity.burner.inventory, surface, entity.position, entity.force)
    end
  end
  for _, entity in pairs(surface.find_entities_filtered{type = HOLDERS}) do
    if entity.grid then purge_grid(entity.grid, surface, entity.position, entity.force) end
    purge_inventories(entity, surface, entity.position, entity.force)
  end
end
-- Players without a character keep their inventories on the player.
for _, player in pairs(game.players) do
  if not player.character and player.surface then
    purge_inventories(player, player.surface, player.position, player.force)
  end
end

local assemblers = {}
local modern = require("factorio-version").is_2_1
local specs = require("shared.overcharged-assemblers")
local by_base, by_variant = {}, {}
for _, spec in ipairs(specs) do
  by_base[spec.base] = spec
  by_variant[spec.base .. "-overcharged"] = spec
end

function assemblers.unlocked(force, base)
  local tier = assert(by_base[base], "Unknown overcharged assembler " .. base).tier
  if tier == 1 then return true end
  return force.technologies["nullius-overcharged-assembly-" .. tier].researched and
    force.recipes[base].enabled
end

local function accepts_recipe(prototype, recipe)
  if not recipe then return true end
  if not modern and prototype.crafting_categories[recipe.category] then return true end
  for _, category in pairs(modern and recipe.categories or recipe.additional_categories or {}) do
    if prototype.crafting_categories[category] then return true end
  end
  return false
end

-- Switching preserves compatible work, settings and contents. An incompatible
-- recipe is cancelled; its removed items are returned on the ground.
function assemblers.replace(entity, name, force)
  if entity.type == "entity-ghost" then
    local tags = entity.tags
    local wires = {}
    for id, connector in pairs(entity.get_wire_connectors(false)) do
      for _, connection in pairs(connector.connections) do
        wires[#wires + 1] = {id=id, target=connection.target, origin=connection.origin}
      end
    end
    local replacement = assert(replace_fluid_entity(entity, name, force, nil))
    replacement.tags = tags
    for _, wire in ipairs(wires) do
      assert(replacement.get_wire_connector(wire.id, true).connect_to(
        wire.target, false, wire.origin), "Cannot restore assembler ghost wire")
    end
    return replacement
  end
  local refunded
  if not accepts_recipe(prototypes.entity[name], entity.get_recipe()) then
    refunded = entity.set_recipe(nil)
  end
  local progress = entity.crafting_progress
  local bonus = entity.bonus_progress
  local energy = entity.prototype.electric_energy_source_prototype and entity.energy or 0
  local health = entity.health
  local disabled = entity.disabled_by_script
  local replacement = assert(replace_fluid_entity(entity, name, force, nil),
    "Cannot switch assembler to " .. name)
  replacement.crafting_progress = progress
  replacement.bonus_progress = bonus
  if replacement.prototype.electric_energy_source_prototype then
    replacement.energy = math.min(energy, replacement.electric_buffer_size)
  end
  replacement.health = health
  replacement.disabled_by_script = disabled
  for _, stack in ipairs(refunded or {}) do
    replacement.surface.spill_item_stack{
      position=replacement.position, stack=stack, enable_looted=true,
      allow_belts=false, use_start_position_on_failure=true,
    }
  end
  return replacement
end

-- Locked modes placed from blueprints or upgrades become ordinary assemblers.
function assemblers.built(entity)
  local name = entity.type == "entity-ghost" and entity.ghost_name or entity.name
  local spec = by_variant[name]
  if spec and not assemblers.unlocked(entity.force, spec.base) then
    return assemblers.replace(entity, spec.base, entity.force)
  end
  return entity
end

function assemblers.register()
  local transitions = require("scripts.transitions")
  for _, spec in ipairs(specs) do
    local base = spec.base
    local variant = base .. "-overcharged"
    transitions.register(base, variant, {
      condition = function(_, force) return assemblers.unlocked(force, base) end,
      replace_fn = assemblers.replace,
    })
    transitions.register(variant, base, {replace_fn = assemblers.replace})
  end
end

return assemblers

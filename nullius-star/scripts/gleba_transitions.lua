local assemblers = require("scripts.overcharged_assemblers")
local transitions = require("scripts.transitions")

local gleba_transitions = {}
local by_variant = {}

local function release_fuel(entity)
  if entity.type == "entity-ghost" then return end
  for _, inventory in ipairs({entity.get_fuel_inventory(), entity.get_burnt_result_inventory()}) do
    if inventory then
      for i = 1, #inventory do
        local stack = inventory[i]
        if stack.valid_for_read then
          entity.surface.spill_item_stack{position = entity.position, stack = stack, force = entity.force,
            enable_looted = true, use_start_position_on_failure = true}
          stack.clear()
        end
      end
    end
  end
end

local function is_pump(entity)
  local entity_type = entity.type == "entity-ghost" and entity.ghost_type or entity.type
  return entity_type == "pump"
end

local function replace(entity, name, force)
  if is_pump(entity) then
    local health = entity.type ~= "entity-ghost" and entity.health or nil
    local replacement = assert(replace_pump_valve(entity, name, force), "Could not switch to " .. name)
    if health then replacement.health = health end
    if replacement.type ~= "entity-ghost" and replacement.prototype.electric_energy_source_prototype then
      replacement.energy = 0
    end
    return replacement
  end
  if entity.type == "assembling-machine" or entity.type == "entity-ghost" then
    return assemblers.replace(entity, name, force)
  end
  local health = entity.health
  local replacement = assert(replace_fluid_entity(entity, name, force), "Could not switch to " .. name)
  replacement.health = health
  if replacement.prototype.electric_energy_source_prototype then replacement.energy = 0 end
  return replacement
end

local function unlocked(entity, force)
  return entity.surface.name == "nullius-gleba" and force.technologies["nullius-nutrient-technology"].researched
end

function gleba_transitions.built(entity)
  if not entity or not entity.valid then return entity end
  local name = entity.type == "entity-ghost" and entity.ghost_name or entity.name
  local base = by_variant[name]
  if base and not unlocked(entity, entity.force) then
    release_fuel(entity)
    return replace(entity, base, entity.force)
  end
  return entity
end

for _, spec in ipairs(require("shared.gleba-machines")) do
  local ordinary, nutrient = spec.name, spec.name .. "-nutrient"
  by_variant[nutrient] = ordinary
  transitions.register(ordinary, nutrient, {
    replace_fn = replace,
    condition = unlocked,
  })
  transitions.register(nutrient, ordinary, {on_leave = release_fuel, replace_fn = replace})
end

return gleba_transitions

local assemblers = require("scripts.overcharged_assemblers")
local transitions = require("scripts.transitions")

local function release_fuel(entity)
  if entity.type == "entity-ghost" then return end
  for _, inventory in ipairs({entity.get_fuel_inventory(), entity.get_burnt_result_inventory()}) do
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

local function replace(entity, name, force)
  if entity.type == "assembling-machine" or entity.type == "entity-ghost" then
    return assemblers.replace(entity, name, force)
  end
  local health = entity.health
  local replacement = assert(replace_fluid_entity(entity, name, force), "Could not switch to " .. name)
  replacement.health = health
  if replacement.prototype.electric_energy_source_prototype then replacement.energy = 0 end
  return replacement
end

for _, spec in ipairs(require("shared.gleba-machines")) do
  local ordinary, nutrient = spec.name, spec.name .. "-nutrient"
  transitions.register(ordinary, nutrient, {
    replace_fn = replace,
    condition = function(entity, force)
      return entity.surface.name == "nullius-gleba" and force.technologies["nullius-probe-gleba"].researched
    end,
  })
  transitions.register(nutrient, ordinary, {on_leave = release_fuel, replace_fn = replace})
end

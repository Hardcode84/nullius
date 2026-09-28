local assemblers = {}

-- Cold user-action path. Native fast replacement transfers inventories,
-- modules, settings and wires. Preserve paid crafting work and joules too.
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
  return replacement
end

function assemblers.register()
  local transitions = require("scripts.transitions")
  for _, spec in ipairs(require("shared.overcharged-assemblers")) do
    local base = spec.base
    local variant = base .. "-overcharged"
    transitions.register(base, variant, {replace_fn = assemblers.replace})
    transitions.register(variant, base, {replace_fn = assemblers.replace})
  end
end

return assemblers

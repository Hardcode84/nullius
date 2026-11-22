-- Bioreactor modes of chemical and hydro plants, on every surface.
local assemblers = require("scripts.overcharged_assemblers")
local burner_fuel = require("scripts.burner_fuel")
local transitions = require("scripts.transitions")
local shared = require("shared.bioreactors")

local bioreactors = {}
local by_base, by_variant = {}, {}
for _, spec in ipairs(shared.specs) do
  by_base[spec.base] = spec
  by_variant[spec.base .. "-bioreactor"] = spec
end

function bioreactors.has(base)
  return by_base[base] ~= nil
end

-- A mode needs its tier research and the ordinary machine's construction recipe.
function bioreactors.unlocked(force, base)
  local spec = assert(by_base[base], "Unknown bioreactor base " .. base)
  return force.technologies[shared.research(spec.tier)].researched and force.recipes[base].enabled
end

-- Another mode switches to the bioreactor before its own return edge to the ordinary machine.
function bioreactors.register_from(mode, base, on_leave)
  transitions.register(mode, base .. "-bioreactor", {
    condition = function(_, force) return bioreactors.unlocked(force, base) end,
    on_leave = on_leave,
    replace_fn = assemblers.replace,
  })
end

-- Locked modes placed from blueprints or upgrades become ordinary machines.
function bioreactors.built(entity)
  if not entity or not entity.valid then return entity end
  local spec = by_variant[entity.type == "entity-ghost" and entity.ghost_name or entity.name]
  if spec and not bioreactors.unlocked(entity.force, spec.base) then
    burner_fuel.release(entity)
    return assemblers.replace(entity, spec.base, entity.force)
  end
  return entity
end

-- Registered after the planet modes, so an ordinary machine enters those first.
function bioreactors.register()
  for _, spec in ipairs(shared.specs) do
    bioreactors.register_from(spec.base, spec.base)
    transitions.register(spec.base .. "-bioreactor", spec.base, {
      on_leave = burner_fuel.release,
      replace_fn = assemblers.replace,
    })
  end
end

return bioreactors

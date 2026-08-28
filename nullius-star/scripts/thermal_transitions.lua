local transitions = require("scripts.transitions")
local tier_specs = require("thermal-machine-specs")

local function is_nauvis_thermal(entity, force, base, technology_name)
  local technology = force.technologies[technology_name]
  return entity.surface.name == "nauvis" and
    technology ~= nil and technology.researched and
    force.recipes[base] ~= nil and force.recipes[base].enabled
end

local function is_nauvis(entity)
  return entity.surface.name == "nauvis"
end

local function register_thermal_pair(base, technology)
  local thermal = base .. "-thermal"
  transitions.register(base, thermal, {
    condition = function(entity, force)
      return is_nauvis_thermal(entity, force, base, technology)
    end,
  })
  transitions.register(thermal, base, {condition = is_nauvis})
end

for _, tier in ipairs(tier_specs) do
  for _, base in ipairs(tier.machines) do
    register_thermal_pair(base, tier.technology)
  end
end

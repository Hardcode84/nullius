local transitions = require("scripts.transitions")
local tier_specs = require("thermal-machine-specs")

local function is_thermal_unlocked(force, base, technology_name)
  local technology = force.technologies[technology_name]
  return technology ~= nil and technology.researched and
    force.recipes[base] ~= nil and force.recipes[base].enabled
end

local function register_thermal_pair(base, technology)
  local thermal = base .. "-thermal"
  transitions.register(base, thermal, {
    condition = function(_, force)
      return is_thermal_unlocked(force, base, technology)
    end,
  })
  transitions.register(thermal, base)
end

for _, tier in ipairs(tier_specs) do
  for _, base in ipairs(tier.machines) do
    register_thermal_pair(base, tier.technology)
  end
end

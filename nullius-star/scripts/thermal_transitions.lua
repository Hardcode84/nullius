local TECHNOLOGY = "nullius-thermal-engineering-1"
local transitions = require("scripts.transitions")

local function is_nauvis_thermal(entity, force)
  local technology = force.technologies[TECHNOLOGY]
  return entity.surface.name == "nauvis" and
    technology ~= nil and technology.researched
end

local function is_nauvis(entity)
  return entity.surface.name == "nauvis"
end

local function register_thermal_pair(base)
  local thermal = base .. "-thermal"
  transitions.register(base, thermal, {condition = is_nauvis_thermal})
  transitions.register(thermal, base, {condition = is_nauvis})
end

register_thermal_pair("nullius-crusher-1")
register_thermal_pair("nullius-small-furnace-1")
register_thermal_pair("nullius-foundry-1")

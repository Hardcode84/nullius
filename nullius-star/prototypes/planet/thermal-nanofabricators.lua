local vulcanus_util = require("prototypes.planet.vulcanus-util")
local specs = require("thermal-nanofabricator-specs")

for _, spec in ipairs(specs) do
  local base = data.raw["assembling-machine"][spec.base]
  if not base then
    error("Missing base nanofabricator for thermal variant: " .. spec.base)
  end

  local thermal = table.deepcopy(base)
  thermal.name = spec.base .. "-thermal"
  thermal.localised_name = {
    "entity-name.nullius-thermal-nanofabricator", tostring(spec.tier),
  }
  thermal.localised_description = {
    "", "[color=orange]Thermal mode[/color]\n",
    base.localised_description or {"entity-description.nullius-nanofabricator"},
  }
  thermal.placeable_by = {item = spec.base, count = 1}
  thermal.hidden = true
  thermal.next_upgrade = nil
  thermal.energy_usage = spec.energy_usage

  local collision = thermal.collision_box
  local heat_half = math.min(
    math.abs(collision[1][1]), math.abs(collision[1][2])) - 0.1
  thermal.energy_source = {
    type = "heat",
    max_temperature = spec.max_temperature,
    specific_heat = "200kJ",
    max_transfer = "4MW",
    min_working_temperature = spec.min_temperature,
    default_temperature = 15,
    connections = vulcanus_util.make_heat_connections(heat_half),
    pipe_covers = data.raw.boiler["heat-exchanger"].energy_source.pipe_covers,
    heat_pipe_covers =
      data.raw.boiler["heat-exchanger"].energy_source.heat_pipe_covers,
  }

  data:extend({thermal})
end

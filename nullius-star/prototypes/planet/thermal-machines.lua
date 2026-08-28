local vulcanus_util = require("prototypes.planet.vulcanus-util")

local function thermal_variant(base_name)
  local base = data.raw["assembling-machine"][base_name]
  if not base then
    error("Missing base machine for thermal variant: " .. base_name)
  end

  local thermal = table.deepcopy(base)
  thermal.name = base_name .. "-thermal"
  thermal.localised_name = base.localised_name or {"entity-name." .. base_name}
  thermal.localised_description = {
    "", "[color=orange]Thermal mode[/color]\n",
    base.localised_description or {"entity-description." .. base_name},
  }
  thermal.placeable_by = {item = base_name, count = 1}
  thermal.hidden = true
  thermal.next_upgrade = nil
  thermal.effect_receiver = {base_effect = {productivity = 0.05}}

  local collision = thermal.collision_box or {{-0.7, -0.7}, {0.7, 0.7}}
  local heat_half = math.min(
    math.abs(collision[1][1]), math.abs(collision[1][2])) - 0.1
  if heat_half < 0.5 then heat_half = 0.5 end
  thermal.energy_source = {
    type = "heat",
    max_temperature = 250,
    specific_heat = "200kJ",
    max_transfer = "2MW",
    min_working_temperature = 100,
    default_temperature = 15,
    connections = vulcanus_util.make_heat_connections(heat_half),
    pipe_covers = data.raw.boiler["heat-exchanger"].energy_source.pipe_covers,
    heat_pipe_covers =
      data.raw.boiler["heat-exchanger"].energy_source.heat_pipe_covers,
  }

  data:extend({thermal})
end

thermal_variant("nullius-crusher-1")
thermal_variant("nullius-small-furnace-1")
thermal_variant("nullius-foundry-1")

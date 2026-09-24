-- Runtime map-generation fields that are not valid in planet prototypes.

local surface_config = {}

local controlled_planets = {
  ["nullius-vulcanus"] = true,
  ["nullius-fulgora"] = true,
  vulcanus = true,
  fulgora = true,
  gleba = true,
  aquilo = true,
}

function surface_config.configure(surface)
  if not surface or not surface.valid then return end
  local planet = surface.planet
  if not planet or not controlled_planets[planet.name] then return end

  local settings = surface.map_gen_settings
  if planet.name == "nullius-fulgora" then
    -- Cold configuration path: keep generated chunks and the surface seed,
    -- but use the current planet definition for subsequent terrain generation.
    local native = planet.prototype.map_gen_settings
    settings.property_expression_names = native.property_expression_names
    settings.autoplace_settings = native.autoplace_settings
    settings.cliff_settings = native.cliff_settings
  end
  settings.no_enemies_mode = true
  settings.default_enable_all_autoplace_controls = false
  surface.map_gen_settings = settings
end

function surface_config.configure_existing()
  for _, surface in pairs(game.surfaces) do
    surface_config.configure(surface)
  end
end

script.on_event(defines.events.on_surface_created, function(event)
  surface_config.configure(game.surfaces[event.surface_index])
end)

return surface_config

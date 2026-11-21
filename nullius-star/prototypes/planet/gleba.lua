local planet = table.deepcopy(data.raw.planet.gleba)
planet.name = "nullius-gleba"
planet.order = "d[nullius-gleba]"
planet.pollutant_type = nil
planet.asteroid_spawn_definitions = {}

local map = planet.map_gen_settings
map.autoplace_controls = {gleba_water = {}, gleba_cliff = {}}
map.autoplace_settings.tile.treat_missing_as_default = false
map.autoplace_settings.entity = {treat_missing_as_default = false, settings = {}}
map.autoplace_settings.decorative = {treat_missing_as_default = false, settings = {
  ["cracked-mud-decal"] = {}, ["grey-cracked-mud-decal"] = {},
  ["dark-mud-decal"] = {}, ["light-mud-decal"] = {},
}}

data:extend({planet, {
  type = "space-connection", name = "nauvis-nullius-gleba",
  subgroup = "planet-connections", from = "nauvis", to = planet.name,
  order = "c", length = 15000, asteroid_spawn_definitions = {},
}, {
  type = "technology", name = "nullius-probe-gleba", order = "nullius-dg",
  icon = planet.icon, icon_size = 64,
  prerequisites = {"nullius-interplanetary-signal-acquisition", "nullius-organic-chemistry-1"},
  effects = {{type = "unlock-space-location", space_location = planet.name}},
  unit = {count = 40, time = 20, ingredients = {
    {"nullius-geology-pack", 1}, {"nullius-climatology-pack", 1},
    {"nullius-mechanical-pack", 1}, {"nullius-electrical-pack", 1},
  }},
}})

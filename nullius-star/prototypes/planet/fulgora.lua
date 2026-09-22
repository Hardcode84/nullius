-- Cold data-stage path: natural terrain and probe access, without industry.
local planet = table.deepcopy(data.raw.planet.fulgora)
planet.name = "nullius-fulgora"
planet.order = "c[nullius-fulgora]"
planet.asteroid_spawn_definitions = {}
-- Storm power and protection are a separate mechanic. Native destructive
-- lightning is not part of the Nullius Fulgora design.
planet.lightning_properties = nil
planet.surface_properties["nullius-ambient-temperature"] = 25
local map = planet.map_gen_settings
map.autoplace_controls.scrap = nil
map.autoplace_settings = {
  tile = {treat_missing_as_default = false, settings = {
    ["fulgoran-dust"] = {}, ["fulgoran-dunes"] = {},
    ["fulgoran-sand"] = {}, ["fulgoran-rock"] = {},
  }},
  decorative = {treat_missing_as_default = false, settings = {
    ["medium-fulgora-rock"] = {}, ["small-fulgora-rock"] = {},
    ["tiny-fulgora-rock"] = {},
  }},
  entity = {treat_missing_as_default = false, settings = {}},
}
-- Cover low basins with dry sand. Do not use the native city's road or scrap
-- masks to choose natural terrain.
map.property_expression_names["tile:fulgoran-dust:probability"] = "0.8 + fulgora_rock"
map.property_expression_names["tile:fulgoran-rock:probability"] = "0.5 + 2 * fulgora_rock"
data:extend({planet, {
  type = "space-connection", name = "nauvis-nullius-fulgora",
  subgroup = "planet-connections", from = "nauvis", to = planet.name,
  order = "b", length = 15000, asteroid_spawn_definitions = {},
}, {
  type = "technology", name = "nullius-probe-fulgora", order = "nullius-df",
  icon = "__space-age__/graphics/icons/fulgora.png", icon_size = 64,
  effects = {},
  prerequisites = {"nullius-interplanetary-signal-acquisition", "nullius-insulation-1"},
  unit = {count = 30, time = 20, ingredients = {
    {"nullius-geology-pack", 1}, {"nullius-climatology-pack", 1},
    {"nullius-mechanical-pack", 1}, {"nullius-electrical-pack", 1},
  }},
}})

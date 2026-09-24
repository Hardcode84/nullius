-- Cold data-stage path: natural terrain and probe access, without industry.
-- Dry sediment is walkable, but cannot carry buildings, landfill, or paving.
local basin = table.deepcopy(data.raw.tile["fulgoran-dust"])
basin.name = "nullius-fulgora-sediment"
basin.order = "b[natural]-e[sediment]"
basin.layer = 5
basin.collision_mask = {layers={water_tile=true, ground_tile=true, resource=true}}
basin.variants = table.deepcopy(data.raw.tile["mineral-cream-dirt-1"].variants)
basin.tint = {1, 0.9, 1}
basin.map_color = {174, 156, 119}
basin.walking_speed_modifier = 0.85
-- Keep each native oil tile's probability, layer, and correction behavior.
local sediment_tiles = {}
local native_tiles = data.raw.planet.fulgora.map_gen_settings.autoplace_settings.tile.settings
for name in pairs(native_tiles) do
  if name:find("oil-ocean-",1,true)==1 then
    local native = data.raw.tile[name]
    local sediment = table.deepcopy(basin)
    local suffix = name:sub(#"oil-ocean-"+1)
    sediment.name = basin.name .. (suffix=="shallow" and "" or "-"..suffix)
    sediment.localised_name = {"tile-name.nullius-fulgora-sediment"}
    sediment.localised_description = {"tile-description.nullius-fulgora-sediment"}
    if sediment.name~=basin.name then sediment.factoriopedia_alternative=basin.name end
    sediment.layer = native.layer
    sediment.layer_group = native.layer_group
    sediment.autoplace = table.deepcopy(native.autoplace)
    sediment_tiles[sediment.name] = {}
    data:extend({sediment})
  end
end
-- Keep the former city's tile boundaries too, but use natural dust graphics.
local natural_tiles = {}
for _,name in ipairs({"fulgoran-paving", "fulgoran-walls", "fulgoran-conduit", "fulgoran-machinery"}) do
  local native = data.raw.tile[name]
  local tile = table.deepcopy(data.raw.tile["fulgoran-dust"])
  tile.name = "nullius-"..name
  tile.localised_name = {"tile-name.fulgoran-dust"}
  tile.factoriopedia_alternative = "fulgoran-dust"
  tile.layer = native.layer
  tile.layer_group = native.layer_group
  tile.autoplace = table.deepcopy(native.autoplace)
  natural_tiles[tile.name] = {}
  data:extend({tile})
end
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
  entity = {treat_missing_as_default = false, settings = {
    ["big-fulgora-rock"] = {}, ["fulgurite"] = {},
  }},
}
for name in pairs(sediment_tiles) do map.autoplace_settings.tile.settings[name] = {} end
for name in pairs(natural_tiles) do map.autoplace_settings.tile.settings[name] = {} end
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

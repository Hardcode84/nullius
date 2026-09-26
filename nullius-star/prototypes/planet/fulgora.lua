-- Cold data-stage path: native terrain, hydrocarbon vents, and probe access.
data:extend({{type="collision-layer", name="nullius_fulgora_sand"}})
local basin = table.deepcopy(data.raw.tile["fulgoran-dust"])
basin.name = "nullius-fulgora-sediment"
basin.order = "b[natural]-e[sediment]"
basin.layer = 5
basin.collision_mask = {layers={ground_tile=true, nullius_fulgora_sand=true}}
basin.variants = table.deepcopy(data.raw.tile["mineral-cream-dirt-1"].variants)
basin.walking_speed_modifier = 0.85
-- Keep each native oil tile's probability, layer, and correction behavior.
local sediment_shades = {
  shallow = {tint={1, 0.63, 0.57}, map_color={190, 111, 81}},
  ["shallow-2"] = {tint={1, 0.73, 0.65}, map_color={210, 137, 107}},
  deep = {tint={0.80, 0.46, 0.40}, map_color={143, 74, 58}},
  ["deep-2"] = {tint={0.90, 0.54, 0.47}, map_color={168, 92, 74}},
}
local sediment_tiles = {}
local native_tiles = data.raw.planet.fulgora.map_gen_settings.autoplace_settings.tile.settings
for name in pairs(native_tiles) do
  if name:find("oil-ocean-",1,true)==1 then
    local native = data.raw.tile[name]
    local sediment = table.deepcopy(basin)
    local suffix = name:sub(#"oil-ocean-"+1)
    local shade = sediment_shades[suffix]
    sediment.tint = shade.tint
    sediment.map_color = shade.map_color
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
local resource_autoplace = require("resource-autoplace")
local vent = table.deepcopy(data.raw.resource["crude-oil"])
vent.name = "nullius-hydrocarbon-vent"
vent.order = "nullius-hydrocarbon"
-- Space Age adds an Aquilo snow-placement effect to the shared oil prototype.
vent.created_effect = nil
vent.minable.results = {{type="fluid", name="nullius-hydrocarbon-slurry", amount=10}}
vent.autoplace = resource_autoplace.resource_autoplace_settings{
  name=vent.name, autoplace_set_name="nullius_fulgora", order="c",
  base_density=65.6, base_spots_per_km2=14.4,
  random_probability=1/48, random_spot_size_minimum=1,
  random_spot_size_maximum=1, additional_richness=220000,
  regular_rq_factor_multiplier=1,
}
vent.autoplace.tile_restriction = {}
for name in pairs(sediment_tiles) do
  table.insert(vent.autoplace.tile_restriction, name)
end
table.sort(vent.autoplace.tile_restriction)
data:extend({vent, {
  type="autoplace-control", name=vent.name, category="resource",
  richness=true, order="nullius-hydrocarbon",
  localised_name={"entity-name.nullius-hydrocarbon-vent"},
}})
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
map.autoplace_controls[vent.name] = {frequency=1, size=1, richness=1}
map.autoplace_controls.fulgora_islands.size = 2
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
    ["nullius-hydrocarbon-vent"] = {},
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

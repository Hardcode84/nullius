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

data:extend({{
  type = "noise-expression", name = "nullius_gleba_rock_cluster",
  expression = "(0.70 + 0.30 * max(gleba_highland, lower_cliff, upper_cliff)) * max(0, 0.48 + gleba_cover_noise)",
  local_expressions = {
    lower_cliff = "gleba_select(elevation, cliff_elevation_0 - 10, cliff_elevation_0, 2, 0, 1)",
    upper_cliff = "gleba_select(elevation, upper_level - 10, upper_level, 2, 0, 1)",
    upper_level = "cliff_elevation_0 + cliff_elevation_interval",
  },
}})

local bank_tiles, dry_tiles, shelf_tiles = {}, {}, {}
for name in pairs(map.autoplace_settings.tile.settings) do
  if not data.raw.tile[name].fluid then
    dry_tiles[#dry_tiles + 1] = name
  end
  if name:match("^lowland%-") then bank_tiles[#bank_tiles + 1] = name end
  if name:match("^wetland%-") or name:match("^lowland%-") then
    shelf_tiles[#shelf_tiles + 1] = name
  end
end

local function place_decorative(prop, tiles, probability)
  prop.autoplace = {
    order = prop.name, default_enabled = false, tile_restriction = tiles,
    probability_expression = probability,
  }
  data:extend({prop})
  map.autoplace_settings.decorative.settings[prop.name] = {}
end

local function add_decorative(source, tiles, probability)
  local prop = table.deepcopy(data.raw["optimized-decorative"][source])
  prop.name = "nullius-gleba-" .. source
  prop.localised_name = {"decorative-name." .. source}
  place_decorative(prop, tiles, probability)
end

-- The outcrops use the rock artwork alone. They allow movement and construction.
local function add_outcrop(name, source, tiles, probability)
  local rock = data.raw["simple-entity"][source]
  place_decorative({
    type = "optimized-decorative", name = name, render_layer = "object",
    pictures = rock.pictures, collision_box = rock.collision_box,
    collision_mask = {layers = {doodad = true}, colliding_with_tiles_only = true},
  }, tiles, probability)
end

add_decorative("calcite-stain-small", bank_tiles,
  "0.16 * gleba_select(elevation, 2.7, 5, 0.3, 0, 1) * clamp(gleba_decal_noise, 0, 1)")
add_decorative("medium-rock", dry_tiles, "0.20 * max(0, nullius_gleba_rock_cluster - 0.20)")
add_decorative("small-rock", dry_tiles, "0.27 * max(0, nullius_gleba_rock_cluster - 0.10)")
add_decorative("pumice-relief-decal", dry_tiles, "0.08 * max(0, nullius_gleba_rock_cluster - 0.18)")
add_outcrop("nullius-gleba-weathered-slab", "big-sand-rock", dry_tiles,
  "0.055 * max(0, nullius_gleba_rock_cluster - 0.30)")
add_outcrop("nullius-gleba-mineral-mound", "iron-stromatolite", shelf_tiles,
  "0.055 * gleba_select(elevation, 0.5, 12, 0.5, 0, 1) * max(0, 0.18 + gleba_decal_noise)")

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

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

-- Each resource has a landing patch and separate fields in the surrounding terrain.
local function add_patch(name, product, icon, color, offset, noise_seed, mat)
  local ore = table.deepcopy(data.raw.resource.stone)
  ore.name, ore.icon, ore.icon_size = name, icon, 64
  ore.icons, ore.factoriopedia_simulation = nil, nil
  ore.infinite, ore.normal, ore.minimum, ore.infinite_depletion_amount = true, 100, 100, 0
  ore.minable = {mining_time = mat and 2 or 1, result = product}
  ore.map_color, ore.mining_visualisation_tint = color, color
  ore.highlight = true
  if mat then
    ore.stage_counts = {0}
    ore.stages = {sheet = {
      filename = "__space-age__/graphics/decorative/polycephalum/polycephalum-slime.png",
      width = 216, height = 188, line_length = 1, frame_count = 1, variation_count = 9,
      scale = 0.22,
    }}
  else
    ore.stages.sheet.tint = color
  end
  local noise = "basis_noise{x=x,y=y,seed0=map_seed,seed1=" .. noise_seed ..
    ",input_scale=0.035,output_scale=1}"
  ore.autoplace = {
    default_enabled = false, tile_restriction = dry_tiles,
    probability_expression = "max(9 - sqrt((x - (" .. offset .. "))^2 + (y - 8)^2) + 2 * gleba_cover_noise, min(distance - 70, (" .. noise .. " - 0.68) * 12))",
    richness_expression = "100",
  }
  data:extend({ore})
  map.autoplace_settings.entity.settings[name] = {}
end

add_patch("nullius-gleba-rock", "nullius-gleba-rock", "__space-age__/graphics/icons/iron-stromatolite.png",
  {0.83, 0.50, 0.30}, -23, 414, false)
add_patch("nullius-microbial-mat", "nullius-mat-sample", "__space-age__/graphics/icons/iron-bacteria.png",
  {0.68, 0.85, 0.22}, 23, 872, true)

data:extend({{type = "surface-property", name = "nullius-hydrogen-sulfide", default_value = 0}})
planet.surface_properties["nullius-hydrogen-sulfide"] = 1

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
}})

-- Nullius* Vulcanus planet definition.
-- Uses SA terrain generation and graphics but with modified resources:
-- no tungsten, no coal, no demolishers, no burning trees.
-- Resources: sulfuric-acid-geyser (becomes HCl geyser via data-final-fixes), lava.

local effects = require("__core__.lualib.surface-render-parameter-effects")

local minute = 60 * 60

-- Custom surface property: ambient temperature in Celsius.
-- Default 25C (Nauvis). Vulcanus is 200C.
-- Used in surface_conditions to restrict entities/recipes to specific thermal environments.
data:extend({
  {
    type = "surface-property",
    name = "nullius-ambient-temperature",
    default_value = 25,
    localised_name = {"surface-property-name.nullius-ambient-temperature"},
    localised_unit_key = "surface-property-unit.nullius-ambient-temperature",
  },
})

-- Reuse SA's Vulcanus map gen noise expressions.
-- They are defined by space-age/prototypes/planet/planet-vulcanus-map-gen.lua
-- which loads because space-age mod is a dependency.

local function nullius_vulcanus_map_gen()
  return
  {
    property_expression_names =
    {
      elevation = "vulcanus_elevation",
      temperature = "vulcanus_temperature",
      moisture = "vulcanus_moisture",
      aux = "vulcanus_aux",
      cliffiness = "cliffiness_basic",
      cliff_elevation = "cliff_elevation_from_elevation",
      -- Resources: sulfuric acid geyser only (remapped to HCl).
      -- No tungsten, no coal, no calcite deposits.
      ["entity:sulfuric-acid-geyser:probability"] = "vulcanus_sulfuric_acid_geyser_probability",
      ["entity:sulfuric-acid-geyser:richness"] = "vulcanus_sulfuric_acid_geyser_richness",
    },
    cliff_settings =
    {
      name = "cliff-vulcanus",
      cliff_elevation_interval = 120,
      cliff_elevation_0 = 70
    },
    -- No territory_settings (no demolishers).
    no_enemies_mode = true,
    -- Only use autoplace controls we explicitly list. Without this,
    -- water, trees, and other Nauvis content bleeds into the planet.
    default_enable_all_autoplace_controls = false,
    autoplace_controls =
    {
      ["sulfuric_acid_geyser"] = {},
      ["vulcanus_volcanism"] = {},
    },
    autoplace_settings =
    {
      ["tile"] =
      {
        treat_missing_as_default = false,
        settings =
        {
          ["volcanic-soil-dark"] = {},
          ["volcanic-soil-light"] = {},
          ["volcanic-ash-soil"] = {},
          ["volcanic-ash-flats"] = {},
          ["volcanic-ash-light"] = {},
          ["volcanic-ash-dark"] = {},
          ["volcanic-cracks"] = {},
          ["volcanic-cracks-warm"] = {},
          ["volcanic-folds"] = {},
          ["volcanic-folds-flat"] = {},
          ["lava"] = {},
          ["lava-hot"] = {},
          ["volcanic-folds-warm"] = {},
          ["volcanic-pumice-stones"] = {},
          ["volcanic-cracks-hot"] = {},
          ["volcanic-jagged-ground"] = {},
          ["volcanic-smooth-stone"] = {},
          ["volcanic-smooth-stone-warm"] = {},
          ["volcanic-ash-cracks"] = {},
        }
      },
      ["decorative"] =
      {
        treat_missing_as_default = false,
        settings =
        {
          -- Nauvis decoratives removed (no autoplace on Vulcanus).
          ["vulcanus-rock-decal-large"] = {},
          ["vulcanus-crack-decal-large"] = {},
          ["vulcanus-crack-decal-huge-warm"] = {},
          ["vulcanus-dune-decal"] = {},
          ["vulcanus-sand-decal"] = {},
          ["vulcanus-lava-fire"] = {},
          ["sulfur-stain"] = {},
          ["sulfur-stain-small"] = {},
          ["sulfuric-acid-puddle"] = {},
          ["sulfuric-acid-puddle-small"] = {},
          ["crater-small"] = {},
          ["crater-large"] = {},
          ["pumice-relief-decal"] = {},
          ["small-volcanic-rock"] = {},
          ["medium-volcanic-rock"] = {},
          ["tiny-volcanic-rock"] = {},
          ["tiny-rock-cluster"] = {},
          ["small-sulfur-rock"] = {},
          ["tiny-sulfur-rock"] = {},
          ["sulfur-rock-cluster"] = {},
          ["waves-decal"] = {},
        }
      },
      ["entity"] =
      {
        treat_missing_as_default = false,
        settings =
        {
          -- No coal, no tungsten-ore.
          ["sulfuric-acid-geyser"] = {},
          ["huge-volcanic-rock"] = {},
          ["big-volcanic-rock"] = {},
          ["crater-cliff"] = {},
          ["vulcanus-chimney"] = {},
          ["vulcanus-chimney-faded"] = {},
          ["vulcanus-chimney-cold"] = {},
          ["vulcanus-chimney-short"] = {},
          ["vulcanus-chimney-truncated"] = {},
          -- No trees (lichen trees have no autoplace in Nullius).
        }
      }
    }
  }
end

data:extend({
  {
    type = "planet",
    name = "nullius-vulcanus",
    icon = "__space-age__/graphics/icons/vulcanus.png",
    starmap_icon = "__space-age__/graphics/icons/starmap-planet-vulcanus.png",
    starmap_icon_size = 512,
    gravity_pull = 10,
    distance = 10,
    orientation = 0.1,
    magnitude = 1.5,
    order = "b[nullius-vulcanus]",
    subgroup = "planets",
    map_gen_settings = nullius_vulcanus_map_gen(),
    pollutant_type = nil,
    solar_power_in_space = 600,
    surface_properties =
    {
      ["day-night-cycle"] = 1.5 * minute,
      ["magnetic-field"] = 25,
      ["solar-power"] = 20,
      pressure = 4000,
      gravity = 40,
      ["nullius-ambient-temperature"] = 200,
    },
    persistent_ambient_sounds =
    {
      base_ambience = {filename = "__space-age__/sound/wind/base-wind-vulcanus.ogg", volume = 0.8},
      wind = {filename = "__space-age__/sound/wind/wind-vulcanus.ogg", volume = 0.8},
      crossfade =
      {
        order = {"wind", "base_ambience"},
        curve_type = "cosine",
        from = {control = 0.35, volume_percentage = 0.0},
        to = {control = 2, volume_percentage = 100.0}
      },
      semi_persistent =
      {
        {
          sound = {variations = sound_variations("__space-age__/sound/world/semi-persistent/distant-rumble", 3, 0.5)},
          delay_mean_seconds = 10,
          delay_variance_seconds = 5
        },
        {
          sound = {variations = sound_variations("__space-age__/sound/world/semi-persistent/distant-flames", 5, 0.6)},
          delay_mean_seconds = 15,
          delay_variance_seconds = 7.0
        }
      }
    },
    surface_render_parameters =
    {
      fog = effects.default_fog_effect_properties(),
    },
  },
  -- Connection from Nauvis to Vulcanus.
  {
    type = "space-connection",
    name = "nauvis-nullius-vulcanus",
    subgroup = "planet-connections",
    from = "nauvis",
    to = "nullius-vulcanus",
    order = "a",
    length = 15000,
    asteroid_spawn_definitions = {},
  },
})

-- Cold data-stage path: natural terrain and probe access, without industry.
-- Dry sediment is walkable, but cannot carry buildings, landfill, or paving.
local basin = table.deepcopy(data.raw.tile["fulgoran-dust"])
basin.name = "nullius-fulgora-sediment"
basin.order = "b[natural]-e[sediment]"
basin.layer = 5
basin.collision_mask = {layers={water_tile=true, ground_tile=true, resource=true, floor=true}}
basin.variants = table.deepcopy(data.raw.tile["mineral-cream-dirt-1"].variants)
basin.tint = {1, 0.9, 1}
basin.map_color = {174, 156, 119}
basin.walking_speed_modifier = 0.85
basin.autoplace = {probability_expression="0"}
data:extend({basin, {
  type="noise-expression", name="nullius_fulgora_ridge", hidden=true,
  expression="0.045 - abs(multioctave_noise{x=x, y=y, seed0=map_seed, " ..
    "seed1='nullius-fulgora-ridges', octaves=2, persistence=0.4, input_scale=1/160})",
}, {
  type="noise-expression", name="nullius_fulgora_land", hidden=true,
  expression="max(fulgora_mix_spots, (80 - distance) / 80, nullius_fulgora_ridge)",
}, {
  type="noise-expression", name="nullius_fulgora_elevation", hidden=true,
  expression="80 + 60 * clamp(nullius_fulgora_land, -0.5, 0.5) + " ..
    "20 * ((nullius_fulgora_land > 0) - 0.5)",
}, {
  type="noise-expression", name="nullius_fulgora_cliffiness", hidden=true,
  expression="4 * slider_rescale(cliff_richness, 20) * (distance > 80) * (nullius_fulgora_ridge < -0.015)",
}})
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
    [basin.name] = {},
  }},
  decorative = {treat_missing_as_default = false, settings = {
    ["medium-fulgora-rock"] = {}, ["small-fulgora-rock"] = {},
    ["tiny-fulgora-rock"] = {},
  }},
  entity = {treat_missing_as_default = false, settings = {
    ["big-fulgora-rock"] = {}, ["fulgurite"] = {},
  }},
}
-- Map overrides reference named noise expressions, not inline formulas.
local function probability(kind, name, expression)
  local noise_name = "nullius-fulgora-" .. name .. "-probability"
  data:extend({{type="noise-expression", name=noise_name, expression=expression, hidden=true}})
  map.property_expression_names[kind .. ":" .. name .. ":probability"] = noise_name
end
map.property_expression_names.elevation = "nullius_fulgora_elevation"
map.property_expression_names.cliffiness = "nullius_fulgora_cliffiness"
probability("tile", basin.name, "1000 * (nullius_fulgora_land < 0) - 100")
-- Keep the four native ground types on firm plateaus and ridges.
probability("tile", "fulgoran-dust", "1.2 + fulgora_rock")
probability("tile", "fulgoran-rock", "0.5 + 2 * fulgora_rock")
-- Natural clusters extend into the dry basins, without oil or city masks.
for name, density in pairs({
  ["medium-fulgora-rock"] = 0.12,
  ["small-fulgora-rock"] = 0.24,
  ["tiny-fulgora-rock"] = 0.4,
}) do
  probability("decorative", name, density .. " * clamp(fulgora_rock - 0.4, 0, 1)")
end
probability("entity", "big-fulgora-rock", "0.025 * clamp(fulgora_rock - 0.8, 0, 1) * (distance > 72)")
probability("entity", "fulgurite", "0.008 * clamp(1 - fulgora_rock, 0, 1) * (distance > 72)")
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

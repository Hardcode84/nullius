require("prototypes.override_final")
require("prototypes.override_final_only")
require("prototypes.override_mod_final")
require("prototypes.item.module_limitation")
require("prototypes.item.box_icons")
require("prototypes.custom_tooltip_fields")
require("legacyMirror")

for _, recipe in pairs(data.raw.recipe) do
    if recipe.GCKI_ignore ~= nil then
        recipe.GCKI_ignore = nil
    end
end

require("clutterpedia")

-- Alien Biomes 0.7.4 still writes fields removed from Factorio 2.0. They are
-- ignored by the engine; clear them so strict prototype validation is useful.
if mods["alien-biomes"] then
  local styles = data.raw["gui-style"]["default"]
  local scroll = styles["alien-biomes-scroll-pane"]
  if scroll then scroll.vertical_scroll_bar_spacing = nil end
  local textbox = styles["alien-biomes-textbox"]
  if textbox then
    textbox.maximal_width = nil
    textbox.single_line = nil
  end
  local label = styles["alien-biomes-label-multiline"]
  if label then label.maximal_width = nil end

  for _, color in pairs({
      "tan", "red", "purple", "black", "white", "volcanic"}) do
    local decorative = data.raw["optimized-decorative"][
      "sand-decal-" .. color]
    if decorative then
      for _, picture in pairs(decorative.pictures or {}) do
        picture.slice_y = nil
      end
    end
  end
end

if settings.startup["nullius-hide-recipe-signals"].value then
    for _,recipe in pairs(data.raw.recipe) do
        --recipe.hide_from_signal_gui = true
        if recipe.hide_from_signal_gui == false then
            recipe.hide_from_signal_gui = nil
        end
    end
else
    for _,recipe in pairs(data.raw.recipe) do
        if string.sub(recipe.name, 1, 14) == "nullius-boxed-" or string.sub(recipe.name, 1, 14) == "nullius-unbox-" then
            recipe.hide_from_signal_gui = false
        end
    end
end

data.raw["utility-constants"]["default"].main_menu_simulations = require("menu-simulations.menu-simulations")

-- Restrict Nauvis air separation and oxygen separation recipes to non-Vulcanus.
-- Vulcanus has its own atmosphere separation recipe with different ratios.
local nauvis_air_recipes = {
  "nullius-air-separation-1", "nullius-air-separation-2", "nullius-air-separation-3",
  "nullius-pressure-air-separation",
  "nullius-oxygen-separation", "nullius-pressure-oxygen-separation",
}
for _, rname in pairs(nauvis_air_recipes) do
  local recipe = data.raw.recipe[rname]
  if recipe then
    if not recipe.surface_conditions then
      recipe.surface_conditions = {}
    end
    table.insert(recipe.surface_conditions, {property = "nullius-ambient-temperature", max = 50})
  end
end

-- Block solar panels, wind turbines, accumulators, and water wells on Vulcanus.
-- Solar: semiconductor junction failure at 200C ambient.
-- Wind: corrosive atmosphere destroys exposed mechanical parts.
-- Accumulators: thermal runaway at ambient temperature.
-- Wells: no groundwater aquifer exists on Vulcanus.
local cool_surface_only = {
  {property = "nullius-ambient-temperature", max = 50},
}
local vulcanus_blocked_entities = {
  ["solar-panel"] = {},
  ["accumulator"] = {},
  ["electric-energy-interface"] = {},
  ["assembling-machine"] = {},
}
for i = 1, 4 do
  table.insert(vulcanus_blocked_entities["solar-panel"],
    "nullius-solar-panel-" .. i)
end
for i = 1, 3 do
  table.insert(vulcanus_blocked_entities["accumulator"],
    "nullius-grid-battery-" .. i)
  table.insert(vulcanus_blocked_entities["electric-energy-interface"],
    "nullius-wind-build-" .. i)
  table.insert(vulcanus_blocked_entities["electric-energy-interface"],
    "nullius-wind-base-" .. i)
end
for i = 1, 2 do
  table.insert(vulcanus_blocked_entities["assembling-machine"],
    "nullius-well-" .. i)
  table.insert(vulcanus_blocked_entities["assembling-machine"],
    "nullius-legacy-well-" .. i)
end
for prototype_type, names in pairs(vulcanus_blocked_entities) do
  for _, name in pairs(names) do
    local prototype = data.raw[prototype_type][name]
    if not prototype then
      error("Missing " .. prototype_type .. " prototype " .. name)
    end
    prototype.surface_conditions = table.deepcopy(cool_surface_only)
  end
end

-- Reassign SA's Vulcanus music to our planet.
for _, sound in pairs(data.raw["ambient-sound"]) do
  if sound.planet == "vulcanus" then
    sound.planet = "nullius-vulcanus"
  end
end

-- Gut SA's vanilla planet definitions. Cannot delete (refs break), so
-- strip their map gen to prevent decorative errors and hide them.
local disabled_planet_map_gen = {
  property_expression_names = {},
  autoplace_controls = {},
  autoplace_settings = {
    entity = {treat_missing_as_default = false, settings = {}},
    tile = {
      treat_missing_as_default = false,
      settings = {["empty-space"] = {}},
    },
    decorative = {treat_missing_as_default = false, settings = {}},
  },
}
for _, planet_name in pairs({"vulcanus", "fulgora", "gleba", "aquilo"}) do
  if data.raw.planet[planet_name] then
    data.raw.planet[planet_name].hidden = true
    data.raw.planet[planet_name].map_gen_settings =
      table.deepcopy(disabled_planet_map_gen)
  end
end

-- Strip autoplace from ALL SA tiles, decoratives, and entities that are NOT
-- in our explicit whitelist. This prevents non-Vulcanus content from bleeding
-- into our planet terrain generation.
--
-- Whitelist approach: we know exactly which tiles we want on Nauvis (alien-biomes
-- handles that) and nullius-vulcanus. Everything else from SA gets stripped.

-- Tiles used by nullius-vulcanus (from prototypes/planet/vulcanus.lua).
local keep_tiles = {
  ["volcanic-soil-dark"] = true, ["volcanic-soil-light"] = true,
  ["volcanic-ash-soil"] = true, ["volcanic-ash-flats"] = true,
  ["volcanic-ash-light"] = true, ["volcanic-ash-dark"] = true,
  ["volcanic-cracks"] = true, ["volcanic-cracks-warm"] = true,
  ["volcanic-folds"] = true, ["volcanic-folds-flat"] = true,
  ["lava"] = true, ["lava-hot"] = true,
  ["volcanic-folds-warm"] = true, ["volcanic-pumice-stones"] = true,
  ["volcanic-cracks-hot"] = true, ["volcanic-jagged-ground"] = true,
  ["volcanic-smooth-stone"] = true, ["volcanic-smooth-stone-warm"] = true,
  ["volcanic-ash-cracks"] = true,
  -- Infrastructure tiles to keep.
  ["space"] = true, ["empty-space"] = true,
  ["space-platform-foundation"] = true, ["foundation"] = true,
}

-- Explicit list of non-Vulcanus SA planet tiles to strip autoplace from.
local strip_tiles = {
  -- Fulgora.
  "fulgoran-dust", "fulgoran-dunes", "fulgoran-sand", "fulgoran-rock",
  "fulgoran-paving", "fulgoran-walls", "fulgoran-conduit", "fulgoran-machinery",
  "oil-ocean-shallow", "oil-ocean-deep", "oil-deep",
  -- Gleba.
  "artificial-yumako-soil", "overgrowth-yumako-soil",
  "artificial-jellynut-soil", "overgrowth-jellynut-soil",
  "natural-yumako-soil", "natural-jellynut-soil",
  "lowland-olive-blubber", "lowland-olive-blubber-2", "lowland-olive-blubber-3",
  "lowland-brown-blubber", "lowland-pale-green",
  "lowland-cream-cauliflower", "lowland-cream-cauliflower-2",
  "lowland-dead-skin", "lowland-dead-skin-2",
  "lowland-cream-red", "lowland-red-vein", "lowland-red-vein-2",
  "lowland-red-vein-3", "lowland-red-vein-4", "lowland-red-vein-dead",
  "lowland-red-infection",
  "midland-cracked-lichen", "midland-cracked-lichen-dull", "midland-cracked-lichen-dark",
  "midland-turquoise-bark", "midland-turquoise-bark-2",
  "midland-yellow-crust", "midland-yellow-crust-2", "midland-yellow-crust-3", "midland-yellow-crust-4",
  "highland-dark-rock", "highland-dark-rock-2", "highland-yellow-rock",
  "pit-rock",
  "wetland-yumako", "wetland-jellynut", "wetland-dead-skin", "wetland-light-dead-skin",
  "wetland-green-slime", "wetland-light-green-slime", "wetland-red-tentacle",
  "wetland-pink-tentacle", "wetland-blue-slime", "gleba-deep-lake",
  "wetland-grey", "wetland-green", "wetland-pink", "wetland-purple",
  "wetland-green-puddle", "wetland-pink-puddle", "wetland-grey-puddle",
  -- Aquilo.
  "ammoniacal-ocean", "ammoniacal-ocean-2",
  "snow-flat", "dust-flat", "snow-crests", "dust-crests",
  "snow-lumpy", "dust-lumpy", "snow-patchy", "dust-patchy",
  "ice-rough", "ice-smooth", "ice-platform", "brash-ice", "brash-ice-2",
}

for _, tname in pairs(strip_tiles) do
  if data.raw.tile[tname] and data.raw.tile[tname].autoplace then
    data.raw.tile[tname].autoplace = nil
  end
end

-- Strip autoplace from ALL non-Vulcanus SA decoratives and entities.
-- Vulcanus decoratives start with "vulcanus-", "calcite-", "sulfur-",
-- "crater-", "pumice-", "small-volcanic", "medium-volcanic", "tiny-volcanic",
-- "tiny-rock", "waves-".
local keep_deco_prefixes = {
  "vulcanus", "calcite", "sulfur", "crater", "pumice",
  "small-volcanic", "medium-volcanic", "tiny-volcanic",
  "tiny-rock", "waves-decal",
}

local sa_deco_prefixes = {
  "fulgoran", "lithium", "floating-iceberg", "aqulio", "snow-drift",
  "yellow-lettuce", "green-lettuce", "pale-lettuce",
  "honeycomb", "split-gill", "veins", "mycelium", "coral",
  "black-sceptre", "pink-phalanges", "pink-lichen", "red-lichen",
  "green-cup", "brown-cup", "blood-grape", "brambles", "polycephalum",
  "fuchsia-pita", "wispy-lichen", "barnacles", "solo-barnacle",
  "curly-roots", "knobbly-roots", "matches-small", "white-carpet",
  "green-carpet", "green-hairy", "nerve-roots", "yellow-coral",
  "grey-cracked", "red-desert-bush", "white-desert-bush",
}

for name, deco in pairs(data.raw["optimized-decorative"] or {}) do
  if deco.autoplace then
    for _, prefix in pairs(sa_deco_prefixes) do
      if string.sub(name, 1, #prefix) == prefix then
        deco.autoplace = nil
        break
      end
    end
  end
end

-- Strip autoplace from non-Vulcanus SA entities.
local strip_entity_names = {
  "scrap", "fulgurite", "big-fulgora-rock",
  "fulgoran-ruin-vault", "fulgoran-ruin-attractor",
  "fulgoran-ruin-colossal", "fulgoran-ruin-huge", "fulgoran-ruin-big",
  "fulgoran-ruin-stonehenge", "fulgoran-ruin-medium", "fulgoran-ruin-small",
  "iron-stromatolite", "copper-stromatolite",
  "lithium-brine", "fluorine-vent",
  "lithium-iceberg-huge", "lithium-iceberg-big",
  "tungsten-ore", "coal",
  "ashland-lichen-tree", "ashland-lichen-tree-flaming",
}
for _, ename in pairs(strip_entity_names) do
  for _, type_table in pairs(data.raw) do
    if type_table[ename] and type_table[ename].autoplace then
      type_table[ename].autoplace = nil
    end
  end
end

-- Override Vulcanus rock drops: stone, graphite, rutile (no vanilla ores).
if data.raw["simple-entity"]["huge-volcanic-rock"] then
  data.raw["simple-entity"]["huge-volcanic-rock"].minable.results = {
    {type = "item", name = "stone", amount_min = 10, amount_max = 25},
    {type = "item", name = "nullius-graphite", amount_min = 3, amount_max = 8},
    {type = "item", name = "nullius-rutile", amount_min = 1, amount_max = 3},
  }
end
if data.raw["simple-entity"]["big-volcanic-rock"] then
  data.raw["simple-entity"]["big-volcanic-rock"].minable.results = {
    {type = "item", name = "stone", amount_min = 5, amount_max = 15},
    {type = "item", name = "nullius-graphite", amount_min = 2, amount_max = 5},
    {type = "item", name = "nullius-rutile", amount_min = 0, amount_max = 2, probability = 0.5},
  }
end

-- Override sulfuric acid geyser to produce HCl on Vulcanus.
-- The geyser entity is shared across surfaces, so we change it globally.
-- On Nauvis there are no sulfuric acid geysers, so this only affects Vulcanus.
if data.raw.resource["sulfuric-acid-geyser"] then
  data.raw.resource["sulfuric-acid-geyser"].minable.results = {
    {type = "fluid", name = "nullius-hydrogen-chloride", amount_min = 10, amount_max = 10, probability = 1},
  }
  data.raw.resource["sulfuric-acid-geyser"].localised_name = {"entity-name.nullius-hcl-geyser"}
end

-- Neuter quality and recycling. SA forces quality mod to load, but
-- Nullius* does not use quality. Disable at prototype level.

-- Hide and disable all recycling recipes (don't delete -- SA refs break).
for name, recipe in pairs(data.raw.recipe) do
  if string.find(name, "%-recycling$") then
    recipe.hidden = true
    recipe.enabled = false
  end
end

-- Disable quality on all recipes.
for _, recipe in pairs(data.raw.recipe) do
  recipe.allow_quality = false
end

-- Flatten all quality tiers.
for _, quality in pairs(data.raw.quality) do
  quality.next_probability = 0
  quality.default_multiplier = 1
  quality.crafting_machine_speed_multiplier = 1
  quality.crafting_machine_energy_usage_multiplier = 1
  quality.inserter_speed_multiplier = 1
  quality.inventory_size_multiplier = 1
  quality.lab_research_speed_multiplier = 1
  quality.mining_drill_resource_drain_multiplier = 1
  quality.science_pack_drain_multiplier = 1
  quality.tool_durability_multiplier = 1
  quality.range_multiplier = 1
  quality.beacon_power_usage_multiplier = 1
  quality.fluid_wagon_capacity_multiplier = 1
  quality.flying_robot_max_energy_multiplier = 1
  quality.accumulator_capacity_multiplier = 1
end

-- Hide quality modules.
for _, module in pairs(data.raw.module) do
  if module.effect and module.effect.quality then
    module.hidden = true
  end
end

local variant_upgrades = require("shared.variant-upgrades")
variant_upgrades.apply("-pneumatic")
variant_upgrades.apply("-thermal")

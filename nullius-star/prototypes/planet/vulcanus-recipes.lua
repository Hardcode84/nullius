-- Vulcanus lava processing recipes and molten bloom items.

local cool_environment_only = {
  {property = "nullius-ambient-temperature", max = 50},
}

local vulcanus_only = {
  {property = "nullius-ambient-temperature", min = 100},
}

local recipe_util = require("prototypes.recipe-util")

local function vulcanus_substitute_recipe(source_name, name, substitutions,
    overrides)
  overrides = table.deepcopy(overrides or {})
  overrides.surface_conditions = table.deepcopy(vulcanus_only)
  return recipe_util.substitute_recipe(
    source_name, name, substitutions, overrides)
end

local function vulcanus_plastic_recipe(source_name, name, replacement,
    overrides)
  return vulcanus_substitute_recipe(source_name, name, {
    ["nullius-plastic"] = replacement,
  }, overrides)
end

local function vulcanus_rubber_recipe(source_name, name, replacement,
    overrides)
  return vulcanus_substitute_recipe(source_name, name, {
    ["nullius-rubber"] = replacement,
  }, overrides)
end

for _, name in ipairs{
    "nullius-bpa",
    "nullius-pressure-bpa",
    "nullius-boxed-bpa",
    "nullius-boxed-pressure-bpa",
    "nullius-epoxy",
    "nullius-boxed-epoxy",
} do
  local recipe = data.raw.recipe[name]
  if not recipe then error("Missing cool-environment organic recipe: " .. name) end
  recipe.surface_conditions = table.deepcopy(cool_environment_only)
end

for _, name in ipairs{
    "nullius-arthropod-disposal",
    "nullius-arthropod-egg-disposal",
    "nullius-arthropod-egg-harvest",
    "nullius-arthropod-harvest",
    "nullius-barrel-recycling",
    "nullius-legacy-arthropod-egg-harvest",
    "nullius-legacy-barrel-recycling",
    "nullius-legacy-plastic-pex",
    "nullius-plastic",
    "nullius-plastic-pc-abs",
    "nullius-plastic-pex",
    "nullius-polypropylene",
    "nullius-latex",
    "nullius-rubber",
    "nullius-rubber-nbr",
    "nullius-boxed-arthropod-disposal",
    "nullius-boxed-arthropod-harvest",
    "nullius-boxed-plastic",
    "nullius-boxed-plastic-pex",
    "nullius-legacy-boxed-plastic-pex",
    "nullius-boxed-latex",
    "nullius-boxed-rubber",
} do
  local recipe = data.raw.recipe[name]
  if not recipe then error("Missing polymer production recipe: " .. name) end
  recipe.surface_conditions = table.deepcopy(cool_environment_only)
end

-- Molten bloom items: spoil into ingots after cooling.
data:extend({
  {
    type = "item",
    name = "nullius-molten-iron-bloom",
    localised_name = {"item-name.nullius-molten-iron-bloom"},
    icons = {{
      icon = "__space-age__/graphics/icons/fluid/molten-iron.png",
      icon_size = 64,
    }},
    subgroup = "iron-ingot",
    order = "nullius-a",
    stack_size = 50,
    spoil_ticks = 1800,
    spoil_result = "nullius-iron-ingot",
  },
  {
    type = "item",
    name = "nullius-molten-aluminum-bloom",
    localised_name = {"item-name.nullius-molten-aluminum-bloom"},
    icons = {{
      icon = "__space-age__/graphics/icons/fluid/molten-copper.png",
      icon_size = 64,
    }},
    subgroup = "aluminum-ingot",
    order = "nullius-a",
    stack_size = 50,
    spoil_ticks = 2400,
    spoil_result = "nullius-alumina",
  },
  {
    type = "item",
    name = "nullius-aluminum-chloride",
    localised_name = {"item-name.nullius-aluminum-chloride"},
    icons = {{
      icon = "__angelsrefininggraphics__/graphics/icons/angels-ore6/angels-ore6-3.png",
      icon_size = 64,
      tint = {220, 220, 180},
    }},
    subgroup = "aluminum-ingot",
    order = "nullius-vc",
    stack_size = 100,
  },
  {
    type = "item",
    name = "nullius-iron-chloride",
    localised_name = {"item-name.nullius-iron-chloride"},
    icons = {{
      icon = "__angelsrefininggraphics__/graphics/icons/angels-ore6/angels-ore6-3.png",
      icon_size = 64,
      tint = {150, 95, 45},
    }},
    subgroup = "iron-ingot",
    order = "nullius-vc",
    stack_size = 100,
  },
  {
    type = "item",
    name = "nullius-refractory-mix",
    localised_name = {"item-name.nullius-refractory-mix"},
    icons = {{
      icon = "__angelssmeltinggraphics__/graphics/icons/powder-silica.png",
      icon_size = 64,
      tint = {r = 0.8, g = 0.65, b = 0.5},
    }},
    subgroup = "masonry",
    order = "nullius-bz",
    stack_size = 100,
  },
  {
    type = "tool",
    name = "nullius-metallurgic-pack",
    icon = "__space-age__/graphics/icons/metallurgic-science-pack.png",
    icon_size = 64,
    subgroup = "research-pack",
    order = "nullius-v",
    stack_size = 200,
    durability = 1,
    durability_description_key = "description.science-pack-remaining-amount-key",
    durability_description_value = "description.science-pack-remaining-amount-value",
  },
})

data:extend({
  {
    type = "recipe",
    name = "nullius-high-temperature-resin",
    localised_name = {"recipe-name.nullius-high-temperature-resin"},
    enabled = false,
    category = "basic-chemistry",
    subgroup = "organic-chemistry",
    order = "nullius-jv",
    always_show_made_in = true,
    energy_required = 10,
    crafting_machine_tint = {
      primary = data.raw.fluid["nullius-acrylonitrile"].flow_color,
      secondary = data.raw.fluid["nullius-benzene"].flow_color,
    },
    ingredients = {
      {type = "item", name = "nullius-acrylonitrile-barrel", amount = 2},
      {type = "item", name = "nullius-ammonia-barrel", amount = 1},
      {type = "item", name = "nullius-alumina", amount = 1},
      {
        type = "fluid",
        name = "nullius-benzene",
        amount = 30,
        fluidbox_index = 1,
      },
      {
        type = "fluid",
        name = "nullius-oxygen",
        amount = 100,
        fluidbox_index = 2,
      },
      {
        type = "fluid",
        name = "nullius-solvent",
        amount = 10,
        fluidbox_index = 3,
      },
    },
    results = {
      {
        type = "fluid",
        name = "nullius-epoxy",
        amount = 40,
        temperature = 200,
      },
      {type = "fluid", name = "nullius-wastewater", amount = 50},
      {
        type = "item",
        name = "barrel",
        amount = 3,
        ignored_by_productivity = 3,
      },
      {
        type = "item",
        name = "nullius-alumina",
        amount = 1,
        ignored_by_productivity = 1,
      },
    },
    main_product = "nullius-epoxy",
    allow_productivity = true,
    surface_conditions = {
      {property = "nullius-ambient-temperature", min = 200},
    },
  },
})

-- Shape reactive blooms before they cool.  Iron retains the ordinary ingot
-- casting ratios; aluminum avoids oxidation and the subsequent graphite
-- reduction step.
data:extend({
  {
    type = "recipe",
    name = "nullius-hot-iron-plate",
    localised_name = {"recipe-name.nullius-hot-iron-plate"},
    enabled = false,
    category = "machine-casting",
    subgroup = "iron-product",
    order = "nullius-va",
    energy_required = 3,
    ingredients = {
      {type = "item", name = "nullius-molten-iron-bloom", amount = 4},
    },
    results = {
      {type = "item", name = "nullius-iron-plate", amount = 3},
    },
    main_product = "nullius-iron-plate",
    allow_productivity = true,
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },
  {
    type = "recipe",
    name = "nullius-hot-iron-rod",
    localised_name = {"recipe-name.nullius-hot-iron-rod"},
    enabled = false,
    category = "machine-casting",
    subgroup = "iron-product",
    order = "nullius-vb",
    energy_required = 4,
    ingredients = {
      {type = "item", name = "nullius-molten-iron-bloom", amount = 4},
    },
    results = {
      {type = "item", name = "nullius-iron-rod", amount = 5},
    },
    main_product = "nullius-iron-rod",
    allow_productivity = true,
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },
  {
    type = "recipe",
    name = "nullius-hot-aluminum-sheet",
    localised_name = {"recipe-name.nullius-hot-aluminum-sheet"},
    enabled = false,
    category = "machine-casting",
    subgroup = "aluminum-product",
    order = "nullius-va",
    energy_required = 4,
    ingredients = {
      {type = "item", name = "nullius-molten-aluminum-bloom", amount = 4},
    },
    results = {
      {type = "item", name = "nullius-aluminum-sheet", amount = 5},
    },
    main_product = "nullius-aluminum-sheet",
    allow_productivity = true,
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },
  {
    type = "recipe",
    name = "nullius-hot-aluminum-rod",
    localised_name = {"recipe-name.nullius-hot-aluminum-rod"},
    enabled = false,
    category = "machine-casting",
    subgroup = "aluminum-product",
    order = "nullius-vb",
    energy_required = 4,
    ingredients = {
      {type = "item", name = "nullius-molten-aluminum-bloom", amount = 4},
    },
    results = {
      {type = "item", name = "nullius-aluminum-rod", amount = 5},
    },
    main_product = "nullius-aluminum-rod",
    allow_productivity = true,
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },
})

-- Industrial refractory production consumes abundant Vulcanus mineral
-- byproducts and avoids the wet, organic ceramic route.
data:extend({
  {
    type = "recipe",
    name = "nullius-refractory-mix-vulcanus",
    localised_name = {"recipe-name.nullius-refractory-mix-vulcanus"},
    enabled = false,
    category = "medium-crafting",
    subgroup = "masonry",
    order = "nullius-vc",
    energy_required = 12,
    ingredients = {
      {type = "item", name = "nullius-alumina", amount = 5},
      {type = "item", name = "nullius-silica", amount = 8},
      {type = "item", name = "nullius-mineral-dust", amount = 12},
    },
    results = {
      {type = "item", name = "nullius-refractory-mix", amount = 10},
    },
    allow_productivity = true,
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },
  {
    type = "recipe",
    name = "nullius-refractory-brick-vulcanus",
    localised_name = {"recipe-name.nullius-refractory-brick-vulcanus"},
    enabled = false,
    category = "dry-smelting",
    subgroup = "masonry",
    order = "nullius-vd",
    energy_required = 15,
    ingredients = {
      {type = "item", name = "nullius-refractory-mix", amount = 10},
    },
    results = {
      {type = "item", name = "nullius-refractory-brick", amount = 30},
    },
    main_product = "nullius-refractory-brick",
    allow_productivity = true,
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },
  {
    type = "recipe",
    name = "nullius-heat-pipe-2-vulcanus",
    localised_name = {"recipe-name.nullius-heat-pipe-2-vulcanus"},
    enabled = false,
    category = "machine-casting",
    subgroup = "heat-energy",
    order = "nullius-vc",
    energy_required = 6,
    ingredients = {
      {type = "item", name = "nullius-heat-pipe-1", amount = 1},
      {type = "item", name = "nullius-pipe-2", amount = 2},
      {type = "item", name = "nullius-aluminum-sheet", amount = 4},
      {type = "item", name = "nullius-refractory-brick", amount = 4},
      {type = "item", name = "nullius-silicon-insulation", amount = 2},
      {type = "item", name = "nullius-eutectic-salt", amount = 5},
    },
    results = {
      {type = "item", name = "nullius-heat-pipe-2", amount = 2},
    },
    main_product = "nullius-heat-pipe-2",
    allow_productivity = true,
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },
  {
    type = "recipe",
    name = "nullius-vulcanus-radiator-2-refractory",
    localised_name = {"recipe-name.nullius-vulcanus-radiator-2-refractory"},
    enabled = false,
    category = "medium-crafting",
    subgroup = "energy",
    order = "nullius-vc",
    energy_required = 10,
    ingredients = {
      {type = "item", name = "nullius-vulcanus-radiator-1", amount = 1},
      {type = "item", name = "nullius-aluminum-sheet", amount = 4},
      {type = "item", name = "nullius-refractory-brick", amount = 4},
      {type = "item", name = "nullius-heat-pipe-1", amount = 1},
      {type = "item", name = "nullius-pipe-2", amount = 4},
    },
    results = {
      {type = "item", name = "nullius-vulcanus-radiator-2", amount = 1},
    },
    main_product = "nullius-vulcanus-radiator-2",
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },
})

-- Pilot titanium metallurgy substitutes local aluminum for sodium and argon.
-- Aluminum chloride is recoverable only as a small alumina fraction, keeping
-- the route useful for construction without closing an aluminum loop.
data:extend({
  {
    type = "recipe",
    name = "nullius-titanium-ingot-vulcanus",
    localised_name = {"recipe-name.nullius-titanium-ingot-vulcanus"},
    enabled = false,
    category = "nullius-high-temp-radiator",
    subgroup = "titanium-product",
    order = "nullius-vc",
    energy_required = 8,
    ingredients = {
      {type = "fluid", name = "nullius-titanium-tetrachloride", amount = 15},
      {type = "item", name = "nullius-aluminum-ingot", amount = 4},
    },
    results = {
      {type = "item", name = "nullius-titanium-ingot", amount = 2},
      {
        type = "item",
        name = "nullius-aluminum-chloride",
        amount = 4,
        ignored_by_productivity = 4,
      },
    },
    main_product = "nullius-titanium-ingot",
    allow_productivity = true,
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },
  {
    type = "recipe",
    name = "nullius-aluminum-chloride-recovery",
    localised_name = {"recipe-name.nullius-aluminum-chloride-recovery"},
    enabled = false,
    category = "nullius-high-temp-radiator",
    subgroup = "aluminum-ingot",
    order = "nullius-vd",
    energy_required = 6,
    ingredients = {
      {type = "item", name = "nullius-aluminum-chloride", amount = 4},
      {type = "fluid", name = "nullius-water", amount = 30},
    },
    results = {
      {type = "item", name = "nullius-alumina", amount = 1},
      {type = "item", name = "nullius-mineral-dust", amount = 3},
      {type = "fluid", name = "nullius-hydrogen-chloride", amount = 60},
    },
    main_product = "nullius-alumina",
    allow_productivity = false,
    no_productivity = true,
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },
  {
    type = "recipe",
    name = "nullius-hydro-plant-2-vulcanus",
    localised_name = {"recipe-name.nullius-hydro-plant-2-vulcanus"},
    enabled = false,
    category = "medium-crafting",
    subgroup = "water-treatment",
    order = "nullius-vc",
    energy_required = 16,
    ingredients = {
      {type = "item", name = "nullius-hydro-plant-1", amount = 1},
      {type = "item", name = "nullius-chemical-plant-1", amount = 1},
      {type = "item", name = "nullius-medium-tank-2", amount = 1},
      {type = "item", name = "nullius-refractory-brick", amount = 20},
      {type = "item", name = "nullius-titanium-plate", amount = 2},
      {type = "item", name = "nullius-red-wire", amount = 5},
    },
    results = {
      {type = "item", name = "nullius-hydro-plant-2", amount = 1},
    },
    main_product = "nullius-hydro-plant-2",
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },
  {
    type = "recipe",
    name = "nullius-foundry-2-vulcanus",
    localised_name = {"recipe-name.nullius-foundry-2-vulcanus"},
    enabled = false,
    category = "medium-crafting",
    subgroup = "ore-processing",
    order = "nullius-vd",
    energy_required = 15,
    ingredients = {
      {type = "item", name = "nullius-foundry-1", amount = 1},
      {type = "item", name = "nullius-small-furnace-2", amount = 1},
      {type = "item", name = "nullius-refractory-brick", amount = 12},
      {type = "item", name = "nullius-titanium-plate", amount = 1},
      {type = "item", name = "bob-turbo-inserter", amount = 2},
    },
    results = {
      {type = "item", name = "nullius-foundry-2", amount = 1},
    },
    main_product = "nullius-foundry-2",
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },
})

-- Lava processing recipes. Category: nullius-water-treatment (hydro-plant).
-- All produce compressed volcanic gas as byproduct.
data:extend({
  {
    type = "recipe",
    name = "nullius-lava-iron-separation",
    localised_name = {"recipe-name.nullius-lava-iron-separation"},
    icons = {{
      icon = "__space-age__/graphics/icons/fluid/molten-iron.png",
      icon_size = 64,
    }},
    enabled = true,
    category = "nullius-water-treatment",
    subgroup = "iron-ingot",
    order = "nullius-vb",
    energy_required = 5,
    ingredients = {
      {type = "fluid", name = "lava", amount = 100},
    },
    results = {
      {type = "item", name = "nullius-molten-iron-bloom", amount = 4},
      {type = "fluid", name = "nullius-compressed-volcanic-gas", amount = 30},
      {type = "item", name = "stone", amount = 10},
    },
    main_product = "nullius-molten-iron-bloom",
    allow_productivity = true,
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },
  {
    type = "recipe",
    name = "nullius-lava-aluminum-separation",
    localised_name = {"recipe-name.nullius-lava-aluminum-separation"},
    icons = {{
      icon = "__space-age__/graphics/icons/fluid/molten-copper.png",
      icon_size = 64,
    }},
    enabled = true,
    category = "nullius-water-treatment",
    subgroup = "aluminum-ingot",
    order = "nullius-vb",
    energy_required = 5,
    ingredients = {
      {type = "fluid", name = "lava", amount = 100},
    },
    results = {
      {type = "item", name = "nullius-molten-aluminum-bloom", amount = 3},
      {type = "fluid", name = "nullius-compressed-volcanic-gas", amount = 25},
      {type = "item", name = "stone", amount = 8},
    },
    main_product = "nullius-molten-aluminum-bloom",
    allow_productivity = true,
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },
  {
    type = "recipe",
    name = "nullius-lava-calcite-separation",
    localised_name = {"recipe-name.nullius-lava-calcite-separation"},
    icons = {{
      icon = "__space-age__/graphics/icons/calcite.png",
      icon_size = 64,
    }},
    enabled = true,
    category = "nullius-water-treatment",
    subgroup = "calcium-product",
    order = "nullius-vb",
    energy_required = 4,
    ingredients = {
      {type = "fluid", name = "lava", amount = 80},
    },
    results = {
      {type = "item", name = "nullius-crushed-limestone", amount = 6},
      {type = "fluid", name = "nullius-compressed-volcanic-gas", amount = 20},
    },
    main_product = "nullius-crushed-limestone",
    allow_productivity = true,
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },
  {
    type = "recipe",
    name = "nullius-lava-silica-extraction",
    localised_name = {"recipe-name.nullius-lava-silica-extraction"},
    icons = {{
      icon = "__angelsrefininggraphics__/graphics/icons/angels-ore6/angels-ore6-2.png",
      icon_size = 64,
      tint = {220, 200, 160},
    }},
    enabled = true,
    category = "nullius-water-treatment",
    subgroup = "silicon-product",
    order = "nullius-vb",
    energy_required = 3,
    ingredients = {
      {type = "fluid", name = "lava", amount = 60},
    },
    results = {
      {type = "item", name = "nullius-silica", amount = 8},
      {type = "item", name = "stone", amount = 5},
      {type = "fluid", name = "nullius-compressed-volcanic-gas", amount = 15},
      {type = "fluid", name = "nullius-sulfur-dioxide", amount = 10},
    },
    main_product = "nullius-silica",
    allow_productivity = true,
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },
})

-- Restore ordinary volcanic gas pressure for the existing separation chain.
data:extend({
  {
    type = "recipe",
    name = "nullius-decompress-volcanic-gas",
    localised_name = {"recipe-name.nullius-decompress-volcanic-gas"},
    icons = data.raw.fluid["nullius-volcanic-gas"].icons,
    enabled = false,
    show_amount_in_title = false,
    always_show_products = true,
    allow_decomposition = false,
    allow_as_intermediate = false,
    hide_from_stats = true,
    category = "decompression",
    subgroup = "decompression",
    order = "nullius-z",
    energy_required = 1,
    ingredients = {
      {type = "fluid", name = "nullius-compressed-volcanic-gas", amount = 25},
    },
    results = {
      {type = "fluid", name = "nullius-volcanic-gas", amount = 100},
    },
    main_product = "nullius-volcanic-gas",
    allow_productivity = false,
    no_productivity = true,
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },
})

-- Obsolete but electricity-free sodium production by carbothermic reduction
-- and immediate condensation of sodium vapor.  Its poor yield and refractory
-- wear keep electrolysis preferable wherever power is available.
data:extend({
  {
    type = "recipe",
    name = "nullius-carbothermic-sodium",
    localised_name = {"recipe-name.nullius-carbothermic-sodium"},
    enabled = false,
    category = "nullius-high-temp-radiator",
    subgroup = "sodium-product",
    order = "nullius-vc",
    always_show_products = true,
    energy_required = 20,
    ingredients = {
      {type = "item", name = "nullius-soda-ash", amount = 3},
      {type = "item", name = "nullius-graphite", amount = 6},
      {type = "item", name = "nullius-refractory-brick", amount = 1},
    },
    results = {
      {type = "item", name = "nullius-sodium", amount = 2},
      {type = "fluid", name = "nullius-carbon-monoxide", amount = 90},
    },
    main_product = "nullius-sodium",
    allow_productivity = false,
    no_productivity = true,
  },
})

-- Inefficient alkali recovery from sodium-bearing volcanic silicates.  These
-- recipes are globally usable: their poor yields are the constraint, while
-- Vulcanus supplies renewable gravel, hydrogen chloride, and pneumatic power.
data:extend({
  {
    type = "recipe",
    name = "nullius-volcanic-saline",
    localised_name = {"recipe-name.nullius-volcanic-saline"},
    icon = data.raw.fluid["nullius-saline"].icon,
    icon_size = data.raw.fluid["nullius-saline"].icon_size,
    enabled = false,
    category = "basic-chemistry",
    subgroup = "nullius-water-treatment",
    order = "nullius-vs",
    show_amount_in_title = false,
    always_show_products = true,
    energy_required = 8,
    ingredients = {
      {type = "item", name = "nullius-gravel", amount = 10},
      {type = "fluid", name = "nullius-hydrogen-chloride", amount = 50},
      {type = "fluid", name = "nullius-water", amount = 100},
    },
    results = {
      {type = "fluid", name = "nullius-saline", amount = 70},
      {type = "item", name = "nullius-silica", amount = 4},
      {type = "item", name = "nullius-mineral-dust", amount = 5},
    },
    main_product = "nullius-saline",
    allow_productivity = false,
    no_productivity = true,
  },
  {
    type = "recipe",
    name = "nullius-volcanic-causticization",
    localised_name = {"recipe-name.nullius-volcanic-causticization"},
    icon = data.raw.item["nullius-sodium-hydroxide"].icon,
    icon_size = data.raw.item["nullius-sodium-hydroxide"].icon_size,
    enabled = false,
    category = "nullius-water-treatment",
    subgroup = "sodium-product",
    order = "nullius-vc",
    always_show_products = true,
    energy_required = 30,
    ingredients = {
      {type = "item", name = "nullius-soda-ash", amount = 1},
      {type = "item", name = "nullius-lime", amount = 1},
      {type = "fluid", name = "nullius-water", amount = 100},
    },
    results = {
      {type = "item", name = "nullius-sodium-hydroxide", amount = 2},
      {type = "item", name = "nullius-crushed-limestone", amount = 1},
    },
    main_product = "nullius-sodium-hydroxide",
    allow_productivity = false,
    no_productivity = true,
  },
})

-- Vulcanus-local crafting and science recipes.
data:extend({
  vulcanus_plastic_recipe("nullius-barrel-1", "nullius-vulcanus-barrel", {
    {type = "item", name = "nullius-aluminum-sheet", amount = 2},
    {type = "item", name = "nullius-glass", amount = 1},
  }, {
    localised_name = {"recipe-name.nullius-vulcanus-barrel"},
    enabled = false,
    category = "small-crafting",
    subgroup = "canisters",
    order = "nullius-ba",
    always_show_made_in = true,
    show_amount_in_title = false,
    always_show_products = true,
    energy_required = 10,
  }),
  {
    type = "recipe",
    name = "nullius-metallurgic-pack",
    localised_name = {"recipe-name.nullius-metallurgic-pack-bootstrap"},
    enabled = false,
    category = "small-crafting",
    subgroup = "research-pack-2",
    order = "nullius-va",
    energy_required = 60,
    ingredients = {
      {type = "item", name = "nullius-iron-ingot", amount = 12},
      {type = "item", name = "nullius-aluminum-ingot", amount = 8},
      {type = "item", name = "nullius-crushed-limestone", amount = 4},
      {type = "item", name = "nullius-silica", amount = 4},
      {type = "item", name = "sulfur", amount = 4},
    },
    results = {
      {type = "item", name = "nullius-metallurgic-pack", amount = 1},
    },
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },
  {
    type = "recipe",
    name = "nullius-metallurgic-pack-efficient",
    localised_name = {"recipe-name.nullius-metallurgic-pack-efficient"},
    icon = "__space-age__/graphics/icons/metallurgic-science-pack.png",
    icon_size = 64,
    enabled = false,
    category = "medium-crafting",
    subgroup = "research-pack-2",
    order = "nullius-vb",
    energy_required = 15,
    ingredients = {
      {type = "item", name = "nullius-molten-iron-bloom", amount = 2},
      {type = "item", name = "nullius-molten-aluminum-bloom", amount = 2},
      {type = "item", name = "nullius-crucible", amount = 1},
      {type = "item", name = "nullius-chlorine-barrel", amount = 1},
      {type = "item", name = "nullius-sulfur-dioxide-barrel", amount = 1},
    },
    results = {
      {type = "item", name = "nullius-metallurgic-pack", amount = 5},
      {
        type = "item",
        name = "barrel",
        amount = 1,
        ignored_by_productivity = 1,
      },
      {
        type = "item",
        name = "barrel",
        amount = 1,
        probability = 0.9,
        ignored_by_productivity = 1,
      },
    },
    main_product = "nullius-metallurgic-pack",
    allow_productivity = true,
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },
  {
    type = "recipe",
    name = "nullius-geology-pack-vulcanus",
    localised_name = {"recipe-name.nullius-geology-pack-vulcanus"},
    icons = {
      {
        icon = "__base__/graphics/icons/utility-science-pack.png",
        icon_size = 64,
      },
      {
        icon = "__angelsrefininggraphics__/graphics/icons/angels-ore6/angels-ore6-2.png",
        icon_size = 64,
        scale = 0.27,
        shift = {1, 7},
        tint = {r = 0.9, g = 0.65, b = 0.35, a = 0.85},
      },
    },
    show_amount_in_title = false,
    always_show_products = true,
    always_show_made_in = true,
    hide_from_signal_gui = false,
    enabled = true,
    category = "small-crafting",
    subgroup = "research-pack-2",
    order = "nullius-vb",
    energy_required = 40,
    ingredients = {
      {type = "item", name = "nullius-mineral-dust", amount = 2},
      {type = "item", name = "nullius-silica", amount = 2},
      {type = "item", name = "nullius-crushed-limestone", amount = 1},
      {type = "item", name = "sulfur", amount = 1},
    },
    results = {
      {type = "item", name = "nullius-geology-pack", amount = 1},
    },
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },
  {
    type = "recipe",
    name = "nullius-climatology-pack-vulcanus",
    localised_name = {"recipe-name.nullius-climatology-pack-vulcanus"},
    icons = {
      {
        icon = "__base__/graphics/icons/chemical-science-pack.png",
        icon_size = 64,
      },
      {
        icon = "__angelspetrochemgraphics__/graphics/icons/molecules/carbon-dioxide.png",
        icon_size = 72,
        scale = 0.27,
        shift = {1, 7},
      },
    },
    show_amount_in_title = false,
    always_show_products = true,
    always_show_made_in = true,
    hide_from_signal_gui = false,
    enabled = true,
    allow_decomposition = false,
    category = "basic-chemistry",
    subgroup = "research-pack-2",
    order = "nullius-vc",
    crafting_machine_tint = {
      primary = data.raw.fluid["nullius-carbon-dioxide"].flow_color,
      secondary = data.raw.fluid["nullius-sulfur-dioxide"].flow_color,
    },
    energy_required = 50,
    ingredients = {
      {type = "fluid", name = "nullius-carbon-dioxide", amount = 400},
      {type = "fluid", name = "nullius-nitrogen", amount = 30},
      {type = "fluid", name = "nullius-sulfur-dioxide", amount = 10},
    },
    results = {
      {type = "item", name = "nullius-climatology-pack", amount = 1},
    },
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },
})

-- Vulcanus logistics alt recipes: replace unavailable materials.
data:extend({
  vulcanus_plastic_recipe("nullius-splitter-1", "nullius-splitter-1-vulcanus", {
    {type = "item", name = "nullius-silicon-insulation", amount = 2},
  }, {
    localised_name = {"recipe-name.nullius-splitter-vulcanus"},
    enabled = true,
    category = "small-crafting",
    subgroup = "splitter",
    order = "nullius-vc",
    always_show_made_in = true,
    energy_required = 4,
  }),
  vulcanus_substitute_recipe("nullius-underground-pipe-1",
    "nullius-underground-pipe-1-vulcanus", {
      ["nullius-sand"] = {
        {type = "item", name = "nullius-silica", amount = 3},
      },
    }, {
      localised_name = {"recipe-name.nullius-underground-pipe-vulcanus"},
      enabled = true,
      category = "small-crafting",
      subgroup = "pipes",
      order = "nullius-vc",
      always_show_made_in = true,
      always_show_products = true,
      show_amount_in_title = false,
    }),
  -- Dedicated gas extraction recipe: high gas yield, stone byproduct.
  {
    type = "recipe",
    name = "nullius-lava-gas-extraction",
    localised_name = {"recipe-name.nullius-lava-gas-extraction"},
    icons = {{
      icon = "__space-age__/graphics/icons/fluid/lava.png",
      icon_size = 64,
      tint = {1, 0.8, 0.5},
    }},
    enabled = true,
    category = "nullius-water-treatment",
    subgroup = "compressed-air",
    order = "nullius-vb",
    energy_required = 2,
    ingredients = {
      {type = "fluid", name = "lava", amount = 50},
    },
    results = {
      {type = "fluid", name = "nullius-compressed-volcanic-gas", amount = 60},
      {type = "item", name = "stone", amount = 3},
    },
    main_product = "nullius-compressed-volcanic-gas",
    allow_productivity = true,
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },
})

-- Vulcanus atmosphere separation: CO2-dominated with trace N2 and SO2.
-- Uses same input (nullius-air from air filter) but different output ratios.
-- Replaces Nauvis air-separation recipes on Vulcanus.
data:extend({
  {
    type = "recipe",
    name = "nullius-vulcanus-atmosphere-separation",
    localised_name = {"recipe-name.nullius-vulcanus-atmosphere-separation"},
    icon = "__angelspetrochemgraphics__/graphics/icons/molecules/carbon-dioxide.png",
    icon_size = 72,
    enabled = true,
    allow_decomposition = false,
    category = "distillation",
    subgroup = "air-filtration-recipe",
    order = "nullius-va",
    energy_required = 1,
    ingredients = {
      {type = "fluid", name = "nullius-air", amount = 150},
    },
    results = {
      {type = "fluid", name = "nullius-carbon-dioxide", amount = 120},
      {type = "fluid", name = "nullius-nitrogen", amount = 15},
      {type = "fluid", name = "nullius-sulfur-dioxide", amount = 10},
    },
    main_product = "nullius-carbon-dioxide",
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },
})

-- SO2 catalytic decomposition: the only way to get oxygen on Vulcanus.
-- 40 SO2 --> 40 O2 + 1 sulfur (catalyzed by rutile/TiO2 at volcanic temperatures).
-- SO2 comes from lava silica extraction and atmosphere separation.
-- Rutile catalyst: 1 in, 1 out (not consumed). Productivity disabled.
data:extend({
  {
    type = "recipe",
    name = "nullius-so2-catalytic-decomposition",
    localised_name = {"recipe-name.nullius-so2-decomposition"},
    icon = "__angelspetrochemgraphics__/graphics/icons/molecules/oxygen.png",
    icon_size = 72,
    enabled = true,
    category = "nullius-low-temp-radiator",
    subgroup = "air-filtration-recipe",
    order = "nullius-vc",
    allow_productivity = false,
    no_productivity = true,
    energy_required = 4,
    ingredients = {
      {type = "fluid", name = "nullius-sulfur-dioxide", amount = 40},
      {type = "item", name = "nullius-rutile", amount = 1},
    },
    results = {
      {type = "fluid", name = "nullius-oxygen", amount = 40},
      {type = "item", name = "sulfur", amount = 1},
      {type = "item", name = "nullius-rutile", amount = 1},
    },
    main_product = "nullius-oxygen",
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },
})

-- Lubricant alt: graphite-based high-temperature lubricant.
-- Replaces methanol (organic) with graphite (inorganic).
-- Silicon-graphite colloidal suspension in HCl.
data:extend({
  {
    type = "recipe",
    name = "nullius-lubricant-vulcanus",
    localised_name = {"recipe-name.nullius-lubricant-vulcanus"},
    enabled = true,
    category = "basic-chemistry",
    subgroup = "chlorine-chemistry",
    order = "nullius-vc",
    crafting_machine_tint = {
      primary = data.raw.fluid["nullius-hydrogen-chloride"].flow_color,
      secondary = data.raw.fluid["nullius-hydrogen-chloride"].flow_color,
    },
    energy_required = 6,
    ingredients = {
      {type = "item", name = "nullius-silicon-ingot", amount = 1},
      {type = "item", name = "nullius-graphite", amount = 3},
      {type = "fluid", name = "nullius-hydrogen-chloride", amount = 50, fluidbox_index = 1},
    },
    results = {
      {type = "fluid", name = "nullius-lubricant", amount = 8},
      {type = "fluid", name = "nullius-acid-hydrochloric", amount = 10},
    },
    main_product = "nullius-lubricant",
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },
})

-- Heat pipe alt: no water needed (Vulcanus has almost no water).
data:extend({
  vulcanus_substitute_recipe("nullius-heat-pipe-1",
    "nullius-heat-pipe-1-vulcanus", {
      ["nullius-water"] = {
        {type = "item", name = "nullius-aluminum-sheet", amount = 1},
        {type = "item", name = "nullius-silica", amount = 2},
      },
    }, {
      localised_name = {"recipe-name.nullius-heat-pipe-vulcanus"},
      enabled = true,
      category = "small-crafting",
      order = "nullius-vc",
      show_amount_in_title = false,
      always_show_products = true,
      energy_required = 4,
    }),
})

-- Vulcanus alternative recipes: replace organic materials (plastic, rubber)
-- with silicon/silica-based substitutes.

data:extend({
  -- Silicon insulation item (replaces rubber for insulated wire).
  {
    type = "item",
    name = "nullius-silicon-insulation",
    localised_name = {"item-name.nullius-silicon-insulation"},
    icons = {{
      icon = "__angelsrefininggraphics__/graphics/icons/angels-ore6/angels-ore6-2.png",
      icon_size = 64,
      tint = {200, 200, 220},
    }},
    subgroup = "silicon-product",
    order = "nullius-vc",
    stack_size = 100,
  },

  -- Silicon insulation recipe: silica + aluminum sheet.
  {
    type = "recipe",
    name = "nullius-silicon-insulation",
    localised_name = {"recipe-name.nullius-silicon-insulation"},
    enabled = true,
    category = "dry-smelting",
    subgroup = "silicon-product",
    order = "nullius-vc",
    energy_required = 4,
    ingredients = {
      {type = "item", name = "nullius-silica", amount = 3},
      {type = "item", name = "nullius-aluminum-sheet", amount = 1},
    },
    results = {
      {type = "item", name = "nullius-silicon-insulation", amount = 2},
    },
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },

  vulcanus_substitute_recipe("nullius-insulated-wire-1",
    "nullius-insulated-wire-vulcanus", {
      ["nullius-rubber"] = {
        {type = "item", name = "nullius-silicon-insulation", amount = 2},
      },
    }, {
      localised_name = {"recipe-name.nullius-insulated-wire-vulcanus"},
      enabled = true,
      order = "nullius-vb",
    }),
  vulcanus_plastic_recipe("nullius-motor-1",
    "nullius-motor-1-vulcanus", {
      {type = "item", name = "nullius-silica", amount = 2},
    }, {
      localised_name = {"recipe-name.nullius-motor-vulcanus"},
      enabled = true,
      order = "nullius-vb",
    }),
  vulcanus_plastic_recipe("nullius-filter-1",
    "nullius-filter-1-vulcanus", {
      {type = "item", name = "nullius-silica", amount = 2},
    }, {
      localised_name = {"recipe-name.nullius-filter-vulcanus"},
      enabled = true,
      order = "nullius-vc",
      energy_required = 8,
    }),
  vulcanus_substitute_recipe("nullius-motor-2",
    "nullius-motor-2-vulcanus", {
      ["nullius-lubricant"] = {
        {type = "item", name = "nullius-silica", amount = 3},
      },
    }, {
      localised_name = {"recipe-name.nullius-motor-2-vulcanus"},
      enabled = true,
      category = "medium-crafting",
      order = "nullius-vc",
      energy_required = 10,
    }),
  vulcanus_substitute_recipe("nullius-pump-2",
    "nullius-pump-2-vulcanus", {
      ["nullius-rubber"] = {
        {type = "item", name = "nullius-silicon-insulation", amount = 2},
      },
    }, {
      localised_name = {"recipe-name.nullius-pump-2-vulcanus"},
      enabled = true,
      order = "nullius-vc",
      energy_required = 8,
    }),
  vulcanus_plastic_recipe("nullius-capacitor",
    "nullius-capacitor-vulcanus", {
      {type = "item", name = "nullius-silica", amount = 4},
    }, {
      localised_name = {"recipe-name.nullius-capacitor-vulcanus"},
      enabled = true,
      order = "nullius-vc",
      energy_required = 6,
    }),
  vulcanus_plastic_recipe("nullius-logic-circuit",
    "nullius-logic-circuit-vulcanus", {
      {type = "item", name = "nullius-silicon-insulation", amount = 3},
    }, {
      localised_name = {"recipe-name.nullius-logic-circuit-vulcanus"},
      enabled = true,
      order = "nullius-vc",
    }),
  vulcanus_plastic_recipe("nullius-display-panel",
    "nullius-display-panel-vulcanus", {
      {type = "item", name = "nullius-silicon-insulation", amount = 1},
    }, {enabled = true}),
  vulcanus_substitute_recipe("nullius-armor-plate",
    "nullius-armor-plate-vulcanus", {
      ["nullius-plastic"] = {
        {type = "item", name = "nullius-ceramic-powder", amount = 2},
      },
      ["nullius-rubber"] = {
        {type = "item", name = "nullius-silicon-insulation", amount = 2},
      },
    }, {enabled = true}),
  vulcanus_plastic_recipe("nullius-battery-1",
    "nullius-battery-1-vulcanus", {
      {type = "item", name = "nullius-ceramic-powder", amount = 2},
    }, {enabled = true}),
  vulcanus_plastic_recipe("nullius-insulation",
    "nullius-insulation-vulcanus", {
      {type = "item", name = "nullius-refractory-mix", amount = 2},
    }, {enabled = true}),
  vulcanus_plastic_recipe("nullius-repair-pack",
    "nullius-repair-pack-vulcanus", {
      {type = "item", name = "nullius-aluminum-sheet", amount = 1},
    }, {enabled = true}),
  vulcanus_plastic_recipe("nullius-levitation-field-1",
    "nullius-levitation-field-1-vulcanus", {
      {type = "item", name = "nullius-silicon-insulation", amount = 4},
    }, {enabled = true}),
  vulcanus_plastic_recipe("nullius-medium-tank-2",
    "nullius-medium-tank-2-vulcanus", {
      {type = "item", name = "nullius-glass", amount = 2},
    }, {enabled = true}),
  vulcanus_plastic_recipe("nullius-optical-cable",
    "nullius-optical-cable-vulcanus", {
      {type = "item", name = "nullius-silicon-insulation", amount = 1},
    }, {enabled = true}),
  vulcanus_plastic_recipe("nullius-rail", "nullius-rail-vulcanus", {
    {type = "item", name = "nullius-refractory-brick", amount = 3},
  }, {enabled = true}),
  vulcanus_plastic_recipe("nullius-solar-panel-1",
    "nullius-solar-panel-1-vulcanus", {
      {type = "fluid", name = "nullius-epoxy", amount = 10,
        fluidbox_index = 1},
    }, {
      enabled = true,
      category = "large-fluid-assembly",
    }),
  vulcanus_plastic_recipe("nullius-transformer",
    "nullius-transformer-vulcanus", {
      {type = "item", name = "nullius-silicon-insulation", amount = 1},
    }, {enabled = true}),
  vulcanus_plastic_recipe("nullius-power-pole-1",
    "nullius-small-electric-pole-vulcanus", {
      {type = "item", name = "nullius-glass", amount = 1},
    }, {enabled = true}),
  vulcanus_rubber_recipe("nullius-inserter-3",
    "nullius-bulk-inserter-vulcanus", {
      {type = "item", name = "nullius-silicon-insulation", amount = 2},
    }, {enabled = true}),
  vulcanus_rubber_recipe("nullius-conveyor-belt-2",
    "nullius-fast-transport-belt-vulcanus", {
      {type = "item", name = "nullius-silicon-insulation", amount = 4},
    }, {enabled = true}),
  vulcanus_substitute_recipe("nullius-small-chest-2",
    "nullius-iron-chest-vulcanus", {
      ["wooden-chest"] = {
        {type = "item", name = "nullius-iron-sheet", amount = 2},
      },
      ["nullius-rubber"] = {
        {type = "item", name = "nullius-silicon-insulation", amount = 1},
      },
    }, {enabled = true}),
  vulcanus_rubber_recipe("nullius-car-1",
    "nullius-car-1-vulcanus", {
      {type = "item", name = "nullius-silicon-insulation", amount = 4},
    }, {enabled = true}),
  vulcanus_rubber_recipe("nullius-chassis-2",
    "nullius-chassis-2-vulcanus", {
      {type = "item", name = "nullius-silicon-insulation", amount = 8},
    }, {enabled = true}),
  vulcanus_rubber_recipe("nullius-gun",
    "nullius-gun-vulcanus", {
      {type = "item", name = "nullius-silicon-insulation", amount = 1},
    }, {enabled = true}),
  vulcanus_rubber_recipe("nullius-leg-augmentation-3",
    "nullius-leg-augmentation-3-vulcanus", {
      {type = "item", name = "nullius-silicon-insulation", amount = 8},
    }, {enabled = true}),
  vulcanus_rubber_recipe("nullius-refueler",
    "nullius-refueler-vulcanus", {
      {type = "item", name = "nullius-silicon-insulation", amount = 3},
    }, {enabled = true}),
  vulcanus_rubber_recipe("nullius-self-repair-pack",
    "nullius-self-repair-pack-vulcanus", {
      {type = "item", name = "nullius-silicon-insulation", amount = 2},
    }, {enabled = true}),
  vulcanus_rubber_recipe("nullius-truck-1",
    "nullius-truck-1-vulcanus", {
      {type = "item", name = "nullius-silicon-insulation", amount = 8},
    }, {enabled = true}),
  vulcanus_rubber_recipe("nullius-power-switch",
    "nullius-power-switch-vulcanus", {
      {type = "item", name = "nullius-silicon-insulation", amount = 1},
    }, {enabled = true}),
  vulcanus_rubber_recipe("nullius-antenna",
    "nullius-programmable-speaker-vulcanus", {
      {type = "item", name = "nullius-silicon-insulation", amount = 1},
    }, {enabled = true}),

  -- Carbochlorination: Al2O3 + 3Cl2 + 3C -> 2AlCl3 + 3CO.
  -- Chlorine sink: dump AlCl3 into lava.
  {
    type = "recipe",
    name = "nullius-carbochlorination",
    localised_name = {"recipe-name.nullius-carbochlorination"},
    enabled = true,
    category = "nullius-high-temp-radiator",
    main_product = "nullius-aluminum-chloride",
    subgroup = "aluminum-ingot",
    order = "nullius-vc",
    always_show_made_in = true,
    energy_required = 6,
    ingredients = {
      {type = "item", name = "nullius-alumina", amount = 2},
      {type = "fluid", name = "nullius-chlorine", amount = 30},
      {type = "item", name = "nullius-graphite", amount = 3},
    },
    results = {
      {type = "item", name = "nullius-aluminum-chloride", amount = 4},
      {type = "fluid", name = "nullius-carbon-monoxide", amount = 30},
    },
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },
  -- Direct chlorination provides a renewable chlorine sink independent of
  -- hydrogen and graphite.  The solid product can be inserted into lava.
  {
    type = "recipe",
    name = "nullius-iron-chlorination",
    localised_name = {"recipe-name.nullius-iron-chlorination"},
    enabled = true,
    category = "nullius-high-temp-radiator",
    main_product = "nullius-iron-chloride",
    subgroup = "iron-ingot",
    order = "nullius-vc",
    always_show_made_in = true,
    energy_required = 4,
    ingredients = {
      {type = "item", name = "nullius-iron-ingot", amount = 2},
      {type = "fluid", name = "nullius-chlorine", amount = 30},
    },
    results = {
      {type = "item", name = "nullius-iron-chloride", amount = 4},
    },
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },
})

-- Alignment content is optional at startup and its technologies are activated
-- only for multiplayer forces.  Preserve both gates for the hot-environment
-- substitute instead of exposing the identification card from game start.
if data.raw.recipe["nullius-align-identification-card"] then
  local identification_card = vulcanus_plastic_recipe(
    "nullius-align-identification-card",
    "nullius-align-identification-card-vulcanus", {
      {type = "item", name = "nullius-aluminum-sheet", amount = 1},
    }, {enabled = false})
  data:extend({identification_card})

  local technology = data.raw.technology["nullius-alignment-1"]
  if not technology then
    error("Missing Alignment 1 technology for Vulcanus identification card")
  end
  table.insert(technology.effects, {
    type = "unlock-recipe",
    recipe = "nullius-align-identification-card-vulcanus",
  })
end

local function vulcanus_boxed_plastic_recipe(source_name, name, replacement,
    overrides)
  overrides = table.deepcopy(overrides or {})
  overrides.enabled = false
  return vulcanus_substitute_recipe(source_name, name, {
    ["nullius-box-plastic"] = replacement,
  }, overrides)
end

local function vulcanus_boxed_rubber_recipe(source_name, name, replacement,
    overrides)
  overrides = table.deepcopy(overrides or {})
  overrides.enabled = false
  return vulcanus_substitute_recipe(source_name, name, {
    ["nullius-box-rubber"] = replacement,
  }, overrides)
end

-- Bulk counterparts for every Vulcanus polymer-free product whose existing
-- boxed recipe still consumes boxed plastic or rubber.  Five unboxed units
-- equal one boxed unit; intermediates without boxed prototypes are scaled by 5.
data:extend({
  vulcanus_boxed_plastic_recipe("nullius-boxed-barrel-1",
    "nullius-boxed-barrel-vulcanus", {
      {type = "item", name = "nullius-box-aluminum-sheet", amount = 2},
      {type = "item", name = "nullius-box-glass", amount = 1},
    }, {energy_required = 50}),
  vulcanus_substitute_recipe("nullius-boxed-explosive",
    "nullius-boxed-thermite-explosive", {
      ["nullius-acid-nitric"] = {
        {type = "item", name = "nullius-chlorine-barrel", amount = 5},
      },
      ["nullius-acid-sulfuric"] = {
        {type = "item", name = "nullius-sulfur-dioxide-barrel", amount = 5},
      },
      ["nullius-glycerol"] = {
        {type = "item", name = "nullius-box-aluminum-powder", amount = 4},
      },
      ["nullius-box-sand"] = {
        {type = "item", name = "nullius-box-green-wire", amount = 1},
        {type = "item", name = "nullius-small-miner-1", amount = 5},
      },
      ["nullius-box-plastic"] = {},
    }, {
      enabled = false,
      energy_required = 150,
      localised_name = {"recipe-name.nullius-boxed",
        {"recipe-name.nullius-thermite-explosive"}},
      results = {
        {type = "item", name = "nullius-box-explosive", amount = 1},
      },
      main_product = "nullius-box-explosive",
    }),
  vulcanus_boxed_plastic_recipe("nullius-boxed-logic-circuit",
    "nullius-boxed-logic-circuit-vulcanus", {
      {type = "item", name = "nullius-silicon-insulation", amount = 15},
    }),
  vulcanus_boxed_plastic_recipe("nullius-boxed-capacitor",
    "nullius-boxed-capacitor-vulcanus", {
      {type = "item", name = "nullius-box-silica", amount = 4},
    }, {energy_required = 30}),
  vulcanus_boxed_plastic_recipe("nullius-boxed-filter-1",
    "nullius-boxed-filter-1-vulcanus", {
      {type = "item", name = "nullius-box-silica", amount = 2},
    }, {energy_required = 40}),
  vulcanus_boxed_plastic_recipe("nullius-boxed-splitter-1",
    "nullius-boxed-splitter-1-vulcanus", {
      {type = "item", name = "nullius-silicon-insulation", amount = 10},
    }, {energy_required = 20}),
  vulcanus_substitute_recipe("nullius-boxed-insulated-wire-1",
    "nullius-boxed-insulated-wire-vulcanus", {
      ["nullius-box-rubber"] = {
        {type = "item", name = "nullius-silicon-insulation", amount = 10},
      },
    }, {enabled = false}),
  vulcanus_substitute_recipe("nullius-boxed-one-way-valve",
    "nullius-boxed-one-way-valve-vulcanus", {
      ["nullius-box-pipe-2"] = {
        {type = "item", name = "nullius-box-pipe-1", amount = 1},
      },
      ["nullius-box-rubber"] = {},
      ["nullius-box-steel-sheet"] = {
        {type = "item", name = "nullius-box-iron-sheet", amount = 1},
      },
    }, {enabled = false, energy_required = 20}),
  vulcanus_substitute_recipe("nullius-boxed-pump-2",
    "nullius-boxed-pump-2-vulcanus", {
      ["nullius-box-rubber"] = {
      {type = "item", name = "nullius-silicon-insulation", amount = 10},
      },
    }, {enabled = false, energy_required = 40}),
  vulcanus_boxed_plastic_recipe("nullius-boxed-display-panel",
    "nullius-boxed-display-panel-vulcanus", {
      {type = "item", name = "nullius-silicon-insulation", amount = 5},
    }),
  vulcanus_boxed_plastic_recipe("nullius-boxed-battery-1",
    "nullius-boxed-battery-1-vulcanus", {
      {type = "item", name = "nullius-box-ceramic-powder", amount = 2},
    }),
  vulcanus_boxed_plastic_recipe("nullius-boxed-insulation",
    "nullius-boxed-insulation-vulcanus", {
      {type = "item", name = "nullius-refractory-mix", amount = 10},
    }),
  vulcanus_boxed_plastic_recipe("nullius-boxed-repair-pack",
    "nullius-boxed-repair-pack-vulcanus", {
      {type = "item", name = "nullius-box-aluminum-sheet", amount = 1},
    }),
  vulcanus_boxed_plastic_recipe("nullius-boxed-levitation-field-1",
    "nullius-boxed-levitation-field-1-vulcanus", {
      {type = "item", name = "nullius-silicon-insulation", amount = 20},
    }),
  vulcanus_boxed_plastic_recipe("nullius-boxed-medium-tank-2",
    "nullius-boxed-medium-tank-2-vulcanus", {
      {type = "item", name = "nullius-box-glass", amount = 2},
    }),
  vulcanus_boxed_plastic_recipe("nullius-boxed-optical-cable",
    "nullius-boxed-optical-cable-vulcanus", {
      {type = "item", name = "nullius-silicon-insulation", amount = 5},
    }),
  vulcanus_boxed_plastic_recipe("nullius-boxed-rail",
    "nullius-boxed-rail-vulcanus", {
      {type = "item", name = "nullius-box-refractory-brick", amount = 3},
    }),
  vulcanus_boxed_plastic_recipe("nullius-boxed-solar-panel-1",
    "nullius-boxed-solar-panel-1-vulcanus", {
      {type = "fluid", name = "nullius-epoxy", amount = 50,
        fluidbox_index = 1},
    }, {category = "huge-fluid-assembly"}),
  vulcanus_boxed_plastic_recipe("nullius-boxed-transformer",
    "nullius-boxed-transformer-vulcanus", {
      {type = "item", name = "nullius-silicon-insulation", amount = 5},
    }),
  vulcanus_boxed_rubber_recipe("nullius-boxed-antenna",
    "nullius-boxed-antenna-vulcanus", {
      {type = "item", name = "nullius-silicon-insulation", amount = 5},
    }),
  vulcanus_boxed_rubber_recipe("nullius-boxed-belt-2",
    "nullius-boxed-belt-2-vulcanus", {
      {type = "item", name = "nullius-silicon-insulation", amount = 20},
    }),
  vulcanus_boxed_rubber_recipe("nullius-boxed-inserter-3",
    "nullius-boxed-inserter-3-vulcanus", {
      {type = "item", name = "nullius-silicon-insulation", amount = 10},
    }),
  vulcanus_boxed_rubber_recipe("nullius-boxed-power-switch",
    "nullius-boxed-power-switch-vulcanus", {
      {type = "item", name = "nullius-silicon-insulation", amount = 5},
    }),
})

-- Thermite explosive: aluminum-sulfur thermite in a chlorine barrel.
-- Alt to improvised explosive that avoids methanol (organic).
-- Hand-craftable like the original. No surface condition.
data:extend({
  {
    type = "recipe",
    name = "nullius-thermite-explosive",
    localised_name = {"recipe-name.nullius-thermite-explosive"},
    icons = {
      {
        icon = "__base__/graphics/icons/explosives.png",
        icon_size = 64,
        scale = 0.5,
      },
      {
        icon = "__angelssmeltinggraphics__/graphics/icons/powder-aluminium.png",
        icon_size = 64,
        scale = 0.3,
        shift = {-7, -7},
      },
    },
    order = "nullius-xb",
    enabled = false,
    always_show_made_in = true,
    allow_decomposition = false,
    allow_as_intermediate = false,
    category = "hand-crafting",
    energy_required = 30,
    ingredients = {
      {type = "item", name = "nullius-chlorine-barrel", amount = 1},
      {type = "item", name = "nullius-sulfur-dioxide-barrel", amount = 1},
      {type = "item", name = "nullius-aluminum-powder", amount = 4},
      {type = "item", name = "nullius-red-wire", amount = 1},
      {type = "item", name = "nullius-green-wire", amount = 1},
      {type = "item", name = "nullius-small-miner-1", amount = 1},
    },
    results = {
      {type = "item", name = "cliff-explosives", amount = 1},
    },
  },
})

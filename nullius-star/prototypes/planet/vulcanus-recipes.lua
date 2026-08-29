-- Vulcanus lava processing recipes and molten bloom items.

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
  {
    type = "recipe",
    name = "nullius-vulcanus-barrel",
    localised_name = {"recipe-name.nullius-vulcanus-barrel"},
    enabled = false,
    category = "small-crafting",
    subgroup = "canisters",
    order = "nullius-ba",
    always_show_made_in = true,
    allow_decomposition = false,
    show_amount_in_title = false,
    always_show_products = true,
    energy_required = 10,
    ingredients = {
      {type = "item", name = "nullius-steel-sheet", amount = 2},
      {type = "item", name = "nullius-aluminum-sheet", amount = 2},
      {type = "item", name = "nullius-glass", amount = 1},
      {type = "item", name = "nullius-one-way-valve", amount = 1},
    },
    results = {
      {type = "item", name = "barrel", amount = 3},
    },
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },
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
  -- Splitter alt: underground belt + silicon insulation (replaces plastic).
  {
    type = "recipe",
    name = "nullius-splitter-1-vulcanus",
    localised_name = {"recipe-name.nullius-splitter-vulcanus"},
    enabled = true,
    category = "small-crafting",
    subgroup = "belt",
    order = "nullius-vc",
    always_show_made_in = true,
    energy_required = 4,
    ingredients = {
      {type = "item", name = "underground-belt", amount = 2},
      {type = "item", name = "nullius-silicon-insulation", amount = 2},
    },
    results = {
      {type = "item", name = "splitter", amount = 1},
    },
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },

  -- Underground pipe alt: pipe + silica (replaces sand, which needs sandstone).
  {
    type = "recipe",
    name = "nullius-underground-pipe-1-vulcanus",
    localised_name = {"recipe-name.nullius-underground-pipe-vulcanus"},
    enabled = true,
    category = "small-crafting",
    subgroup = "pipes",
    order = "nullius-vc",
    always_show_made_in = true,
    always_show_products = true,
    show_amount_in_title = false,
    energy_required = 8,
    ingredients = {
      {type = "item", name = "pipe", amount = 5},
      {type = "item", name = "nullius-silica", amount = 3},
    },
    results = {
      {type = "item", name = "pipe-to-ground", amount = 2},
    },
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },
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
  {
    type = "recipe",
    name = "nullius-heat-pipe-1-vulcanus",
    localised_name = {"recipe-name.nullius-heat-pipe-vulcanus"},
    enabled = true,
    category = "small-crafting",
    order = "nullius-vc",
    show_amount_in_title = false,
    always_show_products = true,
    energy_required = 4,
    ingredients = {
      {type = "item", name = "nullius-pipe-2", amount = 1},
      {type = "item", name = "nullius-aluminum-sheet", amount = 2},
      {type = "item", name = "nullius-silica", amount = 2},
    },
    results = {
      {type = "item", name = "nullius-heat-pipe-1", amount = 1},
    },
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },
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

  -- Insulated wire alt: aluminum wire + silicon insulation (replaces rubber).
  {
    type = "recipe",
    name = "nullius-insulated-wire-vulcanus",
    localised_name = {"recipe-name.nullius-insulated-wire-vulcanus"},
    enabled = true,
    category = "small-crafting",
    order = "nullius-vb",
    always_show_made_in = true,
    show_amount_in_title = false,
    always_show_products = true,
    energy_required = 6,
    ingredients = {
      {type = "item", name = "nullius-aluminum-wire", amount = 3},
      {type = "item", name = "nullius-silicon-insulation", amount = 2},
    },
    results = {
      {type = "item", name = "copper-cable", amount = 4},
    },
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },

  -- Motor alt: iron wire + plate + silica + rod (replaces plastic).
  {
    type = "recipe",
    name = "nullius-motor-1-vulcanus",
    localised_name = {"recipe-name.nullius-motor-vulcanus"},
    enabled = true,
    category = "medium-crafting",
    subgroup = "mechanical-intermediate",
    order = "nullius-vb",
    always_show_made_in = true,
    energy_required = 8,
    ingredients = {
      {type = "item", name = "nullius-iron-wire", amount = 2},
      {type = "item", name = "nullius-iron-plate", amount = 1},
      {type = "item", name = "nullius-silica", amount = 2},
      {type = "item", name = "nullius-iron-rod", amount = 1},
    },
    results = {
      {type = "item", name = "nullius-motor-1", amount = 1},
    },
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },

  -- Filter-1 alt: silica + graphite + iron sheet + CO2 (replaces plastic).
  {
    type = "recipe",
    name = "nullius-filter-1-vulcanus",
    localised_name = {"recipe-name.nullius-filter-vulcanus"},
    enabled = true,
    category = "basic-chemistry",
    order = "nullius-vc",
    show_amount_in_title = false,
    always_show_products = true,
    crafting_machine_tint = {
      primary = data.raw.fluid["nullius-carbon-dioxide"].flow_color,
      secondary = data.raw.fluid["nullius-carbon-dioxide"].flow_color,
    },
    energy_required = 8,
    ingredients = {
      {type = "item", name = "nullius-silica", amount = 2},
      {type = "item", name = "nullius-graphite", amount = 1},
      {type = "item", name = "nullius-iron-sheet", amount = 1},
      {type = "fluid", name = "nullius-carbon-dioxide", amount = 10, fluidbox_index = 3},
    },
    results = {
      {type = "item", name = "nullius-filter-1", amount = 1},
    },
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },

  -- Motor-2 alt: insulated wire + steel plate + steel gear + steel rod + silica (replaces lubricant).
  {
    type = "recipe",
    name = "nullius-motor-2-vulcanus",
    localised_name = {"recipe-name.nullius-motor-2-vulcanus"},
    enabled = true,
    category = "medium-crafting",
    subgroup = "mechanical-intermediate",
    order = "nullius-vc",
    always_show_made_in = true,
    energy_required = 10,
    ingredients = {
      {type = "item", name = "copper-cable", amount = 2},
      {type = "item", name = "nullius-steel-plate", amount = 1},
      {type = "item", name = "nullius-steel-gear", amount = 1},
      {type = "item", name = "nullius-steel-rod", amount = 1},
      {type = "item", name = "nullius-silica", amount = 3},
    },
    results = {
      {type = "item", name = "nullius-motor-2", amount = 1},
    },
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },

  -- Pump-2 alt: pump-1 + motor-2 + pipe-2 + silicon insulation (replaces rubber).
  {
    type = "recipe",
    name = "nullius-pump-2-vulcanus",
    localised_name = {"recipe-name.nullius-pump-2-vulcanus"},
    enabled = true,
    category = "medium-crafting",
    order = "nullius-vc",
    always_show_made_in = true,
    energy_required = 8,
    ingredients = {
      {type = "item", name = "nullius-pump-1", amount = 1},
      {type = "item", name = "nullius-motor-2", amount = 1},
      {type = "item", name = "nullius-pipe-2", amount = 2},
      {type = "item", name = "nullius-silicon-insulation", amount = 2},
    },
    results = {
      {type = "item", name = "nullius-pump-2", amount = 1},
    },
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },

  -- Capacitor alt: aluminum sheet + silica + alumina + graphite (replaces plastic).
  {
    type = "recipe",
    name = "nullius-capacitor-vulcanus",
    localised_name = {"recipe-name.nullius-capacitor-vulcanus"},
    enabled = true,
    category = "machine-casting",
    subgroup = "battery",
    order = "nullius-vc",
    show_amount_in_title = false,
    always_show_products = true,
    energy_required = 6,
    ingredients = {
      {type = "item", name = "nullius-aluminum-sheet", amount = 2},
      {type = "item", name = "nullius-silica", amount = 4},
      {type = "item", name = "nullius-alumina", amount = 1},
      {type = "item", name = "nullius-graphite", amount = 1},
    },
    results = {
      {type = "item", name = "nullius-capacitor", amount = 2},
    },
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },

  -- Logic circuit alt: silicon insulation replaces plastic.
  {
    type = "recipe",
    name = "nullius-logic-circuit-vulcanus",
    localised_name = {"recipe-name.nullius-logic-circuit-vulcanus"},
    enabled = true,
    category = "tiny-assembly",
    subgroup = "electronic-intermediate",
    order = "nullius-vc",
    show_amount_in_title = false,
    always_show_products = true,
    energy_required = 5,
    ingredients = {
      {type = "item", name = "nullius-silicon-insulation", amount = 3},
      {type = "item", name = "nullius-aluminum-wire", amount = 4},
      {type = "item", name = "nullius-polycrystalline-silicon", amount = 2},
      {type = "item", name = "nullius-graphite", amount = 1},
    },
    results = {
      {type = "item", name = "decider-combinator", amount = 3},
    },
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },

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

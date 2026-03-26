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
    spoil_result = "nullius-aluminum-ingot",
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
      {type = "item", name = "nullius-mineral-dust", amount = 10},
    },
    main_product = "nullius-molten-iron-bloom",
    allow_productivity = true,
    surface_conditions = {{property = "gravity", min = 39}},
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
      {type = "item", name = "nullius-mineral-dust", amount = 8},
    },
    main_product = "nullius-molten-aluminum-bloom",
    allow_productivity = true,
    surface_conditions = {{property = "gravity", min = 39}},
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
    surface_conditions = {{property = "gravity", min = 39}},
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
      {type = "item", name = "nullius-mineral-dust", amount = 5},
      {type = "fluid", name = "nullius-compressed-volcanic-gas", amount = 15},
      {type = "fluid", name = "nullius-sulfur-dioxide", amount = 10},
    },
    main_product = "nullius-silica",
    allow_productivity = true,
    surface_conditions = {{property = "gravity", min = 39}},
  },
})

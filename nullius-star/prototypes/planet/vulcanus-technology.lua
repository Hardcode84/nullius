local recipe_productivity = require("prototypes.recipe-productivity")

local pneumatic = data.raw.technology["nullius-pneumatic-technology"]
if not pneumatic then error("Missing nullius-pneumatic-technology") end
pneumatic.effects = pneumatic.effects or {}
for _, recipe in ipairs({
    "nullius-metallurgic-pack",
    "nullius-vulcanus-barrel",
    "nullius-vulcanus-radiator-1",
    "nullius-vulcanus-radiator-2",
    "nullius-temperature-sensor",
    "nullius-carbochlorination",
    "nullius-iron-chlorination",
}) do
  pneumatic.effects[#pneumatic.effects + 1] = {
    type = "unlock-recipe",
    recipe = recipe,
  }
end

local boiling_1 = data.raw.technology["nullius-boiling-1"]
if not boiling_1 then error("Missing nullius-boiling-1") end
boiling_1.effects = boiling_1.effects or {}
boiling_1.effects[#boiling_1.effects + 1] = {
  type = "unlock-recipe",
  recipe = "nullius-iron-assisted-sludge-dehydration",
}

local mass_production = data.raw.technology["nullius-mass-production-5"]
if not mass_production then error("Missing nullius-mass-production-5") end
mass_production.effects = mass_production.effects or {}
for _, recipe in ipairs({
    "nullius-boxed-barrel-vulcanus",
    "nullius-boxed-thermite-explosive",
    "nullius-boxed-logic-circuit-vulcanus",
    "nullius-boxed-capacitor-vulcanus",
    "nullius-boxed-filter-1-vulcanus",
    "nullius-boxed-splitter-1-vulcanus",
    "nullius-boxed-insulated-wire-vulcanus",
    "nullius-boxed-one-way-valve-vulcanus",
    "nullius-boxed-pump-2-vulcanus",
    "nullius-boxed-display-panel-vulcanus",
    "nullius-boxed-battery-1-vulcanus",
    "nullius-boxed-insulation-vulcanus",
    "nullius-boxed-repair-pack-vulcanus",
    "nullius-boxed-levitation-field-1-vulcanus",
    "nullius-boxed-medium-tank-2-vulcanus",
    "nullius-boxed-optical-cable-vulcanus",
    "nullius-boxed-rail-vulcanus",
    "nullius-boxed-solar-panel-1-vulcanus",
    "nullius-boxed-transformer-vulcanus",
    "nullius-boxed-antenna-vulcanus",
    "nullius-boxed-inserter-3-vulcanus",
    "nullius-boxed-power-switch-vulcanus",
    "nullius-box-clockwork-logistic-robot",
    "nullius-unbox-clockwork-logistic-robot",
}) do
  mass_production.effects[#mass_production.effects + 1] = {
    type = "unlock-recipe",
    recipe = recipe,
  }
end

local mass_production_6 = data.raw.technology["nullius-mass-production-6"]
if not mass_production_6 then error("Missing nullius-mass-production-6") end
mass_production_6.effects = mass_production_6.effects or {}
mass_production_6.effects[#mass_production_6.effects + 1] = {
  type = "unlock-recipe",
  recipe = "nullius-boxed-belt-2-vulcanus",
}

local sulfur_processing_2 = data.raw.technology["nullius-sulfur-processing-2"]
if not sulfur_processing_2 then error("Missing nullius-sulfur-processing-2") end
sulfur_processing_2.effects = sulfur_processing_2.effects or {}
sulfur_processing_2.effects[#sulfur_processing_2.effects + 1] = {
  type = "unlock-recipe",
  recipe = "nullius-decompress-volcanic-gas",
}

local organic_chemistry_5 = data.raw.technology["nullius-organic-chemistry-5"]
if not organic_chemistry_5 then error("Missing nullius-organic-chemistry-5") end
organic_chemistry_5.effects = organic_chemistry_5.effects or {}
organic_chemistry_5.effects[#organic_chemistry_5.effects + 1] = {
  type = "unlock-recipe",
  recipe = "nullius-high-temperature-resin",
}

local sodium_processing = data.raw.technology["nullius-sodium-processing"]
if not sodium_processing then error("Missing nullius-sodium-processing") end
sodium_processing.effects = sodium_processing.effects or {}
sodium_processing.effects[#sodium_processing.effects + 1] = {
  type = "unlock-recipe",
  recipe = "nullius-carbothermic-sodium",
}

local function productivity_technology(name, order, icon, prerequisite,
    categories)
  return {
    type = "technology",
    name = name,
    order = order,
    icon = icon,
    icon_size = 256,
    effects = recipe_productivity.effects(categories, 0.01),
    unit = {
      count_formula = "100*L^2",
      ingredients = {{"nullius-metallurgic-pack", 1}},
      time = 30,
    },
    prerequisites = {"nullius-efficient-metallurgic-science", prerequisite},
    max_level = "infinite",
    upgrade = true,
  }
end

data:extend({
  {
    type = "technology",
    name = "nullius-volcanic-alkali-processing",
    order = "nullius-df-y",
    icon = "__base__/graphics/technology/oil-processing.png",
    icon_size = 256,
    effects = {
      {type = "unlock-recipe", recipe = "nullius-volcanic-saline"},
      {type = "unlock-recipe", recipe = "nullius-volcanic-causticization"},
    },
    unit = {
      count = 50,
      ingredients = {
        {"nullius-geology-pack", 1},
        {"nullius-climatology-pack", 1},
        {"nullius-mechanical-pack", 1},
        {"nullius-electrical-pack", 1},
      },
      time = 30,
    },
    prerequisites = {"nullius-nitrogen-chemistry-1"},
  },
  {
    type = "technology",
    name = "nullius-efficient-metallurgic-science",
    order = "nullius-df-z",
    icon = "__base__/graphics/technology/advanced-material-processing-2.png",
    icon_size = 256,
    effects = {
      {type = "unlock-recipe", recipe = "nullius-metallurgic-pack-efficient"},
      {type = "unlock-recipe", recipe = "nullius-chlorine-barrel"},
      {type = "unlock-recipe", recipe = "nullius-sulfur-dioxide-barrel"},
    },
    unit = {
      count = 5,
      ingredients = {
        {"nullius-metallurgic-pack", 2},
        {"nullius-geology-pack", 2},
        {"nullius-mechanical-pack", 1},
        {"nullius-electrical-pack", 1},
      },
      time = 30,
    },
    prerequisites = {"nullius-pneumatic-technology"},
  },
  {
    type = "technology",
    name = "nullius-primitive-robotics",
    order = "nullius-df-z0",
    icon = "__base__/graphics/technology/logistic-robotics.png",
    icon_size = 256,
    effects = {
      {type = "unlock-recipe", recipe = "nullius-clockwork-roboport"},
      {type = "unlock-recipe", recipe = "nullius-clockwork-logistic-robot"},
      {type = "unlock-recipe", recipe = "nullius-primitive-storage-chest"},
      {type = "unlock-recipe", recipe = "nullius-primitive-supply-chest"},
      {type = "unlock-recipe", recipe = "nullius-primitive-demand-chest"},
    },
    unit = {
      count = 5,
      ingredients = {
        {"nullius-metallurgic-pack", 5},
        {"nullius-mechanical-pack", 2},
        {"nullius-electrical-pack", 2},
      },
      time = 30,
    },
    prerequisites = {
      "nullius-efficient-metallurgic-science",
      "nullius-weaving-1",
    },
  },
  {
    type = "technology",
    name = "nullius-hot-metalworking",
    order = "nullius-df-za",
    icon = "__base__/graphics/technology/advanced-material-processing-2.png",
    icon_size = 256,
    effects = {
      {type = "unlock-recipe", recipe = "nullius-hot-iron-plate"},
      {type = "unlock-recipe", recipe = "nullius-hot-iron-rod"},
      {type = "unlock-recipe", recipe = "nullius-hot-aluminum-plate"},
      {type = "unlock-recipe", recipe = "nullius-hot-aluminum-rod"},
    },
    unit = {
      count = 10,
      ingredients = {
        {"nullius-metallurgic-pack", 10},
        {"nullius-mechanical-pack", 1},
      },
      time = 30,
    },
    prerequisites = {
      "nullius-efficient-metallurgic-science",
      "nullius-aluminum-working-1",
    },
  },
  {
    type = "technology",
    name = "nullius-vulcanus-refractory-engineering",
    order = "nullius-df-zb",
    icon = "__angelssmeltinggraphics__/graphics/icons/brick-clay.png",
    icon_size = 32,
    effects = {
      {type = "unlock-recipe", recipe = "nullius-refractory-mix-vulcanus"},
      {type = "unlock-recipe", recipe = "nullius-refractory-brick-vulcanus"},
      {type = "unlock-recipe", recipe = "nullius-heat-pipe-2-vulcanus"},
      {type = "unlock-recipe", recipe = "nullius-vulcanus-radiator-2-refractory"},
    },
    unit = {
      count = 10,
      ingredients = {
        {"nullius-metallurgic-pack", 40},
        {"nullius-geology-pack", 4},
        {"nullius-chemical-pack", 4},
      },
      time = 45,
    },
    prerequisites = {
      "nullius-hot-metalworking",
      "nullius-ceramics",
      "nullius-thermal-storage-2",
    },
  },
  {
    type = "technology",
    name = "nullius-volcanic-titanium-metallurgy",
    order = "nullius-df-zc",
    icon = "__angelssmeltinggraphics__/graphics/technology/smelting-titanium-tech.png",
    icon_size = 256,
    effects = {
      {type = "unlock-recipe", recipe = "nullius-titanium-ingot-vulcanus"},
      {type = "unlock-recipe", recipe = "nullius-aluminum-chloride-recovery"},
      {type = "unlock-recipe", recipe = "nullius-hydro-plant-2-vulcanus"},
      {type = "unlock-recipe", recipe = "nullius-foundry-2-vulcanus"},
    },
    unit = {
      count = 10,
      ingredients = {
        {"nullius-metallurgic-pack", 80},
        {"nullius-geology-pack", 8},
        {"nullius-chemical-pack", 8},
      },
      time = 60,
    },
    prerequisites = {
      "nullius-vulcanus-refractory-engineering",
      "nullius-titanium-production-2",
      "nullius-water-filtration-3",
      "nullius-metalworking-2",
    },
  },
  {
    type = "technology",
    name = "nullius-thermal-engineering-2",
    order = "nullius-dg-e",
    icon = "__base__/graphics/technology/advanced-material-processing-2.png",
    icon_size = 256,
    effects = {},
    unit = {
      count = 10,
      ingredients = {
        {"nullius-metallurgic-pack", 80},
        {"nullius-geology-pack", 8},
        {"nullius-mechanical-pack", 4},
        {"nullius-electrical-pack", 4},
        {"nullius-chemical-pack", 4},
      },
      time = 45,
    },
    prerequisites = {
      "nullius-efficient-metallurgic-science",
      "nullius-mineral-processing-2",
      "nullius-metallurgy-2",
      "nullius-metalworking-2",
      "nullius-thermal-storage-2",
      "nullius-solar-thermal-power-2",
    },
  },
  {
    type = "technology",
    name = "nullius-thermal-engineering-3",
    order = "nullius-dg-f",
    icon = "__base__/graphics/technology/advanced-material-processing-2.png",
    icon_size = 256,
    effects = {},
    unit = {
      count = 20,
      ingredients = {
        {"nullius-metallurgic-pack", 160},
        {"nullius-geology-pack", 16},
        {"nullius-climatology-pack", 8},
        {"nullius-mechanical-pack", 8},
        {"nullius-electrical-pack", 8},
        {"nullius-chemical-pack", 16},
      },
      time = 60,
    },
    prerequisites = {
      "nullius-thermal-engineering-2",
      "nullius-mineral-processing-3",
      "nullius-metallurgy-3",
      "nullius-metalworking-4",
      "nullius-thermal-storage-3",
      "nullius-nuclear-power-1",
    },
  },
  productivity_technology(
    "nullius-crushing-productivity-1",
    "nullius-dg-b",
    "__base__/graphics/technology/mining-productivity.png",
    "nullius-mineral-processing-1",
    {"ore-crushing"}),
  productivity_technology(
    "nullius-smelting-productivity-1",
    "nullius-dg-c",
    "__base__/graphics/technology/advanced-material-processing-2.png",
    "nullius-metallurgy-1",
    {"dry-smelting"}),
  productivity_technology(
    "nullius-casting-productivity-1",
    "nullius-dg-d",
    "__base__/graphics/technology/steel-processing.png",
    "nullius-metalworking-1",
    {"machine-casting"}),
})

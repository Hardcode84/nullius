local recipe_productivity = require("prototypes.recipe-productivity")

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
    prerequisites = {
      "nullius-thermal-engineering-1",
      prerequisite,
    },
    max_level = "infinite",
    upgrade = true,
  }
end

data:extend({
  {
    type = "technology",
    name = "nullius-thermal-engineering-1",
    order = "nullius-dg-a",
    icon = "__base__/graphics/technology/advanced-material-processing-2.png",
    icon_size = 256,
    effects = {},
    unit = {
      count = 5,
      ingredients = {
        {"nullius-metallurgic-pack", 40},
        {"nullius-geology-pack", 2},
        {"nullius-mechanical-pack", 1},
      },
      time = 30,
    },
    prerequisites = {
      "nullius-pneumatic-technology",
      "nullius-mineral-processing-1",
      "nullius-metallurgy-1",
      "nullius-metalworking-1",
      "nullius-boiling-1",
      "nullius-solar-thermal-power-1",
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

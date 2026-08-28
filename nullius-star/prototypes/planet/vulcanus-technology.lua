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
})

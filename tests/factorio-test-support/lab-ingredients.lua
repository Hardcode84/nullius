-- Research technologies for experiment-research-lab-ingredients.
local function technology(name, ingredients, count)
  return {
    type = "technology",
    name = name,
    localised_name = name,
    icon = "__base__/graphics/technology/research-speed.png",
    icon_size = 256,
    enabled = false,
    visible_when_disabled = false,
    effects = {},
    unit = {count = count, ingredients = ingredients, time = 1},
  }
end

data:extend({
  technology("factorio-test-lab-two-packs",
    {{"nullius-geology-pack", 1}, {"nullius-climatology-pack", 1}}, 1000),
  technology("factorio-test-lab-one-pack",
    {{"nullius-climatology-pack", 1}}, 1000),
  technology("factorio-test-lab-asymmetric",
    {{"nullius-geology-pack", 20}, {"nullius-climatology-pack", 1}}, 10),
})

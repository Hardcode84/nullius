-- Two-fluid electromagnetism recipes for real overcharged assemblers. Amounts
-- mirror a planned fixation recipe at ordinary and above-500 boxed scale.
local output = "factorio-test-em-fluid-output"
local function recipe(name, nitrogen, water)
  return {
    type = "recipe",
    name = name,
    enabled = true,
    hidden = true,
    categories = {"nullius-electromagnetism-1"},
    energy_required = 1,
    allow_productivity = true,
    ingredients = {
      {type = "fluid", name = "nullius-nitrogen", amount = nitrogen},
      {type = "fluid", name = "nullius-water", amount = water},
    },
    results = {{type = "item", name = output, amount = 1}},
  }
end
data:extend({
  {type = "item", name = output, hidden = true, stack_size = 1000,
    icon = "__base__/graphics/icons/copper-plate.png", icon_size = 64},
  recipe("factorio-test-em-two-fluid", 10, 20),
  recipe("factorio-test-em-two-fluid-bulk", 600, 1200),
})

local category = "factorio-test-innate-productivity"
local input = "factorio-test-productivity-input"
local output = "factorio-test-productivity-output"

local machine = table.deepcopy(data.raw["assembling-machine"]["nullius-small-assembler-1"])
machine.name = "factorio-test-innate-productivity-machine"
machine.localised_name = "Innate productivity experiment machine"
machine.flags = {"placeable-off-grid", "not-on-map"}
machine.minable = nil
machine.fast_replaceable_group = nil
machine.next_upgrade = nil
machine.crafting_categories = {category}
machine.crafting_speed = 10
machine.energy_source = {type = "void"}
machine.energy_usage = "1W"
machine.module_slots = 1
machine.allowed_effects = {"productivity"}
machine.effect_receiver = {base_effect = {productivity = 0.5}}
machine.hidden_in_factoriopedia = true

data:extend({
  {
    type = "item",
    name = input,
    icon = "__base__/graphics/icons/iron-plate.png",
    icon_size = 64,
    hidden = true,
    stack_size = 1000,
  },
  {
    type = "item",
    name = output,
    icon = "__base__/graphics/icons/copper-plate.png",
    icon_size = 64,
    hidden = true,
    stack_size = 1000,
  },
  {type = "recipe-category", name = category},
  {
    type = "recipe",
    name = "factorio-test-productivity-rejected",
    enabled = false,
    hidden = true,
    category = category,
    energy_required = 0.1,
    ingredients = {{type = "item", name = input, amount = 1}},
    results = {{type = "item", name = output, amount = 1}},
    allow_productivity = false,
  },
  {
    type = "recipe",
    name = "factorio-test-productivity-allowed",
    enabled = false,
    hidden = true,
    category = category,
    energy_required = 0.1,
    ingredients = {{type = "item", name = input, amount = 1}},
    results = {{type = "item", name = output, amount = 1}},
    allow_productivity = true,
  },
  {
    type = "recipe",
    name = "factorio-test-productivity-capped",
    enabled = false,
    hidden = true,
    category = category,
    energy_required = 0.1,
    ingredients = {{type = "item", name = input, amount = 1}},
    results = {{type = "item", name = output, amount = 1}},
    allow_productivity = true,
    maximum_productivity = 0.52,
  },
  {
    type = "recipe",
    name = "factorio-test-productivity-disabled",
    enabled = false,
    hidden = true,
    category = category,
    energy_required = 0.1,
    ingredients = {{type = "item", name = input, amount = 1}},
    results = {{type = "item", name = output, amount = 1}},
    allow_productivity = false,
    maximum_productivity = 0,
  },
  machine,
  {
    type = "technology",
    name = "factorio-test-superlinear-cost-1",
    localised_name = "Superlinear cost experiment",
    icon = "__base__/graphics/technology/research-speed.png",
    icon_size = 256,
    enabled = false,
    visible_when_disabled = false,
    upgrade = true,
    max_level = "infinite",
    effects = {{
      type = "change-recipe-productivity",
      recipe = "factorio-test-productivity-allowed",
      change = 0.01,
    }},
    unit = {
      count_formula = "10*L^2",
      ingredients = {{"nullius-geology-pack", 1}},
      time = 1,
    },
  },
})

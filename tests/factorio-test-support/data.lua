local category = "factorio-test-innate-productivity"
local input = "factorio-test-productivity-input"
local output = "factorio-test-productivity-output"
local family_primary = "factorio-test-family-primary"
local family_additional = "factorio-test-family-additional"

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
  {type = "recipe-category", name = family_primary},
  {type = "recipe-category", name = family_additional},
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
  {
    type = "recipe",
    name = "factorio-test-family-a-primary",
    enabled = false,
    hidden = true,
    category = family_primary,
    ingredients = {{type = "item", name = input, amount = 1}},
    results = {{type = "item", name = output, amount = 1}},
  },
  {
    type = "recipe",
    name = "factorio-test-family-b-additional",
    enabled = false,
    hidden = true,
    category = category,
    additional_categories = {family_additional},
    ingredients = {{type = "item", name = input, amount = 1}},
    results = {{type = "item", name = output, amount = 1}},
  },
  {
    type = "recipe",
    name = "factorio-test-family-c-both",
    enabled = false,
    hidden = true,
    category = family_primary,
    additional_categories = {family_additional},
    ingredients = {{type = "item", name = input, amount = 1}},
    results = {{type = "item", name = output, amount = 1}},
  },
  {
    type = "recipe",
    name = "factorio-test-family-d-zero-cap",
    enabled = false,
    hidden = true,
    category = family_primary,
    maximum_productivity = 0,
    ingredients = {{type = "item", name = input, amount = 1}},
    results = {{type = "item", name = output, amount = 1}},
  },
  {
    type = "recipe",
    name = "factorio-test-family-e-unrelated",
    enabled = false,
    hidden = true,
    category = category,
    ingredients = {{type = "item", name = input, amount = 1}},
    results = {{type = "item", name = output, amount = 1}},
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

local family_generator =
  require("__nullius-star__/prototypes/recipe-productivity")
local family_effects = family_generator.effects(
  {family_additional, family_primary}, 0.01)
local expected_family_recipes = {
  "factorio-test-family-a-primary",
  "factorio-test-family-b-additional",
  "factorio-test-family-c-both",
}

assert(#family_effects == #expected_family_recipes,
  "recipe family generator selected an unexpected number of recipes")
for index, expected_recipe in ipairs(expected_family_recipes) do
  local effect = family_effects[index]
  assert(effect.type == "change-recipe-productivity",
    "recipe family generator emitted an unexpected effect type")
  assert(effect.recipe == expected_recipe,
    "recipe family generator order mismatch at index " .. index)
  assert(effect.change == 0.01,
    "recipe family generator emitted an unexpected change")
end

data:extend({{
  type = "technology",
  name = "factorio-test-recipe-productivity-family",
  localised_name = "Recipe productivity family test",
  icon = "__base__/graphics/technology/research-speed.png",
  icon_size = 256,
  enabled = false,
  visible_when_disabled = false,
  effects = family_effects,
  unit = {
    count = 1,
    ingredients = {{"nullius-geology-pack", 1}},
    time = 1,
  },
}})

-- Pneumatic roboport experiment fixtures.  The port's electric buffer cannot
-- accept grid power; the scenario supplies it from the colocated fluid store.
local pneumatic_roboport = table.deepcopy(data.raw.roboport["nullius-hangar-1"])
pneumatic_roboport.name = "factorio-test-pneumatic-roboport"
pneumatic_roboport.localised_name = "Pneumatic roboport experiment"
pneumatic_roboport.flags = {"placeable-off-grid", "not-on-map"}
pneumatic_roboport.minable = nil
pneumatic_roboport.fast_replaceable_group = nil
pneumatic_roboport.next_upgrade = nil
pneumatic_roboport.collision_mask = {layers = {}}
pneumatic_roboport.energy_source.input_flow_limit = "0W"
pneumatic_roboport.hidden_in_factoriopedia = true

local pneumatic_reservoir = table.deepcopy(data.raw["storage-tank"]["storage-tank"])
pneumatic_reservoir.name = "factorio-test-pneumatic-roboport-reservoir"
pneumatic_reservoir.localised_name = "Pneumatic roboport experiment reservoir"
pneumatic_reservoir.flags = {"placeable-off-grid", "not-on-map"}
pneumatic_reservoir.minable = nil
pneumatic_reservoir.fast_replaceable_group = nil
pneumatic_reservoir.next_upgrade = nil
pneumatic_reservoir.collision_box = {{0, 0}, {0, 0}}
pneumatic_reservoir.collision_mask = {layers = {}}
pneumatic_reservoir.selection_box = nil
pneumatic_reservoir.fluid_box.pipe_connections = {}
pneumatic_reservoir.hidden_in_factoriopedia = true

data:extend({pneumatic_roboport, pneumatic_reservoir})

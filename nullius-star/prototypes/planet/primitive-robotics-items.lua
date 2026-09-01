local function item(name, template, subgroup, order, stack_size)
  return {
    type = "item",
    name = name,
    localised_name = {"entity-name." .. name},
    localised_description = {"entity-description." .. name},
    icons = table.deepcopy(data.raw.item[template].icons),
    subgroup = subgroup,
    order = order,
    place_result = name,
    stack_size = stack_size,
  }
end

local function recipe(name, category, energy_required, ingredients)
  return {
    type = "recipe",
    name = name,
    localised_name = {"entity-name." .. name},
    enabled = false,
    always_show_made_in = true,
    category = category,
    energy_required = energy_required,
    ingredients = ingredients,
    results = {{type = "item", name = name, amount = 1}},
  }
end

data:extend({
  item("nullius-clockwork-roboport", "nullius-hangar-1",
    "hangar-2", "nullius-ba", 20),
  item("nullius-clockwork-logistic-robot", "nullius-logistic-bot-1",
    "robot", "nullius-ca", 20),
  item("nullius-primitive-storage-chest", "nullius-small-storage-chest-1",
    "small-logistic-storage", "nullius-aa", 100),
  item("nullius-primitive-supply-chest", "nullius-small-supply-chest-1",
    "small-logistic-storage", "nullius-ab", 100),
  item("nullius-primitive-demand-chest", "nullius-small-demand-chest-1",
    "small-logistic-storage", "nullius-ac", 100),

  recipe("nullius-clockwork-roboport", "medium-crafting", 8, {
    {type = "item", name = "nullius-iron-plate", amount = 12},
    {type = "item", name = "nullius-aluminum-plate", amount = 8},
    {type = "item", name = "nullius-iron-gear", amount = 8},
    {type = "item", name = "nullius-aluminum-rod", amount = 4},
  }),
  recipe("nullius-clockwork-logistic-robot", "tiny-crafting", 2, {
    {type = "item", name = "nullius-iron-gear", amount = 1},
    {type = "item", name = "nullius-iron-rod", amount = 1},
    {type = "item", name = "nullius-aluminum-sheet", amount = 1},
  }),
  recipe("nullius-primitive-storage-chest", "medium-crafting", 2, {
    {type = "item", name = "nullius-iron-plate", amount = 3},
    {type = "item", name = "nullius-aluminum-plate", amount = 3},
  }),
  recipe("nullius-primitive-supply-chest", "medium-crafting", 2, {
    {type = "item", name = "nullius-iron-plate", amount = 2},
    {type = "item", name = "nullius-iron-gear", amount = 1},
  }),
  recipe("nullius-primitive-demand-chest", "medium-crafting", 2, {
    {type = "item", name = "nullius-aluminum-plate", amount = 2},
    {type = "item", name = "nullius-iron-gear", amount = 1},
  }),
})

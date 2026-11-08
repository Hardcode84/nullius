-- Box weight fixtures for experiment-rocket-cargo-weights. One content item
-- with a declared weight, boxed five to a box by three packaging recipes that
-- differ only in productivity support and weight coefficient. Weight
-- calculation ignores hidden and non-decomposable recipes, so the items and
-- recipes stay visible; a nullius order keeps them out of the vanilla hiding
-- pass.
local content = "factorio-test-box-content"

local function item(name, stack_size, extra)
  local prototype = {
    type = "item",
    name = name,
    localised_name = name,
    icon = "__base__/graphics/icons/wooden-chest.png",
    icon_size = 64,
    hidden_in_factoriopedia = true,
    order = "nullius-zz-test-" .. name,
    stack_size = stack_size,
  }
  for key, value in pairs(extra or {}) do prototype[key] = value end
  return prototype
end

local function box(name, recipe_fields, item_fields)
  local recipe = {
    type = "recipe",
    name = name,
    enabled = false,
    hidden = false,
    allow_decomposition = true,
    order = "nullius-zz-test-" .. name,
    categories = {"packaging"},
    energy_required = 1,
    ingredients = {{type = "item", name = content, amount = 20}},
    results = {{type = "item", name = name, amount = 4}},
  }
  for key, value in pairs(recipe_fields) do recipe[key] = value end
  return {item(name, 50, item_fields), recipe}
end

local prototypes = {item(content, 100, {weight = 1000})}
for _, pair in ipairs({
  box("factorio-test-box-clamped", {allow_productivity = false}),
  box("factorio-test-box-uncapped", {allow_productivity = true, maximum_productivity = 0}),
  box("factorio-test-box-equal", {allow_productivity = true, maximum_productivity = 0},
    {ingredient_to_weight_coefficient = 1}),
}) do
  for _, prototype in ipairs(pair) do prototypes[#prototypes + 1] = prototype end
end
data:extend(prototypes)

-- A product computed below one gram: two 1 g items make three products, so
-- the floored intermediate weight is zero.
data:extend({
  item("factorio-test-light-content", 100, {weight = 1}),
  item("factorio-test-light-product", 200),
  {
    type = "recipe",
    name = "factorio-test-light-product",
    enabled = false,
    hidden = false,
    allow_decomposition = true,
    order = "nullius-zz-test-factorio-test-light-product",
    categories = {"packaging"},
    energy_required = 1,
    ingredients = {{type = "item", name = "factorio-test-light-content", amount = 2}},
    results = {{type = "item", name = "factorio-test-light-product", amount = 3}},
  },
})

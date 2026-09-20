local modern = string.match(mods.base, "^2%.1%.") ~= nil
local primary = "factorio-test-family-primary"
local additional = "factorio-test-family-additional"
local unrelated = "factorio-test-family-unrelated"
data:extend({
  {type="recipe-category", name=primary},
  {type="recipe-category", name=additional},
  {type="recipe-category", name=unrelated},
})
local cases = {
  {name="a-primary", categories={primary}},
  {name="b-additional", categories={unrelated, additional}},
  {name="c-both", categories={primary, additional}},
  {name="d-zero-cap", categories={primary}, cap=0},
  {name="e-unrelated", categories={unrelated}},
}
for _, case in ipairs(cases) do
  local recipe = {
    type="recipe", name="factorio-test-family-" .. case.name,
    enabled=false, maximum_productivity=case.cap,
    ingredients={{type="item", name="iron-plate", amount=1}},
    results={{type="item", name="copper-plate", amount=1}},
  }
  if modern then
    recipe.categories = case.categories
  else
    recipe.category = case.categories[1]
    if case.categories[2] then recipe.additional_categories = {case.categories[2]} end
  end
  data:extend({recipe})
end
local family = require("__nullius-star__/prototypes/recipe-productivity")
local effects = family.effects({additional, primary}, 0.01)
assert(#effects == 3, "expected three recipe-family effects, got " .. #effects)
for index, name in ipairs({"a-primary", "b-additional", "c-both"}) do
  assert(effects[index].recipe == "factorio-test-family-" .. name,
    "recipe family must be sorted and contain no duplicates")
end
data:extend({{
  type="technology", name="factorio-test-recipe-productivity-family",
  icon="__base__/graphics/technology/research-speed.png", icon_size=256,
  effects=effects,
  unit={count=1, ingredients={{"automation-science-pack", 1}}, time=1},
}})

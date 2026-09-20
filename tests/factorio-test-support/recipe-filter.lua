local modern = string.match(mods.base, "^2%.1%.") ~= nil
if not data.raw["recipe-category"]["ee-testing-tool"] then
  data:extend({{type="recipe-category", name="ee-testing-tool"}})
end
local fixtures = {
  {"factorio-test-filter-foreign"},
  {"nullius-filter-native"},
  {"factorio-test-filter-order", order="nullius-filter"},
  {"fill-nullius-filter"},
  {"empty-nullius-filter"},
  {"bpsb-filter"},
  {"factorio-test-filter-primary", categories={"ee-testing-tool"}},
  {"factorio-test-filter-additional", categories={"crafting", "ee-testing-tool"}},
  {"factorio-test-filter-multiple", categories={"crafting", "advanced-crafting"}},
  {"nullius-broken-filter"},
}
for _, fixture in ipairs(fixtures) do
  local recipe = {type="recipe", name=fixture[1], order=fixture.order or "test",
    enabled=true, ingredients={{type="item", name="iron-plate", amount=1}},
    results={{type="item", name="copper-plate", amount=1}}}
  local categories = fixture.categories or {"crafting"}
  if modern then recipe.categories = categories
  else
    recipe.category = categories[1]
    if categories[2] then recipe.additional_categories = {categories[2]} end
  end
  data:extend({recipe})
end

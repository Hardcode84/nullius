local visibility = require("__nullius-star__/prototypes/recipe-visibility")
local fixtures = require("recipe-filter")
-- Match hidden.lua's item marking and cleanup around the recipe passes.
for _, fixture in ipairs(fixtures) do
  local recipe = data.raw.recipe[fixture[1]]
  local product = data.raw.item[recipe.results[1].name]
  product.flags = {"temphidden"}
  visibility.hide(recipe, data.raw)
  if visibility.unmark(product) then product.hidden = true end
  visibility.restrict(recipe)
end
for _, name in ipairs({"factorio-test-filter-primary", "factorio-test-filter-additional"}) do
  assert(not data.raw.recipe[name].hidden, "testing-tool exemption lost: " .. name)
end
for _, name in ipairs({"fill-nullius-filter", "empty-nullius-filter"}) do
  assert(data.raw.recipe[name].GCKI_ignore == true, "barrel handling lost: " .. name)
end

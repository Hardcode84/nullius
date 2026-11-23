-- Silica in place of plastic, for planets without the organic chemistry that makes
-- plastic. Each planet applies these with its own surface condition and name suffix.
local recipe_util = require("prototypes.recipe-util")

local SUBSTITUTIONS = {
  {source = "nullius-motor-1", locale = "nullius-motor-vulcanus", order = "nullius-vb"},
  {source = "nullius-filter-1", locale = "nullius-filter-vulcanus", order = "nullius-vc", energy_required = 8},
}

-- Returns the substituted recipes for one planet.
return function(suffix, surface_conditions, overrides)
  local recipes = {}
  for _, spec in ipairs(SUBSTITUTIONS) do
    local recipe_overrides = table.deepcopy(overrides)
    recipe_overrides.localised_name = {"recipe-name." .. spec.locale}
    recipe_overrides.order = spec.order
    recipe_overrides.energy_required = spec.energy_required
    recipe_overrides.surface_conditions = table.deepcopy(surface_conditions)
    recipes[#recipes + 1] = recipe_util.substitute_recipe(spec.source, spec.source .. suffix, {
      ["nullius-plastic"] = {{type = "item", name = "nullius-silica", amount = 2}},
    }, recipe_overrides)
  end
  return recipes
end

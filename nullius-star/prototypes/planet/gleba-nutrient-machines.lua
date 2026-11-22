-- Nutrient machine variants for Gleba.
-- Generated after data-updates so copied entities keep final Nullius stats and names.
local mode_variant = require("prototypes.mode-variant")

for _, spec in ipairs(require("shared.gleba-machines")) do
  local base = assert(data.raw[spec.type][spec.name], "Missing Gleba base machine: " .. spec.name)
  local machine = mode_variant(base, "-nutrient")
  machine.localised_name = {"entity-name.nullius-nutrient-mode",
    base.localised_name or {"entity-name." .. base.name}}
  machine.surface_conditions = {{property = "nullius-hydrogen-sulfide", min = 1}}
  machine.energy_source = {
    type = "burner", fuel_categories = {"nullius-nutrient"}, effectivity = 1,
    fuel_inventory_size = 1, burnt_inventory_size = 1,
  }
  if spec.category then
    table.insert(machine.crafting_categories, spec.category)
  end
  -- A fixed recipe ignores recipe surface conditions, so the mode selects it.
  if spec.fixed_recipe then
    machine.fixed_recipe = spec.fixed_recipe
  end
  data:extend({machine})
end

-- Nutrient machine variants for Gleba.
-- Generated after data-updates so copied entities keep final Nullius stats and names.
for _, spec in ipairs(require("shared.gleba-machines")) do
  local base = assert(data.raw[spec.type][spec.name], "Missing Gleba base machine: " .. spec.name)
  local machine = table.deepcopy(base)
  machine.name = base.name .. "-nutrient"
  machine.localised_name = {"entity-name.nullius-nutrient-mode",
    base.localised_name or {"entity-name." .. base.name}}
  machine.placeable_by = {item = base.minable and base.minable.result or base.name, count = 1}
  machine.fast_replaceable_group = base.fast_replaceable_group or base.name
  base.fast_replaceable_group = machine.fast_replaceable_group
  machine.next_upgrade = nil
  machine.hidden = true
  machine.surface_conditions = {{property = "nullius-hydrogen-sulfide", min = 1}}
  machine.energy_source = {
    type = "burner", fuel_categories = {"nullius-nutrient"}, effectivity = 1,
    fuel_inventory_size = 1, burnt_inventory_size = 1,
  }
  if spec.category then
    machine.crafting_categories = table.deepcopy(machine.crafting_categories or {})
    table.insert(machine.crafting_categories, spec.category)
  end
  data:extend({machine})
end

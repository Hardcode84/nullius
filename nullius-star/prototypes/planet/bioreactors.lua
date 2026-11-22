-- Bioreactor modes of chemical and hydro plants. Generated after data-updates so
-- copied machines keep final Nullius stats, as the other mode variants are.
local bioreactors = require("shared.bioreactors")
local productivity = require("thermal-machine-config").productivity
local mode_variant = require("prototypes.mode-variant")
local tint_graphics = require("prototypes.tint-graphics")
local tint = {r = 0.7, g = 1, b = 0.55}

for _, spec in ipairs(bioreactors.specs) do
  local base = assert(data.raw["assembling-machine"][spec.base], "Missing bioreactor base: " .. spec.base)
  local machine = mode_variant(base, "-bioreactor")
  local power = bioreactors.power[spec.tier]
  machine.localised_name = {"entity-name.nullius-bioreactor",
    base.localised_name or {"entity-name." .. base.name}}
  machine.localised_description = {"entity-description.nullius-bioreactor",
    tostring(productivity[spec.tier] * 100), tostring(power)}
  machine.energy_usage = tostring(util.parse_energy(base.energy_usage) * 60 * power) .. "W"
  machine.energy_source = {
    type = "burner", fuel_categories = {"nullius-nutrient"}, effectivity = 1,
    fuel_inventory_size = 1, burnt_inventory_size = 1,
  }
  if spec.category then
    table.insert(machine.crafting_categories, spec.category)
  end
  machine.effect_receiver = machine.effect_receiver or {}
  machine.effect_receiver.base_effect = machine.effect_receiver.base_effect or {}
  machine.effect_receiver.base_effect.productivity = productivity[spec.tier]
  tint_graphics(machine, tint)
  data:extend({machine})
end

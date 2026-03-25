require("prototypes.override_final")
require("prototypes.override_final_only")
require("prototypes.override_mod_final")
require("prototypes.item.module_limitation")
require("prototypes.item.box_icons")
require("prototypes.custom_tooltip_fields")
require("legacyMirror")

for _, recipe in pairs(data.raw.recipe) do
    if recipe.GCKI_ignore ~= nil then
        recipe.GCKI_ignore = nil
    end
end

require("clutterpedia")

if settings.startup["nullius-hide-recipe-signals"].value then
    for _,recipe in pairs(data.raw.recipe) do
        --recipe.hide_from_signal_gui = true
        if recipe.hide_from_signal_gui == false then
            recipe.hide_from_signal_gui = nil
        end
    end
else
    for _,recipe in pairs(data.raw.recipe) do
        if string.sub(recipe.name, 1, 14) == "nullius-boxed-" or string.sub(recipe.name, 1, 14) == "nullius-unbox-" then
            recipe.hide_from_signal_gui = false
        end
    end
end

data.raw["utility-constants"]["default"].main_menu_simulations = require("menu-simulations.menu-simulations")

-- Gut SA's vanilla planet definitions. Cannot delete (refs break), so
-- strip their map gen to prevent decorative errors and hide them.
for _, planet_name in pairs({"vulcanus", "fulgora", "gleba", "aquilo"}) do
  if data.raw.planet[planet_name] then
    data.raw.planet[planet_name].hidden = true
    data.raw.planet[planet_name].map_gen_settings = { no_enemies_mode = true }
  end
end

-- Neuter quality and recycling. SA forces quality mod to load, but
-- Nullius* does not use quality. Disable at prototype level.

-- Hide and disable all recycling recipes (don't delete -- SA refs break).
for name, recipe in pairs(data.raw.recipe) do
  if string.find(name, "%-recycling$") then
    recipe.hidden = true
    recipe.enabled = false
  end
end

-- Disable quality on all recipes.
for _, recipe in pairs(data.raw.recipe) do
  recipe.allow_quality = false
end

-- Flatten all quality tiers.
for _, quality in pairs(data.raw.quality) do
  quality.next_probability = 0
  quality.default_multiplier = 1
  quality.crafting_machine_speed_multiplier = 1
  quality.crafting_machine_energy_usage_multiplier = 1
  quality.inserter_speed_multiplier = 1
  quality.inventory_size_multiplier = 1
  quality.lab_research_speed_multiplier = 1
  quality.mining_drill_resource_drain_multiplier = 1
  quality.science_pack_drain_multiplier = 1
  quality.tool_durability_multiplier = 1
  quality.range_multiplier = 1
  quality.beacon_power_usage_multiplier = 1
  quality.fluid_wagon_capacity_multiplier = 1
  quality.flying_robot_max_energy_multiplier = 1
  quality.accumulator_capacity_multiplier = 1
end

-- Hide quality modules.
for _, module in pairs(data.raw.module) do
  if module.effect and module.effect.quality then
    module.hidden = true
  end
end

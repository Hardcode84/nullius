-- Antiproton capture: platform collectors fill empty traps in Fulgora orbit,
-- and electrolyzers recharge filled traps before they spoil. The Fulgora
-- orbit gate is scripted in scripts/antiproton.lua.

local NAME = "nullius-antiproton-collector"
local CATEGORY = "nullius-antiproton-capture"

local collector = table.deepcopy(data.raw["assembling-machine"]["electromagnetic-plant"])
collector.name = NAME
collector.minable = {mining_time = 1, result = NAME}
collector.fast_replaceable_group = nil
collector.next_upgrade = nil
collector.crafting_categories = {CATEGORY}
collector.crafting_speed = 1
collector.fixed_recipe = "nullius-antiproton-capture"
-- A fixed recipe works without research unless this is set.
collector.disabled_when_recipe_not_researched = true
collector.fluid_boxes = nil
collector.heating_energy = nil
collector.energy_usage = "1MW"
collector.module_slots = 0
collector.allowed_effects = {}
-- The source machine has innate productivity; captured antimatter has none.
collector.effect_receiver = {uses_module_effects = false, uses_beacon_effects = false, uses_surface_effects = false}
-- Vacuum only, as the vanilla asteroid collector: platforms, not planets.
collector.surface_conditions = {{property = "pressure", min = 0, max = 0}}

data:extend({
  {type = "recipe-category", name = CATEGORY},
  {
    type = "item",
    name = NAME,
    icon = "__space-age__/graphics/icons/electromagnetic-plant.png",
    icon_size = 64,
    place_result = NAME,
    subgroup = "nuclear",
    order = "nullius-fa",
    stack_size = 10
  },
  collector,
  {
    type = "recipe",
    name = NAME,
    enabled = false,
    categories = {"large-crafting"},
    always_show_made_in = true,
    energy_required = 60,
    ingredients = {
      {type = "item", name = "nullius-steel-beam", amount = 10},
      {type = "item", name = "nullius-box-copper-wire", amount = 4},
      {type = "item", name = "nullius-processor-2", amount = 4},
      {type = "item", name = "nullius-sensor-2", amount = 2}
    },
    results = {{type = "item", name = NAME, amount = 1}}
  },
  {
    type = "recipe",
    name = "nullius-antiproton-capture",
    localised_name = {"recipe-name.nullius-antiproton-capture"},
    icon = "__nullius-star__/graphics/icons/antimatter.png",
    icon_size = 64,
    enabled = false,
    categories = {CATEGORY},
    subgroup = "nuclear",
    order = "nullius-fd",
    energy_required = 60,
    allow_productivity = false,
    maximum_productivity = 0,
    ingredients = {{type = "item", name = "nullius-antimatter-trap", amount = 1}},
    results = {{type = "item", name = "nullius-antimatter", amount = 1}}
  },
  {
    type = "recipe",
    name = "nullius-antimatter-recharge",
    localised_name = {"recipe-name.nullius-antimatter-recharge"},
    icon = "__nullius-star__/graphics/icons/antimatter.png",
    icon_size = 64,
    enabled = false,
    categories = {"nullius-electrolysis"},
    subgroup = "nuclear",
    order = "nullius-fe",
    energy_required = 10,
    -- A crafted product inherits its ingredient's spoilage unless it is
    -- always fresh, so only this flag resets the trap's timer.
    ingredients = {{type = "item", name = "nullius-antimatter", amount = 1}},
    results = {{type = "item", name = "nullius-antimatter", amount = 1, always_fresh = true, percent_spoiled = 0}}
  }
})

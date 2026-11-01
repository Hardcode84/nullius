-- Storm interference experiment: one runtime surface property scales native
-- lightning and gates a recipe through surface conditions.
local PROPERTY = "factorio-test-storm-intensity"
local CATEGORY = "factorio-test-storm-recording"

local property = {
  type = "surface-property",
  name = PROPERTY,
  localised_name = "Storm intensity experiment",
  default_value = 100,
  hidden = true,
}

local bolt = table.deepcopy(data.raw.lightning.lightning)
bolt.name = "factorio-test-storm-lightning"
bolt.localised_name = "Storm interference experiment strike"
-- 2.1 changed lightning damage from a number to DamagePrototype.
bolt.damage = {amount = 0, type = "electric"}
bolt.strike_effect = nil
bolt.attractor_hit_effect = nil
bolt.created_effect = {type = "direct", action_delivery = {type = "instant",
  target_effects = {type = "script", effect_id = "storm-interference-strike"}}}

local function planet(name, orientation)
  local result = table.deepcopy(data.raw.planet.nauvis)
  result.name = name
  result.localised_name = name
  result.map_gen_settings = {autoplace_controls = {}, autoplace_settings = {
    entity = {treat_missing_as_default = false, settings = {}},
    decorative = {treat_missing_as_default = false, settings = {}},
  }}
  result.distance = 100
  result.orientation = orientation
  result.surface_properties = table.deepcopy(result.surface_properties)
  result.surface_properties[PROPERTY] = 100
  -- Day and night multipliers stay neutral; only the property scales strikes.
  result.lightning_properties = {
    lightnings_per_chunk_per_tick = 1 / 60,
    search_radius = 1,
    lightning_types = {bolt.name},
    lightning_multiplier_at_day = 1,
    lightning_multiplier_at_night = 1,
    multiplier_surface_property = PROPERTY,
    priority_rules = {},
    exemption_rules = {},
  }
  return result
end

local machine = table.deepcopy(data.raw["assembling-machine"]["nullius-small-assembler-1"])
machine.name = "factorio-test-storm-recorder"
machine.localised_name = "Storm interference experiment recorder"
machine.flags = {"placeable-off-grid", "not-on-map"}
machine.minable = nil
machine.fast_replaceable_group = nil
machine.next_upgrade = nil
machine.crafting_categories = {CATEGORY}
machine.crafting_speed = 1
machine.energy_source = {type = "void"}
machine.energy_usage = "1W"
machine.module_slots = 0
machine.allowed_effects = {}
machine.effect_receiver = nil
machine.hidden_in_factoriopedia = true

data:extend({
  property, bolt,
  planet("factorio-test-storm-planet", 0.45),
  planet("factorio-test-storm-control-planet", 0.55),
  machine,
  {type = "recipe-category", name = CATEGORY},
  {
    type = "recipe",
    name = "factorio-test-storm-recording-long",
    enabled = true,
    hidden = true,
    categories = {CATEGORY},
    energy_required = 10,
    ingredients = {{type = "item", name = "factorio-test-storm-input", amount = 1}},
    results = {{type = "item", name = "factorio-test-storm-recording", amount = 1}},
  },
  {type = "item", name = "factorio-test-storm-input", hidden = true, stack_size = 1000,
    icon = "__base__/graphics/icons/iron-plate.png", icon_size = 64},
  {type = "item", name = "factorio-test-storm-recording", hidden = true, stack_size = 1000,
    icon = "__base__/graphics/icons/copper-plate.png", icon_size = 64},
  {
    type = "recipe",
    name = "factorio-test-storm-recording",
    enabled = true,
    hidden = true,
    categories = {CATEGORY},
    energy_required = 1,
    ingredients = {{type = "item", name = "factorio-test-storm-input", amount = 1}},
    results = {{type = "item", name = "factorio-test-storm-recording", amount = 1}},
    surface_conditions = {{property = PROPERTY, max = 50}},
  },
})

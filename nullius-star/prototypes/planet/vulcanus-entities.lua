-- Vulcanus-specific entities: lava intake variant of seawater intake.
-- Same item as seawater intake. Script swaps on placement when on Vulcanus.

data:extend({
  {
    type = "recipe-category",
    name = "nullius-lava-pumping",
  },
  {
    type = "recipe",
    name = "nullius-lava-pumping",
    localised_name = {"recipe-name.nullius-lava-pumping"},
    enabled = true,
    hide_from_player_crafting = true,
    category = "nullius-lava-pumping",
    energy_required = 1,
    ingredients = {},
    results = {
      {type = "fluid", name = "lava", amount = 125},
    },
    main_product = "lava",
  },
})

local si = data.raw["assembling-machine"]["nullius-seawater-intake-1"]
local lava_intake = table.deepcopy(si)
lava_intake.name = "nullius-lava-intake-1"
lava_intake.localised_name = {"entity-name.nullius-lava-intake"}
lava_intake.crafting_categories = {"nullius-lava-pumping"}
lava_intake.fixed_recipe = "nullius-lava-pumping"
lava_intake.fast_replaceable_group = si.fast_replaceable_group
lava_intake.next_upgrade = nil
lava_intake.hidden = true
lava_intake.fluid_boxes = {{
  production_type = "output",
  volume = 500,
  pipe_covers = pipecoverspictures(),
  filter = "lava",
  pipe_connections = {{position = {0, 1}, flow_direction = "output", direction = defines.direction.south}},
}}
-- Drops the seawater intake item when mined.
lava_intake.minable = {mining_time = 0.5, result = "nullius-seawater-intake-1"}
-- Allows placing via seawater intake item.
lava_intake.placeable_by = {item = "nullius-seawater-intake-1", count = 1}

data:extend({lava_intake})

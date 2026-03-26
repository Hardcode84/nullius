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

-- Vulcanus radiator: heat-powered chemistry building.
-- Absorbs heat from heat pipe network, processes HCl into useful products.
-- Two modes (toggle via Ctrl+R): Deacon (400C) and Cracking (650C).

local ENTITYPATH = "__nullius-star__/graphics/entity/"

local radiator_base = {
  type = "assembling-machine",
  flags = {"placeable-neutral", "player-creation"},
  max_health = 300,
  corpse = "solar-panel-remnants",
  collision_box = {{-2.25, -1.6}, {2.25, 1.6}},
  selection_box = {{-2.5, -2}, {2.5, 2}},
  crafting_speed = 1,
  module_slots = 0,
  graphics_set = {
    animation = {
      layers = {
        {
          filename = ENTITYPATH .. "collector/collector1.png",
          width = 220,
          height = 140,
          scale = 0.9,
          shift = {0, -0.25},
        },
        {
          filename = ENTITYPATH .. "collector/collectorpipe.png",
          width = 320,
          height = 32,
          scale = 0.5,
          shift = {0, 0.5},
        },
      },
    },
  },
  energy_usage = "1MW",
  resistances = {
    {type = "fire", decrease = 100, percent = 90},
    {type = "impact", decrease = 50, percent = 80},
  },
  surface_conditions = {{property = "gravity", min = 39}},
}

-- Deacon mode radiator (400C): HCl + O2 --> Cl2 + H2O.
local deacon = table.deepcopy(radiator_base)
deacon.name = "nullius-vulcanus-radiator-deacon"
deacon.localised_name = {"entity-name.nullius-vulcanus-radiator-deacon"}
deacon.icons = {{
  icon = "__base__/graphics/icons/heat-boiler.png",
  icon_size = 64,
}}
deacon.minable = {mining_time = 1, result = "nullius-vulcanus-radiator"}
deacon.fast_replaceable_group = "vulcanus-radiator"
deacon.crafting_categories = {"nullius-vulcanus-deacon"}
deacon.fixed_recipe = "nullius-vulcanus-deacon"
deacon.energy_source = {
  type = "heat",
  max_temperature = 1000,
  specific_heat = "500kJ",
  max_transfer = "5MW",
  min_working_temperature = 400,
  default_temperature = 15,
  connections = {
    {position = {2, 0.5}, direction = defines.direction.east},
    {position = {-2, 0.5}, direction = defines.direction.west},
  },
  pipe_covers = data.raw.boiler["heat-exchanger"].energy_source.pipe_covers,
  heat_pipe_covers = data.raw.boiler["heat-exchanger"].energy_source.heat_pipe_covers,
}
deacon.fluid_boxes = {
  {
    production_type = "input",
    volume = 200,
    pipe_connections = {{flow_direction = "input", direction = defines.direction.north, position = {0, -1}}},
  },
  {
    production_type = "input",
    volume = 200,
    pipe_connections = {{flow_direction = "input", direction = defines.direction.north, position = {1, -1}}},
  },
  {
    production_type = "output",
    volume = 200,
    pipe_connections = {{flow_direction = "output", direction = defines.direction.south, position = {0, 1}}},
  },
  {
    production_type = "output",
    volume = 200,
    pipe_connections = {{flow_direction = "output", direction = defines.direction.south, position = {1, 1}}},
  },
}

-- Cracking mode radiator (650C): HCl --> H2 + Cl2.
local cracking = table.deepcopy(deacon)
cracking.name = "nullius-vulcanus-radiator-cracking"
cracking.localised_name = {"entity-name.nullius-vulcanus-radiator-cracking"}
cracking.crafting_categories = {"nullius-vulcanus-cracking"}
cracking.fixed_recipe = "nullius-vulcanus-cracking"
cracking.hidden = true
cracking.energy_source.min_working_temperature = 650

data:extend({
  deacon,
  cracking,
  -- Radiator item (shared between both modes).
  {
    type = "item",
    name = "nullius-vulcanus-radiator",
    localised_name = {"item-name.nullius-vulcanus-radiator"},
    icons = deacon.icons,
    subgroup = "other",
    order = "nullius-vr",
    place_result = "nullius-vulcanus-radiator-deacon",
    stack_size = 10,
  },
  -- Recipe categories.
  {type = "recipe-category", name = "nullius-vulcanus-deacon"},
  {type = "recipe-category", name = "nullius-vulcanus-cracking"},
  -- Deacon recipe: 60 HCl + 15 O2 --> 30 Cl2 + 30 H2O.
  {
    type = "recipe",
    name = "nullius-vulcanus-deacon",
    localised_name = {"recipe-name.nullius-vulcanus-deacon"},
    icon = "__base__/graphics/icons/fluid/water.png",
    icon_size = 64,
    enabled = true,
    hide_from_player_crafting = true,
    category = "nullius-vulcanus-deacon",
    energy_required = 2,
    ingredients = {
      {type = "fluid", name = "nullius-hydrogen-chloride", amount = 60},
      {type = "fluid", name = "nullius-oxygen", amount = 15},
    },
    results = {
      {type = "fluid", name = "nullius-chlorine", amount = 30},
      {type = "fluid", name = "nullius-water", amount = 30},
    },
    main_product = "nullius-water",
  },
  -- Cracking recipe: 60 HCl --> 30 H2 + 30 Cl2.
  {
    type = "recipe",
    name = "nullius-vulcanus-cracking",
    localised_name = {"recipe-name.nullius-vulcanus-cracking"},
    icon = "__base__/graphics/icons/fluid/steam.png",
    icon_size = 64,
    enabled = true,
    hide_from_player_crafting = true,
    category = "nullius-vulcanus-cracking",
    energy_required = 2,
    ingredients = {
      {type = "fluid", name = "nullius-hydrogen-chloride", amount = 60},
    },
    results = {
      {type = "fluid", name = "nullius-hydrogen", amount = 30},
      {type = "fluid", name = "nullius-chlorine", amount = 30},
    },
    main_product = "nullius-hydrogen",
  },
  -- Radiator crafting recipe.
  {
    type = "recipe",
    name = "nullius-vulcanus-radiator",
    localised_name = {"item-name.nullius-vulcanus-radiator"},
    enabled = true,
    category = "medium-crafting",
    energy_required = 10,
    ingredients = {
      {type = "item", name = "nullius-iron-plate", amount = 8},
      {type = "item", name = "nullius-aluminum-sheet", amount = 4},
      {type = "item", name = "nullius-heat-pipe-1", amount = 4},
    },
    results = {
      {type = "item", name = "nullius-vulcanus-radiator", amount = 1},
    },
    surface_conditions = {{property = "gravity", min = 39}},
  },
})

-- Cracking radiator also drops the same item.
cracking.minable = {mining_time = 1, result = "nullius-vulcanus-radiator"}
cracking.placeable_by = {item = "nullius-vulcanus-radiator", count = 1}

-- Hidden heat interfaces for pneumatic machines.
-- Spawned alongside pneumatic machines to generate waste heat.
-- Temperature increased by script based on machine activity.
local heat_interface_sizes = {
  -- {name suffix, collision_box half-size, heat connection positions}
  {"small", 0.5, {
    {position = {0, 0}, direction = defines.direction.north},
    {position = {0, 0}, direction = defines.direction.south},
  }},
  {"medium", 1.0, {
    {position = {1, 0}, direction = defines.direction.east},
    {position = {-1, 0}, direction = defines.direction.west},
  }},
  {"large", 1.5, {
    {position = {1, 0}, direction = defines.direction.east},
    {position = {-1, 0}, direction = defines.direction.west},
  }},
}

for _, size_def in pairs(heat_interface_sizes) do
  local suffix, half, connections = size_def[1], size_def[2], size_def[3]
  data:extend({
    {
      type = "heat-interface",
      name = "nullius-pneumatic-heat-" .. suffix,
      localised_name = {"entity-name.nullius-pneumatic-heat"},
      flags = {"placeable-neutral", "not-blueprintable", "not-deconstructable",
               "not-on-map", "hide-alt-info", "not-upgradable"},
      icon = "__base__/graphics/icons/heat-interface.png",
      icon_size = 64,
      hidden = true,
      hidden_in_factoriopedia = true,
      max_health = 1,
      collision_box = {{-0.1, -0.1}, {0.1, 0.1}},
      collision_mask = {layers = {}},
      selection_box = {{-half, -half}, {half, half}},
      selectable_in_game = false,
      gui_mode = "none",
      picture = {
        filename = "__base__/graphics/icons/heat-interface.png",
        width = 64,
        height = 64,
        scale = 0.01,
      },
      heat_buffer = {
        max_temperature = 1000,
        specific_heat = "200kJ",
        max_transfer = "2MW",
        default_temperature = 15,
        minimum_glow_temperature = 0,
        connections = connections,
      },
    },
  })
end

for i = 1, 2 do
  local si = data.raw["assembling-machine"]["nullius-seawater-intake-" .. i]
  if si then
    local lava_intake = table.deepcopy(si)
    lava_intake.name = "nullius-lava-intake-" .. i
    lava_intake.localised_name = {"entity-name.nullius-lava-intake"}
    lava_intake.crafting_categories = {"nullius-lava-pumping"}
    lava_intake.fixed_recipe = "nullius-lava-pumping"
    lava_intake.fast_replaceable_group = si.fast_replaceable_group
    lava_intake.next_upgrade = (i < 2) and ("nullius-lava-intake-" .. (i + 1)) or nil
    lava_intake.hidden = true
    lava_intake.fluid_boxes = {{
      production_type = "output",
      volume = 500,
      pipe_covers = pipecoverspictures(),
      filter = "lava",
      pipe_connections = {{position = {0, 1}, flow_direction = "output", direction = defines.direction.south}},
    }}
    -- Drops the seawater intake item when mined.
    lava_intake.minable = {mining_time = 0.5, result = "nullius-seawater-intake-" .. i}
    -- Allows placing via seawater intake item.
    lava_intake.placeable_by = {item = "nullius-seawater-intake-" .. i, count = 1}

    data:extend({lava_intake})
  end
end

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
  {
    -- Resource category mined only by the hidden gas vent drill (see below).
    type = "resource-category",
    name = "nullius-gas-vent",
  },
  {
    -- Recipe category with no recipes: the gas-vent shell never crafts.
    type = "recipe-category",
    name = "nullius-gas-vent-shell",
  },
})

-- Vulcanus radiators: heat-powered chemistry buildings.
-- Absorb heat from heat pipe network to drive thermal fluid reactions.
-- Two tiers: low-temp (200C) for basic chemistry, high-temp (450C) for cracking.

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
  surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  fluid_boxes = {
    {
      production_type = "input",
      volume = 200,
      pipe_connections = {{flow_direction = "input", direction = defines.direction.north, position = {-1, -1.3}}},
    },
    {
      production_type = "input",
      volume = 200,
      pipe_connections = {{flow_direction = "input", direction = defines.direction.north, position = {1, -1.3}}},
    },
    {
      production_type = "output",
      volume = 200,
      pipe_connections = {{flow_direction = "output", direction = defines.direction.south, position = {-1, 1.3}}},
    },
    {
      production_type = "output",
      volume = 200,
      pipe_connections = {{flow_direction = "output", direction = defines.direction.south, position = {1, 1.3}}},
    },
  },
}

-- Low-temp radiator (200C): Deacon process, SO2 decomposition.
local low_temp = table.deepcopy(radiator_base)
low_temp.name = "nullius-vulcanus-radiator-1"
low_temp.localised_name = {"entity-name.nullius-vulcanus-radiator-1"}
low_temp.icons = {{
  icon = "__base__/graphics/icons/heat-boiler.png",
  icon_size = 64,
}}
low_temp.minable = {mining_time = 1, result = "nullius-vulcanus-radiator-1"}
low_temp.fast_replaceable_group = "vulcanus-radiator"
low_temp.crafting_categories = {"nullius-low-temp-radiator"}
low_temp.energy_source = {
  type = "heat",
  max_temperature = 250,
  specific_heat = "500kJ",
  max_transfer = "5MW",
  min_working_temperature = 200,
  default_temperature = 15,
  connections = {
    {position = {2, 0.5}, direction = defines.direction.east},
    {position = {-2, 0.5}, direction = defines.direction.west},
  },
  pipe_covers = data.raw.boiler["heat-exchanger"].energy_source.pipe_covers,
  heat_pipe_covers = data.raw.boiler["heat-exchanger"].energy_source.heat_pipe_covers,
}

-- High-temp radiator (450C): HCl cracking, carbochlorination. Can also do low-temp recipes.
local high_temp = table.deepcopy(low_temp)
high_temp.name = "nullius-vulcanus-radiator-2"
high_temp.localised_name = {"entity-name.nullius-vulcanus-radiator-2"}
high_temp.icons = {{
  icon = "__base__/graphics/icons/heat-boiler.png",
  icon_size = 64,
  tint = {255, 180, 100},
}}
high_temp.minable = {mining_time = 1, result = "nullius-vulcanus-radiator-2"}
high_temp.crafting_categories = {"nullius-low-temp-radiator", "nullius-high-temp-radiator"}
high_temp.energy_source.min_working_temperature = 450
high_temp.energy_source.max_temperature = 500

data:extend({
  low_temp,
  high_temp,
  -- Recipe categories.
  {type = "recipe-category", name = "nullius-low-temp-radiator"},
  {type = "recipe-category", name = "nullius-high-temp-radiator"},
  -- Low-temp radiator item.
  {
    type = "item",
    name = "nullius-vulcanus-radiator-1",
    localised_name = {"item-name.nullius-vulcanus-radiator-1"},
    icons = low_temp.icons,
    subgroup = "other",
    order = "nullius-vr1",
    place_result = "nullius-vulcanus-radiator-1",
    stack_size = 10,
  },
  -- High-temp radiator item.
  {
    type = "item",
    name = "nullius-vulcanus-radiator-2",
    localised_name = {"item-name.nullius-vulcanus-radiator-2"},
    icons = high_temp.icons,
    subgroup = "other",
    order = "nullius-vr2",
    place_result = "nullius-vulcanus-radiator-2",
    stack_size = 10,
  },
  -- Deacon recipe: 60 HCl + 15 O2 --> 30 Cl2 + 30 H2O.
  {
    type = "recipe",
    name = "nullius-vulcanus-deacon",
    localised_name = {"recipe-name.nullius-vulcanus-deacon"},
    icon = "__base__/graphics/icons/fluid/water.png",
    icon_size = 64,
    enabled = true,
    hide_from_player_crafting = true,
    category = "nullius-low-temp-radiator",
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
    category = "nullius-high-temp-radiator",
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
  -- Low-temp radiator crafting recipe.
  {
    type = "recipe",
    name = "nullius-vulcanus-radiator-1",
    localised_name = {"item-name.nullius-vulcanus-radiator-1"},
    enabled = true,
    category = "medium-crafting",
    energy_required = 10,
    ingredients = {
      {type = "item", name = "nullius-iron-plate", amount = 8},
      {type = "item", name = "nullius-silica", amount = 4},
      {type = "item", name = "pipe", amount = 4},
    },
    results = {
      {type = "item", name = "nullius-vulcanus-radiator-1", amount = 1},
    },
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },
  -- High-temp radiator crafting recipe.
  {
    type = "recipe",
    name = "nullius-vulcanus-radiator-2",
    localised_name = {"item-name.nullius-vulcanus-radiator-2"},
    enabled = true,
    category = "medium-crafting",
    energy_required = 15,
    ingredients = {
      {type = "item", name = "nullius-vulcanus-radiator-1", amount = 1},
      {type = "item", name = "nullius-aluminum-sheet", amount = 8},
      {type = "item", name = "nullius-silica", amount = 8},
      {type = "item", name = "nullius-heat-pipe-1", amount = 1},
      {type = "item", name = "nullius-pipe-2", amount = 4},
    },
    results = {
      {type = "item", name = "nullius-vulcanus-radiator-2", amount = 1},
    },
    surface_conditions = {{property = "nullius-ambient-temperature", min = 100}},
  },
})


-- Hidden heat interfaces for pneumatic machines.
local vulcanus_util = require("prototypes.planet.vulcanus-util")
local make_heat_connections = vulcanus_util.make_heat_connections

local heat_interface_sizes = {
  {"small", 1.0, make_heat_connections(0.8)},
  {"medium", 1.5, make_heat_connections(1.4)},
  {"medium2", 1.9, make_heat_connections(1.8)},
  {"large", 2.5, make_heat_connections(2.4)},
}

for _, size_def in pairs(heat_interface_sizes) do
  local suffix, half, connections = size_def[1], size_def[2], size_def[3]
  data:extend({
    {
      type = "heat-interface",
      name = "nullius-pneumatic-heat-" .. suffix,
      localised_name = {"entity-name.nullius-pneumatic-heat"},
      flags = {"placeable-neutral", "player-creation", "not-blueprintable"},
      icon = "__base__/graphics/icons/heat-interface.png",
      icon_size = 64,
      hidden_in_factoriopedia = true,
      max_health = 1,
      collision_box = {{-half, -half}, {half, half}},
      collision_mask = {layers = {}},
      selectable_in_game = false,
      gui_mode = "none",
      heat_buffer = {
        max_temperature = 500,
        specific_heat = "200kJ",
        max_transfer = "2MW",
        default_temperature = 15,
        minimum_glow_temperature = 0,
        connections = connections,
        pipe_covers = data.raw.boiler["heat-exchanger"].energy_source.pipe_covers,
        heat_pipe_covers = data.raw.boiler["heat-exchanger"].energy_source.heat_pipe_covers,
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
    -- Free/void powered. A shore intake can't practically take gas on its lava
    -- side (pipes cannot be placed on lava), and bootstrap has no electricity.
    lava_intake.energy_source = {type = "void"}
    lava_intake.energy_usage = "1W"
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

    -- Pneumatic lava intake: gas-powered instead of electric. Keeps the lava
    -- output (south); adds a compressed-gas input on the north edge.
    local lava_pneumatic = table.deepcopy(lava_intake)
    lava_pneumatic.name = "nullius-lava-intake-" .. i .. "-pneumatic"
    lava_pneumatic.localised_name = {"entity-name.nullius-lava-intake"}
    lava_pneumatic.next_upgrade = nil
    lava_pneumatic.energy_source = {
      type = "fluid",
      burns_fluid = true,
      scale_fluid_usage = true,
      fluid_usage_per_tick = 1,
      fluid_box = {
        volume = 200,
        pipe_connections = {{
          flow_direction = "input",
          direction = defines.direction.north,
          position = {0, -1},
        }},
      },
    }
    data:extend({lava_pneumatic})

    -- Free-gas vent SHELL: the intake's Ctrl+R alternate mode. This is a cosmetic
    -- assembling machine (never crafts) that is just the intake re-skinned -- so
    -- it places and blueprints/copy-pastes exactly like the intake (NOT a mining
    -- drill, so blueprint ghosts don't need a resource under them first). When it
    -- is built, vulcanus_gasvent.lua spawns a hidden mining-drill + invisible gas
    -- resource under it; the drill does the actual venting and the engine meters
    -- output at resource.amount/NORMAL (throttle = NORMAL/sqrt(N)). This mirrors
    -- Space Exploration 0.5's core miner composite setup.
    local lava_gasvent = table.deepcopy(lava_intake)
    lava_gasvent.name = "nullius-lava-intake-" .. i .. "-gasvent"
    lava_gasvent.localised_name = {"entity-name.nullius-lava-gasvent"}
    lava_gasvent.placeable_by = {item = "nullius-seawater-intake-" .. i, count = 1}
    lava_gasvent.next_upgrade = nil
    lava_gasvent.energy_source = {type = "void"}
    -- Never crafts: a recipe category with no recipes. The hidden drill vents gas.
    lava_gasvent.crafting_categories = {"nullius-gas-vent-shell"}
    lava_gasvent.fixed_recipe = nil
    -- The hidden drill owns the physical output. Duplicating that connection on
    -- the overlapping shell creates two independent fluid boxes and traps the
    -- mined gas in the drill instead of connecting it to the player's pipe.
    lava_gasvent.fluid_boxes = {}
    data:extend({lava_gasvent})
  end
end

-- Hidden gas-vent drill: void-energy fluid mining-drill spawned by the script
-- under each gas-vent shell. Invisible and intangible (the shell is what the
-- player sees/clicks/blueprints); it mines the gas seam and outputs gas to the
-- south pipe, exactly where the shell's lava output used to be.
local gas_vent_drill = table.deepcopy(data.raw["mining-drill"]["nullius-extractor-1"])
gas_vent_drill.name = "nullius-gas-vent-drill"
gas_vent_drill.localised_name = {"entity-name.nullius-lava-gasvent"}
gas_vent_drill.flags = {"placeable-off-grid", "not-on-map", "not-blueprintable", "not-deconstructable", "hide-alt-info"}
gas_vent_drill.hidden = true
gas_vent_drill.selectable_in_game = false
gas_vent_drill.minable = nil
gas_vent_drill.next_upgrade = nil
gas_vent_drill.fast_replaceable_group = nil
-- Box must contain the south pipe connection ({0,1}); collision_mask is empty so
-- it blocks nothing and can overlap both the shell and shore/lava tiles.
gas_vent_drill.collision_box = data.raw["assembling-machine"]["nullius-lava-intake-1"].collision_box
gas_vent_drill.collision_mask = {layers = {}}
gas_vent_drill.selection_box = nil
gas_vent_drill.graphics_set = {}
gas_vent_drill.base_picture = nil
gas_vent_drill.radius_visualisation_picture = nil
gas_vent_drill.circuit_connector = nil
gas_vent_drill.monitor_visualization_tint = nil
gas_vent_drill.energy_source = {type = "void"}
gas_vent_drill.energy_usage = "100kW"
gas_vent_drill.module_slots = 0
gas_vent_drill.allowed_effects = {}
gas_vent_drill.resource_categories = {"nullius-gas-vent"}
gas_vent_drill.resource_searching_radius = 0.99
gas_vent_drill.vector_to_place_result = {0, 0}
gas_vent_drill.mining_speed = 1
gas_vent_drill.output_fluid_box = {
  volume = 1000,
  pipe_covers = pipecoverspictures(),
  filter = "nullius-compressed-volcanic-gas",
  pipe_connections = {{
    position = {0, 1},
    flow_direction = "output",
    direction = defines.direction.south,
  }},
}
data:extend({gas_vent_drill})

-- Invisible infinite gas resource mined by the hidden drill. No autoplace -- only
-- script-spawned under a shell. infinite_depletion_amount = 0 means the engine
-- never changes its amount; vulcanus_gasvent.lua owns it and throttles output by
-- rewriting amount to NORMAL/sqrt(N). NORMAL here must match the runtime script.
data:extend({
  {
    type = "resource",
    name = "nullius-gas-vent-seam",
    category = "nullius-gas-vent",
    infinite = true,
    minimum = 1,
    normal = 1000000,
    infinite_depletion_amount = 0,
    minable = {
      mining_time = 1,
      results = {{type = "fluid", name = "nullius-compressed-volcanic-gas", amount = 12}},
    },
    -- Collisionless so it can be created under a shore/lava intake. Mining drills
    -- find resources by position/category, not by resource-layer collision.
    collision_box = {{-1.3, -1.3}, {1.3, 1.3}},
    collision_mask = {layers = {}},
    selectable_in_game = false,
    highlight = false,
    map_grid = false,
    flags = {"placeable-off-grid", "not-on-map"},
    stage_counts = {0},
    stages = {sheet = {filename = "__core__/graphics/empty.png", width = 1, height = 1, variation_count = 1}},
  },
})

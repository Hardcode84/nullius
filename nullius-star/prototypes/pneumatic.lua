-- Pneumatic machine variants for Vulcanus.
-- For each registered machine, creates a "-pneumatic" variant that uses
-- FluidEnergySource (compressed volcanic gas) instead of electric.
-- Toggle between electric/pneumatic via Ctrl+R (same as priority toggle)
-- on Vulcanus surface only.

-- Compressed volcanic gas fluid.
data:extend({
  {
    type = "fluid",
    name = "nullius-compressed-volcanic-gas",
    icon = "__space-age__/graphics/icons/fluid/lava.png",
    icon_size = 64,
    subgroup = "compressed-air",
    order = "nullius-z",
    default_temperature = 400,
    max_temperature = 800,
    heat_capacity = "0.1kJ",
    fuel_value = "20kJ",
    base_color = {r = 0.8, g = 0.3, b = 0.1},
    flow_color = {r = 0.9, g = 0.4, b = 0.1},
    auto_barrel = false,
  },
})

-- List of machines to create pneumatic variants for.
-- Each entry: { name = "entity-name", type = "entity-type" }
-- The pneumatic variant will be named "entity-name-pneumatic".
local pneumatic_machines = {}

local function register_pneumatic(entity_type, entity_name, thermal)
  table.insert(pneumatic_machines, { name = entity_name, type = entity_type, thermal = thermal })
end

-- Register furnace tiers (thermal: heat-powered, not gas-powered).
for i = 1, 3 do
  register_pneumatic("assembling-machine", "nullius-small-furnace-" .. i, true)
end

-- Register foundry tiers (gas-powered, not thermal).
for i = 1, 3 do
  register_pneumatic("assembling-machine", "nullius-foundry-" .. i)
end

-- Register assembler tiers.
register_pneumatic("assembling-machine", "nullius-small-assembler-1")
register_pneumatic("assembling-machine", "nullius-small-assembler-2")
register_pneumatic("assembling-machine", "nullius-medium-assembler-1")
register_pneumatic("assembling-machine", "nullius-medium-assembler-2")

-- Register inserter (Nullius reuses bob-turbo-inserter as inserter-2).
register_pneumatic("inserter", "inserter")
register_pneumatic("inserter", "bob-turbo-inserter")

-- Register extractors (mining-drill type, for geysers).
register_pneumatic("mining-drill", "nullius-extractor-1")
register_pneumatic("mining-drill", "nullius-extractor-2")

-- Register air filters.
for i = 1, 3 do
  register_pneumatic("assembling-machine", "nullius-air-filter-" .. i)
end

-- Register chemistry buildings.
for i = 1, 3 do
  register_pneumatic("assembling-machine", "nullius-hydro-plant-" .. i)
  register_pneumatic("assembling-machine", "nullius-distillery-" .. i)
  register_pneumatic("assembling-machine", "nullius-chemical-plant-" .. i)
  register_pneumatic("assembling-machine", "nullius-surge-electrolyzer-" .. i)
  register_pneumatic("assembling-machine", "nullius-priority-electrolyzer-" .. i)
end

-- Register labs.
register_pneumatic("lab", "nullius-lab-1")

-- Generate pneumatic variants.
local pneumatic_pairs = {}  -- mapping: original name --> pneumatic name.

for _, entry in pairs(pneumatic_machines) do
  local original = data.raw[entry.type][entry.name]
  if original then
    local pneumatic_name = entry.name .. "-pneumatic"
    local pneumatic = table.deepcopy(original)
    pneumatic.name = pneumatic_name
    pneumatic.localised_name = original.localised_name or {"entity-name." .. entry.name}
    pneumatic.localised_description = {"", "[color=orange]Pneumatic mode[/color]\n",
      original.localised_description or {"entity-description." .. entry.name}}
    pneumatic.placeable_by = { item = original.minable and original.minable.result or entry.name, count = 1 }

    -- Same item drops when mined.
    if pneumatic.minable then
      -- Keep same result item as original.
    end

    -- Replace electric energy source with fluid energy source.
    -- Two pass-through connections so gas can flow through the machine.
    -- Pipe positions must be inside the collision box.
    -- For pass-through, place connections on opposite edges.
    local cb = pneumatic.collision_box or {{-0.7, -0.7}, {0.7, 0.7}}

    local half_h = math.abs(cb[1][2]) - 0.1
    local half_w = math.abs(cb[1][1]) - 0.1
    local off_h = 0
    local off_w = 0
    if half_h < 1 then
      off_h = half_h
    elseif half_h > 1.5 and half_h < 2.0 then
      off_h = 0.4
    end
    if half_w < 1 then
      off_w = half_w
    elseif half_w > 1.5 and half_w < 2.0 then
      off_w = 0.4
    end

    -- Check if entity has existing east/west fluid connections.
    local has_ew_fluid = false
    for _, fb in pairs(pneumatic.fluid_boxes or {}) do
      if type(fb) == "table" and fb.pipe_connections then
        for _, pc in pairs(fb.pipe_connections) do
          local dir = pc.direction
          if dir == defines.direction.east or dir == defines.direction.west then
            has_ew_fluid = true
            break
          end
        end
      end
      if has_ew_fluid then break end
    end

    local pipe_connections
    if has_ew_fluid then
      -- Entity uses east/west for recipe fluids, use north/south for energy.
      pipe_connections = {
        { flow_direction = "input-output", direction = defines.direction.north, position = {off_w, -half_h} },
        { flow_direction = "input-output", direction = defines.direction.south, position = {off_w, half_h} },
      }
    else
      -- Default: east/west pass-through.
      pipe_connections = {
        { flow_direction = "input-output", direction = defines.direction.east, position = {half_w, off_h} },
        { flow_direction = "input-output", direction = defines.direction.west, position = {-half_w, off_h} },
      }
    end

    if entry.thermal then
      -- Furnaces use heat energy source (thermal smelting from waste heat).
      local vulcanus_util = require("prototypes.planet.vulcanus-util")
      local cb_raw = pneumatic.collision_box or {{-0.7, -0.7}, {0.7, 0.7}}
      local heat_half = math.abs(cb_raw[1][1]) - 0.1
      if heat_half < 0.5 then heat_half = 0.8 end
      pneumatic.energy_source = {
        type = "heat",
        max_temperature = 500,
        specific_heat = "200kJ",
        max_transfer = "2MW",
        min_working_temperature = 100,
        default_temperature = 15,
        connections = vulcanus_util.make_heat_connections(heat_half),
        pipe_covers = data.raw.boiler["heat-exchanger"].energy_source.pipe_covers,
        heat_pipe_covers = data.raw.boiler["heat-exchanger"].energy_source.heat_pipe_covers,
      }
    else
      -- All other machines use gas (fluid energy source).
      pneumatic.energy_source = {
        type = "fluid",
        burns_fluid = true,
        scale_fluid_usage = true,
        fluid_usage_per_tick = 1,
        fluid_box = {
          volume = 200,
          pipe_connections = pipe_connections,
        },
        smoke = {{
          name = "smoke",
          frequency = 10,
          position = {0, -0.7},
          starting_vertical_speed = 0.08,
        }},
      }
    end

    -- Same fast_replaceable_group so toggle works.
    pneumatic.fast_replaceable_group = original.fast_replaceable_group or entry.name
    -- Make sure the original also has the same group.
    original.fast_replaceable_group = pneumatic.fast_replaceable_group

    -- Remove next_upgrade (pneumatic variant doesn't chain upgrades).
    pneumatic.next_upgrade = nil

    -- Surface condition: pneumatic mode only on Vulcanus.
    -- (Actually, the toggle script handles this, not the prototype.)

    -- Hidden from player crafting -- you don't craft pneumatic machines,
    -- you toggle existing ones.
    pneumatic.hidden = true

    data:extend({pneumatic})

    pneumatic_pairs[entry.name] = pneumatic_name
    pneumatic_pairs[pneumatic_name] = entry.name
  end
end

-- NOTE: The pneumatic_pairs mapping is duplicated in scripts/turbine.lua
-- because mod-data prototypes are not accessible at runtime.
-- Keep both lists in sync when adding new pneumatic machines.

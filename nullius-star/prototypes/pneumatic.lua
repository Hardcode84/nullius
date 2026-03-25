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

local function register_pneumatic(entity_type, entity_name)
  table.insert(pneumatic_machines, { name = entity_name, type = entity_type })
end

-- Register all furnace tiers.
for i = 1, 3 do
  register_pneumatic("furnace", "nullius-small-furnace-" .. i)
end

-- Register assembler tiers.
register_pneumatic("assembling-machine", "nullius-small-assembler-1")
register_pneumatic("assembling-machine", "nullius-small-assembler-2")
register_pneumatic("assembling-machine", "nullius-medium-assembler-1")
register_pneumatic("assembling-machine", "nullius-medium-assembler-2")

-- Register inserter (Nullius reuses bob-turbo-inserter as inserter-2).
register_pneumatic("inserter", "inserter")
register_pneumatic("inserter", "bob-turbo-inserter")

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
    local energy_usage_watts = pneumatic.energy_usage or "75kW"
    pneumatic.energy_source = {
      type = "fluid",
      burns_fluid = true,
      scale_fluid_usage = true,
      fluid_usage_per_tick = 1,
      fluid_box = {
        volume = 100,
        pipe_connections = {
          { flow_direction = "input-output", direction = defines.direction.north, position = {0, 0} },
        },
      },
      smoke = {{
        name = "smoke",
        frequency = 10,
        position = {0, -0.7},
        starting_vertical_speed = 0.08,
      }},
    }

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

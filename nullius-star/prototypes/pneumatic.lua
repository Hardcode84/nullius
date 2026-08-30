-- Pneumatic machine variants for Vulcanus.
-- For each registered machine, creates a "-pneumatic" variant that uses
-- FluidEnergySource (compressed volcanic gas) instead of electric.
-- Toggle between electric/pneumatic via Ctrl+R (same as priority toggle)
-- on Vulcanus surface only.

local pneumatic_families = require("shared.pneumatic-machine-families")

-- Compressed volcanic gas fluid.
data:extend({
  {
    type = "fluid",
    name = "nullius-compressed-volcanic-gas",
    icons = angelsLegacy.functions.create_gas_fluid_icon(nil,
      {element_tint["volcanic"], element_tint["air"], element_tint["volcanic"]}
    ),
    subgroup = "compressed-air",
    order = "nullius-z",
    default_temperature = 200,
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

local function register_pneumatic(entity_type, entity_name, gas_offset,
    gas_edge)
  table.insert(pneumatic_machines, {
    name = entity_name,
    type = entity_type,
    gas_offset = gas_offset,
    gas_edge = gas_edge,
  })
end

-- Register every ordinary assembler size and tier.
for _, name in ipairs(pneumatic_families.normal_assemblers(
    data.raw["assembling-machine"])) do
  register_pneumatic("assembling-machine", name)
end
for _, name in ipairs(pneumatic_families.barrel_pumps(
    data.raw["assembling-machine"])) do
  register_pneumatic("assembling-machine", name)
end
for _, name in ipairs(pneumatic_families.boxers(
    data.raw["furnace"])) do
  register_pneumatic("furnace", name)
end

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
  register_pneumatic("assembling-machine", "nullius-surge-compressor-" .. i)
  register_pneumatic("assembling-machine", "nullius-priority-compressor-" .. i)
end
register_pneumatic("assembling-machine", "nullius-flotation-cell-1", -0.5, 1.5)

-- Register labs.
register_pneumatic("lab", "nullius-lab-1")

-- Register pumps (gas-powered, no heat interface).
register_pneumatic("pump", "nullius-pump-1")
register_pneumatic("pump", "nullius-pump-2")
register_pneumatic("pump", "pump")
register_pneumatic("pump", "nullius-small-pump-1")
register_pneumatic("pump", "nullius-small-pump-2")

-- Register valves (togglable pumps, gas-powered).
register_pneumatic("pump", "nullius-togglable-pump-1")
register_pneumatic("pump", "nullius-togglable-pump-2")
register_pneumatic("pump", "nullius-togglable-pump-3")
register_pneumatic("pump", "nullius-togglable-small-pump-1")
register_pneumatic("pump", "nullius-togglable-small-pump-2")

-- Generate pneumatic variants.
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

    local occupied_connections = {}
    local function connection_key(direction, offset)
      return tostring(direction) .. ":" .. string.format("%.3f", offset)
    end

    -- Check which edges and lateral offsets recipe fluids already occupy.
    local has_ew_fluid = false
    for _, fb in pairs(pneumatic.fluid_boxes or {}) do
      if type(fb) == "table" and fb.pipe_connections then
        for _, pc in pairs(fb.pipe_connections) do
          local position = pc.position or
            (pc.positions and pc.positions[1]) or {0, 0}
          local dir = pc.direction
          if not dir then
            if math.abs(position[1]) > math.abs(position[2]) then
              dir = (position[1] > 0) and defines.direction.east or
                defines.direction.west
            else
              dir = (position[2] > 0) and defines.direction.south or
                defines.direction.north
            end
          end
          if dir == defines.direction.east or dir == defines.direction.west then
            has_ew_fluid = true
            occupied_connections[connection_key(dir, position[2])] = true
          elseif dir == defines.direction.north or
              dir == defines.direction.south then
            occupied_connections[connection_key(dir, position[1])] = true
          end
        end
      end
    end

    local function free_offset(direction, preferred, maximum)
      local candidates
      if math.abs(preferred % 1) > 0.001 then
        candidates = {preferred, -preferred, 0.5, -0.5, 1.5, -1.5}
      else
        candidates = {preferred, 0, 1, -1, 2, -2}
      end
      for _, candidate in ipairs(candidates) do
        if math.abs(candidate) <= maximum and
            not occupied_connections[connection_key(direction, candidate)] then
          return candidate
        end
      end
      error("No free pneumatic fluid connection for " .. entry.name)
    end

    local pipe_connections
    if has_ew_fluid then
      -- Entity uses east/west for recipe fluids, use north/south for energy.
      local north_offset = free_offset(defines.direction.north,
        entry.gas_offset or off_w, half_w)
      local south_offset = free_offset(defines.direction.south,
        entry.gas_offset or off_w, half_w)
      pipe_connections = {
        { flow_direction = "input-output", direction = defines.direction.north, position = {north_offset, -(entry.gas_edge or half_h)} },
        { flow_direction = "input-output", direction = defines.direction.south, position = {south_offset, entry.gas_edge or half_h} },
      }
    else
      -- Default: east/west pass-through.
      local east_offset = free_offset(defines.direction.east,
        entry.gas_offset or off_h, half_h)
      local west_offset = free_offset(defines.direction.west,
        entry.gas_offset or off_h, half_h)
      pipe_connections = {
        { flow_direction = "input-output", direction = defines.direction.east, position = {entry.gas_edge or half_w, east_offset} },
        { flow_direction = "input-output", direction = defines.direction.west, position = {-(entry.gas_edge or half_w), west_offset} },
      }
    end

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
  end
end

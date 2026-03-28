-- Vulcanus heat interface management.
-- Spawns hidden heat-interface entities alongside pneumatic machines.
-- Periodically increases their temperature (amortized bucket approach).

local vulcanus_heat = {}

local NUM_BUCKETS = 443  -- Same as Stirling engines. One bucket per tick.
local HEAT_PER_UPDATE = 15  -- Degrees added per update (~2C/sec with 443 buckets).
local MAX_HEAT = 500  -- Match heat pipe tier 2 max temperature.

function vulcanus_heat.init()
  storage.nullius_heat_buckets = {}
  for i = 0, NUM_BUCKETS - 1 do
    storage.nullius_heat_buckets[i] = {}
  end
  storage.nullius_pneumatic_heat = {}
end

-- Map machine collision box to heat interface size.
local function get_heat_size(entity)
  local cb = entity.prototype.collision_box
  local half = math.max(math.abs(cb.left_top.x), math.abs(cb.left_top.y))
  if half <= 0.8 then return "small"
  elseif half <= 1.4 then return "medium"
  elseif half <= 1.9 then return "medium2"
  else return "large"
  end
end

-- Spawn heat interface for a pneumatic machine.
function vulcanus_heat.add_heat_interface(entity)
  if not entity or not entity.valid then return end
  if entity.type == "inserter" then return end
  -- Thermal furnaces have their own heat connections, skip them.
  if string.find(entity.name, "furnace") then return end
  local surface = entity.surface
  if not surface.planet or surface.planet.name ~= "nullius-vulcanus" then return end

  local size = get_heat_size(entity)
  local heat_name = "nullius-pneumatic-heat-" .. size
  local heat = surface.create_entity{
    name = heat_name,
    position = entity.position,
    force = entity.force,
  }
  if heat and heat.valid then
    heat.destructible = false
    heat.minable = false

    if not storage.nullius_pneumatic_heat then
      storage.nullius_pneumatic_heat = {}
    end
    storage.nullius_pneumatic_heat[entity.unit_number] = heat

    -- Add to amortized bucket.
    if not storage.nullius_heat_buckets then
      vulcanus_heat.init()
    end
    local bucket_idx = entity.unit_number % NUM_BUCKETS
    storage.nullius_heat_buckets[bucket_idx][entity.unit_number] = {
      heat = heat,
      machine = entity,
    }

    script.register_on_object_destroyed(entity)
  end
end

-- Remove heat interface when machine is removed/toggled back.
function vulcanus_heat.remove_heat_interface(unit_number)
  if storage.nullius_pneumatic_heat then
    local heat = storage.nullius_pneumatic_heat[unit_number]
    if heat and heat.valid then
      heat.destroy()
    end
    storage.nullius_pneumatic_heat[unit_number] = nil
  end

  -- Remove from bucket.
  if storage.nullius_heat_buckets then
    local bucket_idx = unit_number % NUM_BUCKETS
    if storage.nullius_heat_buckets[bucket_idx] then
      storage.nullius_heat_buckets[bucket_idx][unit_number] = nil
    end
  end
end

-- Called every tick from update_tick. Processes one bucket per tick.
function vulcanus_heat.update()
  if not storage.nullius_heat_buckets then return end

  local bucket = storage.nullius_heat_buckets[game.tick % NUM_BUCKETS]
  if not bucket then return end

  for unit_number, entry in pairs(bucket) do
    if not entry.heat.valid then
      bucket[unit_number] = nil
      if storage.nullius_pneumatic_heat then
        storage.nullius_pneumatic_heat[unit_number] = nil
      end
    elseif not entry.machine.valid then
      entry.heat.destroy()
      bucket[unit_number] = nil
      if storage.nullius_pneumatic_heat then
        storage.nullius_pneumatic_heat[unit_number] = nil
      end
    else
      -- Add heat if machine is active (status == working or low power).
      local status = entry.machine.status
      if status == defines.entity_status.working
          or status == defines.entity_status.low_power then
        -- Scale heat by machine energy consumption (base + module bonuses).
        local base_energy = entry.machine.prototype.get_max_energy_usage()
        local consumption_mult = 1 + entry.machine.consumption_bonus
        local heat_delta = HEAT_PER_UPDATE * base_energy * consumption_mult / 100000
        if heat_delta < 1 then heat_delta = 1 end
        local temp = entry.heat.temperature
        entry.heat.temperature = math.min(MAX_HEAT, temp + heat_delta)
      end
      -- If idle, heat dissipates naturally through heat network.
    end
  end
end

return vulcanus_heat

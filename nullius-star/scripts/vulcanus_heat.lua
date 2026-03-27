-- Vulcanus heat interface management.
-- Spawns hidden heat-interface entities alongside pneumatic machines.
-- Periodically increases their temperature (amortized bucket approach).

local vulcanus_heat = {}

local NUM_BUCKETS = 443  -- Same as Stirling engines. One bucket per tick.
local HEAT_AMBIENT = 200  -- Vulcanus ambient temperature floor.
local HEAT_PER_UPDATE = 2  -- Degrees added per update when active (scaled by bucket count).

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
  else return "large"
  end
end

-- Spawn heat interface for a pneumatic machine.
function vulcanus_heat.add_heat_interface(entity)
  if not entity or not entity.valid then return end
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
    -- Set heat mode to actively maintain ambient volcanic temperature.
    heat.set_heat_setting{mode = "at-least", temperature = HEAT_AMBIENT}


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
      -- Machine was removed but we missed the event. Clean up.
      entry.heat.destroy()
      bucket[unit_number] = nil
      if storage.nullius_pneumatic_heat then
        storage.nullius_pneumatic_heat[unit_number] = nil
      end
    else
      local temp = entry.heat.temperature

      -- Floor at ambient volcanic temperature.
      if temp < HEAT_AMBIENT then
        entry.heat.temperature = HEAT_AMBIENT
      else
        -- Add heat if machine is active (status == working or low power).
        local status = entry.machine.status
        if status == defines.entity_status.working
            or status == defines.entity_status.low_power then
          entry.heat.temperature = math.min(1000, temp + HEAT_PER_UPDATE)
        end
        -- If idle, heat dissipates naturally through heat network.
      end
    end
  end
end


-- Called when a heat pipe is placed on Vulcanus.
-- Recreates nearby heat interfaces so the engine detects them.
-- This is needed because the engine doesn't re-evaluate connections
-- for existing heat-interfaces when a new heat pipe is placed.
function vulcanus_heat.on_heat_pipe_built(entity)
  if not entity or not entity.valid then return end
  if entity.type ~= "heat-pipe" then return end
  local surface = entity.surface
  if not surface.planet or surface.planet.name ~= "nullius-vulcanus" then return end
  if not storage.nullius_pneumatic_heat then return end

  local pos = entity.position
  local nearby = surface.find_entities_filtered{
    type = "heat-interface",
    area = {{pos.x - 3, pos.y - 3}, {pos.x + 3, pos.y + 3}},
  }
  for _, heat in pairs(nearby) do
    if heat.valid and string.sub(heat.name, 1, 22) == "nullius-pneumatic-heat" then
      local h_pos = heat.position
      local h_name = heat.name
      local h_force = heat.force
      local h_temp = heat.temperature
      local h_setting = heat.get_heat_setting()

      local parent_unit = nil
      for unit_number, stored_heat in pairs(storage.nullius_pneumatic_heat) do
        if stored_heat == heat then
          parent_unit = unit_number
          break
        end
      end

      heat.destroy()
      local new_heat = surface.create_entity{
        name = h_name, position = h_pos, force = h_force,
      }
      if new_heat and new_heat.valid then
        new_heat.destructible = false
        new_heat.minable = false
        new_heat.temperature = h_temp
        new_heat.set_heat_setting(h_setting)
        if parent_unit then
          storage.nullius_pneumatic_heat[parent_unit] = new_heat
          local bucket_idx = parent_unit % NUM_BUCKETS
          if storage.nullius_heat_buckets
              and storage.nullius_heat_buckets[bucket_idx]
              and storage.nullius_heat_buckets[bucket_idx][parent_unit] then
            storage.nullius_heat_buckets[bucket_idx][parent_unit].heat = new_heat
          end
        end
      end
    end
  end
end

return vulcanus_heat

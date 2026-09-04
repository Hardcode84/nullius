-- Vulcanus heat interface management.
-- Spawns hidden heat-interface entities alongside pneumatic machines.
-- Periodically increases their temperature (amortized bucket approach).

local vulcanus_heat = {}

local NUM_BUCKETS = 443  -- Same as Stirling engines. One bucket per tick.
local MAX_HEAT = 500  -- Match heat pipe tier 2 max temperature.
local HEAT_DIVISOR = 200  -- Scales energy (J/tick) to degrees per update.
local HEAT_INTERFACES = {
  "nullius-pneumatic-heat-small",
  "nullius-pneumatic-heat-medium",
  "nullius-pneumatic-heat-medium2",
  "nullius-pneumatic-heat-large",
}

local function is_heat_producer(entity)
  return entity.type ~= "inserter" and entity.type ~= "pump" and
    entity.name ~= "nullius-boxer-pneumatic"
end

local function new_buckets()
  local buckets = {}
  for i = 0, NUM_BUCKETS - 1 do
    buckets[i] = {}
  end
  return buckets
end

local function ensure_storage()
  if not storage.nullius_heat_buckets then
    storage.nullius_heat_buckets = new_buckets()
  end
  if not storage.nullius_pneumatic_heat then
    storage.nullius_pneumatic_heat = {}
  end
  if not storage.nullius_pneumatic_heat_registered then
    storage.nullius_pneumatic_heat_registered = {}
  end
end

function vulcanus_heat.init()
  storage.nullius_heat_buckets = new_buckets()
  storage.nullius_pneumatic_heat = {}
  storage.nullius_pneumatic_heat_registered = {}
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

local function is_vulcanus(entity)
  local surface = entity.surface
  return surface and surface.planet and
    surface.planet.name == "nullius-vulcanus"
end

local function is_eligible_machine(entity)
  return entity and entity.valid and entity.unit_number and
    string.sub(entity.name, -10) == "-pneumatic" and
    is_heat_producer(entity) and is_vulcanus(entity)
end

local function heat_name(entity)
  return "nullius-pneumatic-heat-" .. get_heat_size(entity)
end

local function interfaces_at(entity)
  return entity.surface.find_entities_filtered{
    name = HEAT_INTERFACES,
    position = entity.position,
    radius = 0.01,
  }
end

local function create_interface(entity, name)
  local heat = entity.surface.create_entity{
    name = name,
    position = entity.position,
    force = entity.force,
  }
  if heat and heat.valid then
    heat.destructible = false
    heat.minable = false
  end
  return heat
end

local function record_owner(entity, heat, register_destroyed)
  local unit_number = entity.unit_number
  storage.nullius_pneumatic_heat[unit_number] = heat
  storage.nullius_heat_buckets[unit_number % NUM_BUCKETS][unit_number] = {
    heat = heat,
    machine = entity,
  }
  if register_destroyed and
      not storage.nullius_pneumatic_heat_registered[unit_number] then
    script.register_on_object_destroyed(entity)
    storage.nullius_pneumatic_heat_registered[unit_number] = true
  end
end

local function reconcile_machine(entity, claimed, register_destroyed)
  local expected_name = heat_name(entity)
  local keep
  for _, heat in pairs(interfaces_at(entity)) do
    if heat.name == expected_name and heat.force == entity.force and
        (not keep or heat.temperature > keep.temperature) then
      if keep then keep.destroy() end
      keep = heat
    else
      heat.destroy()
    end
  end
  if not keep then keep = create_interface(entity, expected_name) end
  if not keep then return nil end
  record_owner(entity, keep, register_destroyed)
  if claimed then claimed[keep.unit_number] = true end
  return keep
end

-- Spawn heat interface for a pneumatic machine.
function vulcanus_heat.add_heat_interface(entity)
  if not is_eligible_machine(entity) then return end
  ensure_storage()
  return reconcile_machine(entity, nil, true)
end

local function eligible_names()
  local names = {}
  for name, prototype in pairs(prototypes.entity) do
    if string.sub(name, -10) == "-pneumatic" and
        prototype.type ~= "inserter" and prototype.type ~= "pump" and
        name ~= "nullius-boxer-pneumatic" then
      names[#names + 1] = name
    end
  end
  return names
end

-- Reconcile physical interfaces and rebuild all derived ownership state.
-- Called on configuration changes, where a full surface scan is acceptable.
function vulcanus_heat.rebuild()
  local registered = storage.nullius_pneumatic_heat_registered or {}
  storage.nullius_heat_buckets = new_buckets()
  storage.nullius_pneumatic_heat = {}
  storage.nullius_pneumatic_heat_registered = registered

  local claimed = {}
  local live_machines = {}
  local names = eligible_names()
  for _, surface in pairs(game.surfaces) do
    local machines = surface.find_entities_filtered{name = names}
    for _, machine in pairs(machines) do
      if is_eligible_machine(machine) then
        local unit_number = machine.unit_number
        live_machines[unit_number] = true
        reconcile_machine(machine, claimed, true)
      end
    end
  end

  for _, surface in pairs(game.surfaces) do
    for _, heat in pairs(surface.find_entities_filtered{name = HEAT_INTERFACES}) do
      if not claimed[heat.unit_number] then heat.destroy() end
    end
  end

  for unit_number in pairs(registered) do
    if not live_machines[unit_number] then registered[unit_number] = nil end
  end
end

-- Remove heat interface when machine is removed/toggled back.
function vulcanus_heat.remove_heat_interface(unit_number, entity)
  local removed = false
  if storage.nullius_pneumatic_heat then
    local heat = storage.nullius_pneumatic_heat[unit_number]
    removed = heat ~= nil
    if heat and heat.valid then
      heat.destroy()
    end
    storage.nullius_pneumatic_heat[unit_number] = nil
  end

  -- Recover cleanup when ownership storage was absent or partial.
  if entity and entity.valid then
    for _, heat in pairs(interfaces_at(entity)) do
      removed = true
      heat.destroy()
    end
  end

  -- Remove from bucket.
  if storage.nullius_heat_buckets then
    local bucket_idx = unit_number % NUM_BUCKETS
    if storage.nullius_heat_buckets[bucket_idx] then
      storage.nullius_heat_buckets[bucket_idx][unit_number] = nil
    end
  end
  if storage.nullius_pneumatic_heat_registered then
    storage.nullius_pneumatic_heat_registered[unit_number] = nil
  end
  return removed
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
      if storage.nullius_pneumatic_heat_registered then
        storage.nullius_pneumatic_heat_registered[unit_number] = nil
      end
    elseif not entry.machine.valid then
      entry.heat.destroy()
      bucket[unit_number] = nil
      if storage.nullius_pneumatic_heat then
        storage.nullius_pneumatic_heat[unit_number] = nil
      end
      if storage.nullius_pneumatic_heat_registered then
        storage.nullius_pneumatic_heat_registered[unit_number] = nil
      end
    else
      -- Add heat if machine is active (status == working or low power).
      local status = entry.machine.status
      if status == defines.entity_status.working
          or status == defines.entity_status.low_power then
        -- Scale heat by machine energy consumption (base + module bonuses).
        -- get_max_energy_usage() returns joules per tick (watts / 60).
        -- A 240kW machine = 4000 J/tick. We want ~10-50 degrees per update.
        local base_energy = entry.machine.prototype.get_max_energy_usage()
        local consumption_mult = 1 + entry.machine.consumption_bonus
        local heat_delta = base_energy * consumption_mult / HEAT_DIVISOR
        if heat_delta < 2 then heat_delta = 2 end
        local temp = entry.heat.temperature
        entry.heat.temperature = math.min(MAX_HEAT, temp + heat_delta)
      end
      -- If idle, heat dissipates naturally through heat network.
    end
  end
end

if script.active_mods["factorio-test-support"] then
  remote.add_interface("nullius-test-pneumatic-heat", {
    forget_all = function()
      storage.nullius_heat_buckets = nil
      storage.nullius_pneumatic_heat = nil
      storage.nullius_pneumatic_heat_registered = nil
    end,
    forget_owner = function(unit_number)
      if storage.nullius_pneumatic_heat then
        storage.nullius_pneumatic_heat[unit_number] = nil
      end
    end,
    rebuild = vulcanus_heat.rebuild,
  })
end

return vulcanus_heat

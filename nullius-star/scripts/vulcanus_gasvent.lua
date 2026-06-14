-- Vulcanus free-gas vent management.
-- The free-gas vent is the lava intake's Ctrl+R alternate mode. The player-facing
-- entity is a cosmetic assembling-machine SHELL (the intake re-skinned, never
-- crafts) -- so it places and blueprints/copy-pastes like a normal intake, with
-- no mining-drill/resource ordering problem for ghosts. When a shell is built,
-- we spawn a hidden mining-drill plus an invisible infinite gas resource under
-- it; the drill does the actual venting.
--
-- This mirrors Space Exploration 0.5 core mining's composite pattern: visible
-- placeable shell + script-created drill/resource + event-driven equalisation.
-- The resource has infinite_depletion_amount = 0, so the engine never changes
-- its amount -- we own it. The engine meters an infinite resource's output at
-- amount/NORMAL, so throttling is just rewriting resource.amount =
-- NORMAL/sqrt(N) (N = vents on the surface). Each vent delivers BASE/sqrt(N)
-- gas, total grows as sqrt(N). No per-tick loop.
--
-- IMPORTANT ordering: a mining drill only acquires a resource that exists when
-- it is created, so register() creates the resource BEFORE the drill.

local vulcanus_gasvent = {}

local NORMAL = 1000000  -- Must match resource "normal" in vulcanus-entities.lua.
local SEAM = "nullius-gas-vent-seam"
local DRILL = "nullius-gas-vent-drill"

local function is_vulcanus(surface)
  return surface and surface.planet and surface.planet.name == "nullius-vulcanus"
end

local function destroy_if_valid(entity)
  if entity and entity.valid then entity.destroy() end
end

function vulcanus_gasvent.init()
  storage.nullius_gasvents = {}             -- shell unit_number -> entry.
  storage.nullius_gasvent_counts = {}       -- surface_index -> count.
  storage.nullius_gasvent_by_unit = {}      -- shell/drill unit_number -> shell unit_number.
  storage.nullius_gasvent_by_destroyed = {} -- object-destroyed registration -> shell unit_number.
end

local function ensure_init()
  if not storage.nullius_gasvents then storage.nullius_gasvents = {} end
  if not storage.nullius_gasvent_counts then storage.nullius_gasvent_counts = {} end
  local needs_backfill = not storage.nullius_gasvent_by_unit
  if not storage.nullius_gasvent_by_unit then storage.nullius_gasvent_by_unit = {} end
  if not storage.nullius_gasvent_by_destroyed then storage.nullius_gasvent_by_destroyed = {} end

  -- Backfill saves from the earlier shell+drill prototype that only keyed by
  -- shell unit and did not maintain a reverse unit map.
  if needs_backfill then
    for shell_unit, entry in pairs(storage.nullius_gasvents) do
      entry.shell_unit_number = entry.shell_unit_number or shell_unit
      entry.drill_unit_number = entry.drill_unit_number or
        (entry.drill and entry.drill.valid and entry.drill.unit_number)
      entry.resource_unit_number = entry.resource_unit_number or
        (entry.resource and entry.resource.valid and entry.resource.unit_number)
      storage.nullius_gasvent_by_unit[entry.shell_unit_number] = shell_unit
      if entry.drill_unit_number then
        storage.nullius_gasvent_by_unit[entry.drill_unit_number] = shell_unit
      end
      if entry.resource_unit_number then
        storage.nullius_gasvent_by_unit[entry.resource_unit_number] = shell_unit
      end
    end
  end
end

local function map_unit(entry, unit_number)
  if unit_number then
    storage.nullius_gasvent_by_unit[unit_number] = entry.shell_unit_number
  end
end

local function unmap_entry(entry)
  if storage.nullius_gasvent_by_unit then
    storage.nullius_gasvent_by_unit[entry.shell_unit_number] = nil
    if entry.drill_unit_number then
      storage.nullius_gasvent_by_unit[entry.drill_unit_number] = nil
    end
    if entry.resource_unit_number then
      storage.nullius_gasvent_by_unit[entry.resource_unit_number] = nil
    end
  end
  if storage.nullius_gasvent_by_destroyed then
    if entry.shell_destroyed_registration then
      storage.nullius_gasvent_by_destroyed[entry.shell_destroyed_registration] = nil
    end
    if entry.drill_destroyed_registration then
      storage.nullius_gasvent_by_destroyed[entry.drill_destroyed_registration] = nil
    end
    if entry.resource_destroyed_registration then
      storage.nullius_gasvent_by_destroyed[entry.resource_destroyed_registration] = nil
    end
  end
end

local function register_destroyed(entry, entity, field)
  if entity and entity.valid then
    local registration = script.register_on_object_destroyed(entity)
    entry[field] = registration
    storage.nullius_gasvent_by_destroyed[registration] = entry.shell_unit_number
  end
end

local function remove_entry(shell_unit, trigger_unit, destroy_shell)
  local entry = storage.nullius_gasvents[shell_unit]
  if not entry then return nil end

  -- If the shell itself was mined/destroyed/toggled, the caller/engine is already
  -- removing it; only destroy it when another hidden component broke first.
  local function not_trigger(part_unit)
    return (not trigger_unit) or (part_unit ~= trigger_unit)
  end
  if destroy_shell and not_trigger(entry.shell_unit_number) then
    destroy_if_valid(entry.shell)
  end
  if not_trigger(entry.drill_unit_number) then
    destroy_if_valid(entry.drill)
  end
  if not_trigger(entry.resource_unit_number) then
    destroy_if_valid(entry.resource)
  end

  storage.nullius_gasvents[shell_unit] = nil
  unmap_entry(entry)
  return entry.surface_index
end

-- Recount/validate one surface and set every vent's resource amount to
-- NORMAL/sqrt(N). This is intentionally a full recount rather than trusting a
-- counter, so stale entries from script destruction self-heal.
local function equalise(surface_index)
  ensure_init()

  local count = 0
  local stale = {}
  for shell_unit, entry in pairs(storage.nullius_gasvents) do
    if entry.surface_index == surface_index then
      if entry.shell and entry.shell.valid
          and entry.drill and entry.drill.valid
          and entry.resource and entry.resource.valid then
        count = count + 1
      else
        stale[#stale + 1] = shell_unit
      end
    end
  end

  for _, shell_unit in pairs(stale) do
    remove_entry(shell_unit, nil, true)
  end

  storage.nullius_gasvent_counts[surface_index] = count
  if count < 1 then return end

  local amount = math.max(1, math.floor(NORMAL / math.sqrt(count)))
  for _, entry in pairs(storage.nullius_gasvents) do
    if entry.surface_index == surface_index
        and entry.resource and entry.resource.valid
        and entry.resource.amount ~= amount then
      entry.resource.amount = amount
    end
  end
end

local function destroy_strays(surface, position)
  for _, entity in pairs(surface.find_entities_filtered{
      name = DRILL, position = position, radius = 0.1}) do
    destroy_if_valid(entity)
  end
  for _, entity in pairs(surface.find_entities_filtered{
      name = SEAM, position = position, radius = 0.1}) do
    destroy_if_valid(entity)
  end
end

-- Register a freshly built gas-vent shell: spawn the hidden resource and drill
-- under it (resource first so the drill acquires it), then re-equalise.
function vulcanus_gasvent.register(shell)
  if not shell or not shell.valid then return end
  if shell.type == "entity-ghost" then return end
  local surface = shell.surface
  if not is_vulcanus(surface) then return end
  ensure_init()

  local shell_unit = shell.unit_number
  if storage.nullius_gasvents[shell_unit] then
    equalise(surface.index)
    return
  end

  -- If a prior broken/experimental version left invisible parts here, remove
  -- them before creating the ordered resource+drill pair.
  destroy_strays(surface, shell.position)

  local resource = surface.create_entity{
    name = SEAM, position = shell.position, amount = NORMAL,
  }
  if not (resource and resource.valid) then return end

  local drill = surface.create_entity{
    name = DRILL, position = shell.position, force = shell.force,
    direction = shell.direction,
  }
  if not (drill and drill.valid) then
    resource.destroy()
    return
  end
  drill.destructible = false
  drill.minable = false

  local entry = {
    shell = shell,
    drill = drill,
    resource = resource,
    shell_unit_number = shell_unit,
    drill_unit_number = drill.unit_number,
    resource_unit_number = resource.unit_number,
    surface_index = surface.index,
  }
  storage.nullius_gasvents[shell_unit] = entry
  map_unit(entry, shell_unit)
  map_unit(entry, drill.unit_number)
  map_unit(entry, resource.unit_number)

  register_destroyed(entry, shell, "shell_destroyed_registration")
  register_destroyed(entry, drill, "drill_destroyed_registration")
  register_destroyed(entry, resource, "resource_destroyed_registration")
  equalise(surface.index)
end

function vulcanus_gasvent.rotated(shell)
  if not shell or not shell.valid then return end
  ensure_init()
  local entry = storage.nullius_gasvents[shell.unit_number]
  if entry and entry.drill and entry.drill.valid then
    entry.drill.direction = shell.direction
  end
end

function vulcanus_gasvent.destroyed(event)
  ensure_init()
  local shell_unit = storage.nullius_gasvent_by_destroyed[event.registration_number]
      or storage.nullius_gasvent_by_unit[event.useful_id]
      or event.useful_id
  local entry = storage.nullius_gasvents[shell_unit]
  if not entry then return false end

  local trigger_unit = event.useful_id
  local destroy_shell = (trigger_unit ~= entry.shell_unit_number)
  local si = remove_entry(shell_unit, trigger_unit, destroy_shell)
  if si then equalise(si) end
  return true
end

-- Deregister a vent. unit_number may be the visible shell or either hidden part.
function vulcanus_gasvent.remove(unit_number)
  ensure_init()
  local shell_unit = storage.nullius_gasvent_by_unit[unit_number] or unit_number
  local entry = storage.nullius_gasvents[shell_unit]
  if not entry then return false end

  local destroy_shell = (unit_number ~= entry.shell_unit_number)
  local si = remove_entry(shell_unit, unit_number, destroy_shell)
  if si then equalise(si) end
  return true
end

return vulcanus_gasvent

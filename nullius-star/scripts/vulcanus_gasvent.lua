local vulcanus_gasvent = {}
local VENTS = {"nullius-lava-intake-1-gasvent", "nullius-lava-intake-2-gasvent"}
local LEGACY_DRILL = "nullius-gas-vent-drill"
local LEGACY_SEAM = "nullius-gas-vent-seam"

local function is_vulcanus(surface)
  return surface.planet and surface.planet.name == "nullius-vulcanus"
end

function vulcanus_gasvent.init()
  storage.nullius_gasvents = {}
  storage.nullius_gasvent_counts = {}
  storage.nullius_gasvent_by_destroyed = {}
  storage.nullius_gasvent_by_unit = nil
end

-- Cold path: placement, removal, and configuration changes.
local function equalise(surface_index)
  local count = 0
  for unit, entry in pairs(storage.nullius_gasvents) do
    if entry.surface_index == surface_index then
      if entry.shell.valid then
        count = count + 1
      else
        storage.nullius_gasvent_by_destroyed[entry.registration] = nil
        storage.nullius_gasvents[unit] = nil
      end
    end
  end
  storage.nullius_gasvent_counts[surface_index] = count
  if count == 0 then return end
  local share = 1 / math.sqrt(count)
  for _, entry in pairs(storage.nullius_gasvents) do
    if entry.surface_index == surface_index then
      entry.shell.local_effect = {speed=share * (1 + entry.shell.force.mining_drill_productivity_bonus) - 1}
    end
  end
end

-- Keep the output bonus that the former mining drills received from research.
function vulcanus_gasvent.refresh_force(force)
  for _, entry in pairs(storage.nullius_gasvents) do
    if entry.shell.valid and entry.shell.force == force then
      local share = 1 / math.sqrt(storage.nullius_gasvent_counts[entry.surface_index])
      entry.shell.local_effect = {speed=share * (1 + force.mining_drill_productivity_bonus) - 1}
    end
  end
end

function vulcanus_gasvent.research_changed(event)
  for _, effect in pairs(event.research.prototype.effects) do
    if effect.type == "mining-drill-productivity-bonus" then
      vulcanus_gasvent.refresh_force(event.research.force)
      return
    end
  end
end

local function track(entity)
  local unit = entity.unit_number
  if storage.nullius_gasvents[unit] then return end
  local registration = script.register_on_object_destroyed(entity)
  storage.nullius_gasvents[unit] = {
    shell=entity, surface_index=entity.surface.index, registration=registration,
  }
  storage.nullius_gasvent_by_destroyed[registration] = unit
end

function vulcanus_gasvent.register(entity)
  if not entity or not entity.valid or entity.type == "entity-ghost" then return end
  if not is_vulcanus(entity.surface) then return end
  track(entity)
  equalise(entity.surface.index)
end

function vulcanus_gasvent.remove(unit)
  local entry = storage.nullius_gasvents[unit]
  if not entry then return false end
  storage.nullius_gasvents[unit] = nil
  storage.nullius_gasvent_by_destroyed[entry.registration] = nil
  equalise(entry.surface_index)
  return true
end

function vulcanus_gasvent.destroyed(event)
  local unit = storage.nullius_gasvent_by_destroyed[event.registration_number]
  return unit and vulcanus_gasvent.remove(unit) or false
end

-- Move a released composite vent's gas into the vent at its position. A drill
-- with no vent above it loses its gas, as a mined vent does.
local function release_drill(drill)
  local vent = drill.surface.find_entities_filtered{
    name=VENTS, position=drill.position, radius=0.1, limit=1}[1]
  if vent then
    for index = 1, drill.fluids_count do
      local fluid = drill.get_fluid(index)
      if fluid then
        local removed = drill.remove_fluid(index, fluid.amount)
        if math.abs(vent.insert_fluid(removed) - removed.amount) > 0.000001 then
          error("Cannot preserve gas while converting a legacy gas vent")
        end
      end
    end
  end
  drill.destroy()
end

-- Cold path: remove every released composite part, including parts that no
-- longer have a vent, then restore each surface's share.
function vulcanus_gasvent.rebuild()
  for _, surface in pairs(game.surfaces) do
    for _, drill in pairs(surface.find_entities_filtered{name=LEGACY_DRILL}) do release_drill(drill) end
    for _, seam in pairs(surface.find_entities_filtered{name=LEGACY_SEAM}) do seam.destroy() end
  end
  vulcanus_gasvent.init()
  for _, surface in pairs(game.surfaces) do
    if is_vulcanus(surface) then
      for _, entity in pairs(surface.find_entities_filtered{name=VENTS}) do track(entity) end
      equalise(surface.index)
    end
  end
end

if script.active_mods["factorio-test-support"] then
  remote.add_interface("nullius-test-gasvent", {rebuild = vulcanus_gasvent.rebuild})
end

return vulcanus_gasvent

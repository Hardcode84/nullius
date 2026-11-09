-- Vulcanus-specific entity transitions (Ctrl+R toggling).
-- Registers pneumatic machine and radiator mode transitions.

local transitions = require("scripts.transitions")
local pneumatic_families = require("shared.pneumatic-machine-families")
local thermal_nanofabricators = require("thermal-nanofabricator-specs")
local overcharged_assemblers = require("scripts.overcharged_assemblers")

-- Condition: entity is on Vulcanus and pneumatic tech is researched.
local function is_vulcanus_pneumatic(entity, force)
  local surface = entity.surface
  if not surface or not surface.planet or surface.planet.name ~= "nullius-vulcanus" then
    return false
  end
  return force.technologies["nullius-pneumatic-technology"].researched
end

local function is_vulcanus(entity)
  local surface = entity.surface
  return surface and surface.planet and
    surface.planet.name == "nullius-vulcanus"
end

local function nanofabricator_unlocked(entity, force, base)
  local recipe = force.recipes[base]
  return is_vulcanus(entity) and recipe ~= nil and recipe.enabled
end

local function on_leave_pneumatic(entity)
  vulcanus_heat.remove_heat_interface(entity.unit_number, entity)
end

local function on_enter_pneumatic(entity)
  vulcanus_heat.add_heat_interface(entity)
end

-- Convenience: register both directions of a pneumatic pair.
-- Must match entities generated in prototypes/pneumatic.lua.
local function register_pneumatic_pair(electric, pneumatic, gate, replace_fn)
  local assembler = pneumatic_families.is_normal_assembler(electric)
  transitions.register(electric, pneumatic, {
    condition = is_vulcanus_pneumatic,
    gate = gate,
    on_enter = on_enter_pneumatic,
    replace_fn = replace_fn or (assembler and overcharged_assemblers.replace or nil),
  })
  if assembler then
    transitions.register(pneumatic, electric .. "-overcharged", {
      condition = function(_, force) return overcharged_assemblers.unlocked(force, electric) end,
      on_leave = on_leave_pneumatic,
      replace_fn = overcharged_assemblers.replace,
    })
  end
  transitions.register(pneumatic, electric, {
    gate = gate,
    on_leave = on_leave_pneumatic,
    replace_fn = replace_fn or (assembler and overcharged_assemblers.replace or nil),
  })
end

-- A ghost has no silo state. A built silo switches only between rockets: the
-- rocket needs one part, so building_rocket means no part and no rocket yet.
local function silo_gate(entity)
  if entity.type == "entity-ghost" then return true end
  local allowed =
    entity.rocket_silo_status == defines.rocket_silo_status.building_rocket and
    entity.rocket == nil
  if not allowed then
    rendering.draw_text{surface=entity.surface, target=entity.position,
      text={"nullius-pneumatic.silo-switch-blocked"},
      color={1, 0.6, 0.2}, time_to_live=120, alignment="center"}
  end
  return allowed
end

local function replace_silo(entity, name, force)
  if entity.type == "entity-ghost" then
    return assert(replace_fluid_entity(entity, name, force), "Pneumatic silo ghost replacement failed")
  end
  -- Fast replacement drops automatic orbit sending; experiment-pneumatic-silo measures it.
  local automatic = entity.send_to_orbit_automatically
  local finished = entity.products_finished
  local replacement = assert(replace_fluid_entity(entity, name, force),
    "Pneumatic silo replacement failed")
  replacement.send_to_orbit_automatically = automatic
  replacement.products_finished = finished
  return replacement
end

register_pneumatic_pair("nullius-silo", "nullius-silo-pneumatic",
  silo_gate, replace_silo)

-- Four-state cycle for machines that already have priority/surge modes:
-- priority electric -> surge electric -> surge pneumatic ->
-- priority pneumatic -> priority electric.  Before pneumatic research or away
-- from Vulcanus, the ordinary priority/surge toggle remains in effect.
local function register_pneumatic_priority_cycle(machine, tier)
  local priority = "nullius-priority-" .. machine .. "-" .. tier
  local surge = "nullius-surge-" .. machine .. "-" .. tier
  local pneumatic_priority = priority .. "-pneumatic"
  local pneumatic_surge = surge .. "-pneumatic"

  transitions.register(priority, surge, {condition = is_vulcanus_pneumatic})
  transitions.register(surge, pneumatic_surge, {
    condition = is_vulcanus_pneumatic,
    on_enter = on_enter_pneumatic,
  })
  transitions.register(pneumatic_surge, pneumatic_priority, {
    on_leave = on_leave_pneumatic,
    on_enter = on_enter_pneumatic,
  })
  transitions.register(pneumatic_priority, priority, {
    on_leave = on_leave_pneumatic,
  })
end

for _, electric in ipairs(pneumatic_families.normal_assemblers(
    prototypes.entity)) do
  local pneumatic = electric .. "-pneumatic"
  if not prototypes.entity[pneumatic] then
    error("Missing pneumatic assembler prototype " .. pneumatic)
  end
  register_pneumatic_pair(electric, pneumatic)
end
for _, electric in ipairs(pneumatic_families.barrel_pumps(
    prototypes.entity)) do
  local pneumatic = electric .. "-pneumatic"
  if not prototypes.entity[pneumatic] then
    error("Missing pneumatic barrel pump prototype " .. pneumatic)
  end
  register_pneumatic_pair(electric, pneumatic)
end
for _, electric in ipairs(pneumatic_families.boxers(prototypes.entity)) do
  local pneumatic = electric .. "-pneumatic"
  if not prototypes.entity[pneumatic] then
    error("Missing pneumatic boxer prototype " .. pneumatic)
  end
  register_pneumatic_pair(electric, pneumatic)
end
for _, name in ipairs({
    "inserter",
    "bob-turbo-inserter",
    "bulk-inserter",
    "bob-express-bulk-inserter",
}) do
  register_pneumatic_pair(name, name .. "-pneumatic")
end
for i = 1, 3 do
  register_pneumatic_pair("nullius-hydro-plant-" .. i, "nullius-hydro-plant-" .. i .. "-pneumatic")
  register_pneumatic_pair("nullius-distillery-" .. i, "nullius-distillery-" .. i .. "-pneumatic")
  register_pneumatic_pair("nullius-chemical-plant-" .. i, "nullius-chemical-plant-" .. i .. "-pneumatic")
  register_pneumatic_priority_cycle("compressor", i)
end
for i = 1, 3 do
  register_pneumatic_pair("nullius-flotation-cell-" .. i,
    "nullius-flotation-cell-" .. i .. "-pneumatic")
end
for _, name in ipairs(pneumatic_families.solid_miners(prototypes.entity)) do
  register_pneumatic_pair(name, name .. "-pneumatic")
end
register_pneumatic_pair("nullius-chimney-3", "nullius-chimney-3-pneumatic")
register_pneumatic_pair("nullius-extractor-1", "nullius-extractor-1-pneumatic")
register_pneumatic_pair("nullius-extractor-2", "nullius-extractor-2-pneumatic")
for i = 1, 3 do
  register_pneumatic_pair("nullius-air-filter-" .. i, "nullius-air-filter-" .. i .. "-pneumatic")
end
for i = 1, 3 do
  register_pneumatic_pair("nullius-lab-" .. i,
    "nullius-lab-" .. i .. "-pneumatic")
end

for _, spec in ipairs(thermal_nanofabricators) do
  local base = spec.base
  local thermal = base .. "-thermal"
  transitions.register(base, thermal, {
    condition = function(entity, force)
      return nanofabricator_unlocked(entity, force, base)
    end,
  })
  transitions.register(thermal, base)
end

-- Pump/valve cycle on Vulcanus:
-- electric-valve -> pneumatic-pump -> pneumatic-valve -> electric-pump.
-- (electric-pump -> electric-valve is handled by the existing toggle_pump in turbine.lua.)
local pump_valve_pairs = {
  {"nullius-pump-1", "nullius-togglable-pump-1"},
  {"nullius-pump-2", "nullius-togglable-pump-2"},
  {"pump", "nullius-togglable-pump-3"},
  {"nullius-small-pump-1", "nullius-togglable-small-pump-1"},
  {"nullius-small-pump-2", "nullius-togglable-small-pump-2"},
}

-- Lava intake cycle on Vulcanus:
-- free lava intake -> free-gas vent -> free lava intake.
-- The lava intake is void-powered: a shore intake can't practically take gas on
-- its lava side (pipes cannot be placed on lava), and bootstrap has no
-- electricity. Gas mode crafts directly, with a local speed effect for its
-- surface share. Mode changes discard the old fluid, as the two modes have
-- different fluid filters.
for i = 1, 2 do
  local lava = "nullius-lava-intake-" .. i
  local pneumatic = lava .. "-pneumatic"  -- legacy/dev saves only.
  local gasvent = lava .. "-gasvent"

  transitions.register(lava, gasvent, {
    condition = is_vulcanus_pneumatic,
    replace_fn = replace_pump_valve,
    on_enter = function(entity) vulcanus_gasvent.register(entity) end,
  })
  transitions.register(pneumatic, gasvent, {
    -- Leaving legacy pneumatic mode: tear down its heat interface.
    replace_fn = replace_pump_valve,
    on_leave = on_leave_pneumatic,
    on_enter = function(entity) vulcanus_gasvent.register(entity) end,
  })
  transitions.register(gasvent, lava, {
    replace_fn = replace_pump_valve,
    on_leave = function(entity) vulcanus_gasvent.remove(entity.unit_number) end,
  })
end

for _, pair in ipairs(pump_valve_pairs) do
  local pump, valve = pair[1], pair[2]
  local pn_pump = pump .. "-pneumatic"
  local pn_valve = valve .. "-pneumatic"

  -- Electric valve -> pneumatic pump (Vulcanus only, after valve done cycling).
  transitions.register(valve, pn_pump, {
    condition = is_vulcanus_pneumatic,
    gate = valve_gate,
    replace_fn = replace_pump_valve,
  })
  -- Pneumatic pump -> pneumatic valve.
  transitions.register(pn_pump, pn_valve, {
    replace_fn = replace_pump_valve,
  })
  -- Pneumatic valve -> electric pump (after valve done cycling).
  transitions.register(pn_valve, pump, {
    gate = valve_gate,
    replace_fn = replace_pump_valve,
  })
end

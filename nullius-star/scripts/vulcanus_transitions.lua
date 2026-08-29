-- Vulcanus-specific entity transitions (Ctrl+R toggling).
-- Registers pneumatic machine and radiator mode transitions.

local transitions = require("scripts.transitions")

-- Condition: entity is on Vulcanus and pneumatic tech is researched.
local function is_vulcanus_pneumatic(entity, force)
  local surface = entity.surface
  if not surface or not surface.planet or surface.planet.name ~= "nullius-vulcanus" then
    return false
  end
  return force.technologies["nullius-pneumatic-technology"].researched
end

local function on_leave_pneumatic(entity)
  vulcanus_heat.remove_heat_interface(entity.unit_number)
end

local function on_enter_pneumatic(entity)
  vulcanus_heat.add_heat_interface(entity)
end

-- Convenience: register both directions of a pneumatic pair.
-- Must match entities generated in prototypes/pneumatic.lua.
local function register_pneumatic_pair(electric, pneumatic)
  transitions.register(electric, pneumatic, {
    condition = is_vulcanus_pneumatic,
    on_enter = on_enter_pneumatic,
  })
  transitions.register(pneumatic, electric, {
    on_leave = on_leave_pneumatic,
  })
end

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

for i = 1, 3 do
  register_pneumatic_pair("nullius-small-furnace-" .. i, "nullius-small-furnace-" .. i .. "-pneumatic")
  register_pneumatic_pair("nullius-medium-furnace-" .. i, "nullius-medium-furnace-" .. i .. "-pneumatic")
  register_pneumatic_pair("nullius-foundry-" .. i, "nullius-foundry-" .. i .. "-pneumatic")
end
register_pneumatic_pair("nullius-small-assembler-1", "nullius-small-assembler-1-pneumatic")
register_pneumatic_pair("nullius-small-assembler-2", "nullius-small-assembler-2-pneumatic")
register_pneumatic_pair("nullius-medium-assembler-1", "nullius-medium-assembler-1-pneumatic")
register_pneumatic_pair("nullius-medium-assembler-2", "nullius-medium-assembler-2-pneumatic")
register_pneumatic_pair("nullius-barrel-pump-1", "nullius-barrel-pump-1-pneumatic")
register_pneumatic_pair("inserter", "inserter-pneumatic")
register_pneumatic_pair("bob-turbo-inserter", "bob-turbo-inserter-pneumatic")
for i = 1, 3 do
  register_pneumatic_pair("nullius-hydro-plant-" .. i, "nullius-hydro-plant-" .. i .. "-pneumatic")
  register_pneumatic_pair("nullius-distillery-" .. i, "nullius-distillery-" .. i .. "-pneumatic")
  register_pneumatic_pair("nullius-chemical-plant-" .. i, "nullius-chemical-plant-" .. i .. "-pneumatic")
  register_pneumatic_priority_cycle("compressor", i)
end
register_pneumatic_pair("nullius-flotation-cell-1",
  "nullius-flotation-cell-1-pneumatic")
register_pneumatic_pair("nullius-extractor-1", "nullius-extractor-1-pneumatic")
register_pneumatic_pair("nullius-extractor-2", "nullius-extractor-2-pneumatic")
for i = 1, 3 do
  register_pneumatic_pair("nullius-crusher-" .. i, "nullius-crusher-" .. i .. "-pneumatic")
end
for i = 1, 3 do
  register_pneumatic_pair("nullius-air-filter-" .. i, "nullius-air-filter-" .. i .. "-pneumatic")
end
register_pneumatic_pair("nullius-lab-1", "nullius-lab-1-pneumatic")

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
-- electricity. The gas vent is a cosmetic assembling-machine shell. Registering
-- it spawns the hidden drill + gas resource used for diminishing-returns
-- throttling; leaving it tears both down. replace_pump_valve is used
-- (destroy+create, no fluid carryover): the modes have differently-filtered
-- fluid boxes (lava vs gas), so the default save/restore could mishandle them.
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

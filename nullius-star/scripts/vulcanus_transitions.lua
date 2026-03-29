-- Vulcanus-specific entity transitions (Ctrl+R toggling).
-- Registers pneumatic machine and radiator mode transitions
-- into the global transition table from turbine.lua.

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
  register_transition(electric, pneumatic, {
    condition = is_vulcanus_pneumatic,
    on_enter = on_enter_pneumatic,
  })
  register_transition(pneumatic, electric, {
    on_leave = on_leave_pneumatic,
  })
end

for i = 1, 3 do
  register_pneumatic_pair("nullius-small-furnace-" .. i, "nullius-small-furnace-" .. i .. "-pneumatic")
  register_pneumatic_pair("nullius-foundry-" .. i, "nullius-foundry-" .. i .. "-pneumatic")
end
register_pneumatic_pair("nullius-small-assembler-1", "nullius-small-assembler-1-pneumatic")
register_pneumatic_pair("nullius-small-assembler-2", "nullius-small-assembler-2-pneumatic")
register_pneumatic_pair("nullius-medium-assembler-1", "nullius-medium-assembler-1-pneumatic")
register_pneumatic_pair("nullius-medium-assembler-2", "nullius-medium-assembler-2-pneumatic")
register_pneumatic_pair("inserter", "inserter-pneumatic")
register_pneumatic_pair("bob-turbo-inserter", "bob-turbo-inserter-pneumatic")
for i = 1, 3 do
  register_pneumatic_pair("nullius-hydro-plant-" .. i, "nullius-hydro-plant-" .. i .. "-pneumatic")
  register_pneumatic_pair("nullius-distillery-" .. i, "nullius-distillery-" .. i .. "-pneumatic")
  register_pneumatic_pair("nullius-chemical-plant-" .. i, "nullius-chemical-plant-" .. i .. "-pneumatic")
  register_pneumatic_pair("nullius-surge-electrolyzer-" .. i, "nullius-surge-electrolyzer-" .. i .. "-pneumatic")
  register_pneumatic_pair("nullius-priority-electrolyzer-" .. i, "nullius-priority-electrolyzer-" .. i .. "-pneumatic")
end
register_pneumatic_pair("nullius-extractor-1", "nullius-extractor-1-pneumatic")
register_pneumatic_pair("nullius-extractor-2", "nullius-extractor-2-pneumatic")
for i = 1, 3 do
  register_pneumatic_pair("nullius-air-filter-" .. i, "nullius-air-filter-" .. i .. "-pneumatic")
end
register_pneumatic_pair("nullius-lab-1", "nullius-lab-1-pneumatic")

-- Radiator mode toggle (Deacon <-> Cracking). No heat interface needed.
register_transition("nullius-vulcanus-radiator-deacon", "nullius-vulcanus-radiator-cracking", {
  condition = is_vulcanus_pneumatic,
})
register_transition("nullius-vulcanus-radiator-cracking", "nullius-vulcanus-radiator-deacon", {
  condition = is_vulcanus_pneumatic,
})

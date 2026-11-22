-- Chemical plants, hydro plants and flotation cells have a bioreactor mode at their
-- own tier, which is also their Gleba mode. Nutrient Technology unlocks the first
-- tier; Bioreactor Engineering unlocks the others.
local bioreactors = {
  -- Multiples of the ordinary machine's power, burned as nutrient goop. The first
  -- tier runs the Gleba bootstrap, so it burns no more than a nutrient machine.
  power = {1, 30, 100},
  specs = {},
}

function bioreactors.research(tier)
  return tier == 1 and "nullius-nutrient-technology" or ("nullius-bioreactor-engineering-" .. tier)
end

-- Gleba recipe categories that each family also runs.
local FAMILIES = {
  {name = "chemical-plant", category = "gleba-chemosynthesis"},
  {name = "hydro-plant"},
  {name = "flotation-cell", category = "gleba-culture"},
}

for tier = 1, 3 do
  for _, family in ipairs(FAMILIES) do
    bioreactors.specs[#bioreactors.specs + 1] = {
      base = "nullius-" .. family.name .. "-" .. tier, tier = tier, category = family.category,
    }
  end
end

return bioreactors

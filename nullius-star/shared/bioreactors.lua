-- Chemical and hydro plants have a bioreactor mode at their own tier. Biochemistry 1
-- unlocks the first tier; Bioreactor Engineering unlocks the others.
local bioreactors = {
  -- Multiples of the ordinary machine's power, burned as nutrient goop.
  power = {10, 30, 100},
  specs = {},
}

function bioreactors.research(tier)
  return tier == 1 and "nullius-biochemistry-1" or ("nullius-bioreactor-engineering-" .. tier)
end

for tier = 1, 3 do
  for _, family in ipairs({"chemical-plant", "hydro-plant"}) do
    bioreactors.specs[#bioreactors.specs + 1] = {base = "nullius-" .. family .. "-" .. tier, tier = tier}
  end
end

return bioreactors

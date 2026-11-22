-- Ordinary items place the electric machine. Ctrl+R selects its nutrient mode.
local machines = {}

local function add(entity_type, name, category, fixed_recipe)
  machines[#machines + 1] = {name = name, type = entity_type, category = category, fixed_recipe = fixed_recipe}
end

local function add_tiers(entity_type, prefix, max_tier, category, fixed_recipe)
  for tier = 1, max_tier do
    add(entity_type, prefix .. tier, category, fixed_recipe)
  end
end

add_tiers("mining-drill", "nullius-small-miner-", 3)
add_tiers("mining-drill", "nullius-medium-miner-", 3)
add_tiers("mining-drill", "nullius-large-miner-", 2)
add_tiers("mining-drill", "nullius-extractor-", 2)

add_tiers("assembling-machine", "nullius-crusher-", 3, "gleba-crushing")
add_tiers("assembling-machine", "nullius-flotation-cell-", 3, "gleba-culture")
add_tiers("assembling-machine", "nullius-chemical-plant-", 3, "gleba-chemosynthesis")
add_tiers("assembling-machine", "nullius-small-furnace-", 3, "gleba-roasting")
add_tiers("assembling-machine", "nullius-medium-furnace-", 3, "gleba-roasting")
add_tiers("assembling-machine", "nullius-large-furnace-", 2, "gleba-roasting")
add_tiers("assembling-machine", "nullius-foundry-", 3)
add_tiers("assembling-machine", "nullius-small-assembler-", 3)
add_tiers("assembling-machine", "nullius-medium-assembler-", 3)
add_tiers("assembling-machine", "nullius-large-assembler-", 2)
add_tiers("assembling-machine", "nullius-hydro-plant-", 3)
add_tiers("assembling-machine", "nullius-distillery-", 3)
-- Gleba air has no carbon dioxide, so nutrient filters separate its nitrogen.
add_tiers("assembling-machine", "nullius-air-filter-", 3, nil, "nullius-air-separation-gleba")
add_tiers("assembling-machine", "nullius-barrel-pump-", 2)
add_tiers("assembling-machine", "nullius-priority-compressor-", 3)
add_tiers("assembling-machine", "nullius-surge-compressor-", 3)
add_tiers("assembling-machine", "nullius-nanofabricator-", 2)

add("furnace", "nullius-boxer")
add("furnace", "nullius-chimney-3")

add_tiers("lab", "nullius-lab-", 3)
add("lab", "nullius-biology-lab")

for _, name in ipairs({
  "inserter",
  "bob-turbo-inserter",
  "bulk-inserter",
  "bob-express-bulk-inserter",
}) do
  add("inserter", name)
end

for _, name in ipairs({
  "nullius-pump-1",
  "nullius-pump-2",
  "pump",
  "nullius-small-pump-1",
  "nullius-small-pump-2",
}) do
  add("pump", name)
end

return machines

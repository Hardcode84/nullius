-- Bioreactor research and the goop routes off Gleba. Biochemistry 1, defined in
-- technology.lua, unlocks the first tier and these recipes.
local goop = data.raw.item["nullius-nutrient-goop"]

local function recipe(name, category, time, ingredients, results, icon)
  return {
    type = "recipe", name = "nullius-" .. name, localised_name = {"recipe-name.nullius-" .. name},
    icons = table.deepcopy(icon.icons or {{icon = icon.icon, icon_size = icon.icon_size}}),
    categories = {category}, subgroup = "biology-material", order = "nullius-gz-" .. name,
    enabled = false, energy_required = time, ingredients = ingredients, results = results,
    main_product = results[1].name,
    -- A bioreactor burns goop, so its productivity never multiplies goop or its waste.
    allow_productivity = false, allow_decomposition = false,
  }
end

local function fluid(name, amount) return {type = "fluid", name = "nullius-" .. name, amount = amount} end
local function item(name, amount) return {type = "item", name = "nullius-" .. name, amount = amount} end

data:extend({
  -- Single-cell protein: bacteria grown on methanol and ammonia, as the ICI Pruteen process.
  recipe("single-cell-protein", "basic-chemistry", 10,
    {fluid("methanol", 40), fluid("ammonia", 10), fluid("oxygen", 20)},
    {item("nutrient-goop", 2), fluid("wastewater", 20)}, goop),
  -- Fulgora grows the same protein on its filtered hydrocarbons.
  recipe("hydrocarbon-protein", "basic-chemistry", 30,
    {fluid("filtered-hydrocarbons", 40), fluid("ammonia", 30)},
    {item("nutrient-goop", 1), fluid("water", 10)}, goop),
  -- Off Gleba, spent and spoiled goop dissolves into sludge.
  recipe("digestate-dissolution", "nullius-water-treatment", 2,
    {item("digestate", 5), fluid("water", 50)},
    {fluid("sludge", 50)}, data.raw.item["nullius-digestate"]),
})

local function engineering(tier, count, seconds, ingredients, prerequisites)
  local description = {"technology-description.nullius-bioreactor-engineering-" .. tier}
  return {
    type = "technology", name = "nullius-bioreactor-engineering-" .. tier,
    localised_description = description,
    icon = "__space-age__/graphics/technology/biochamber.png", icon_size = 256,
    order = "nullius-gc-bioreactor-" .. tier,
    effects = {{type = "nothing", effect_description = description}},
    prerequisites = prerequisites,
    unit = {count = count, time = seconds, ingredients = ingredients},
  }
end

-- Priced as Overcharged Assembly 2 and 3, with biochemistry in place of electromagnetic packs.
data:extend({
  engineering(2, 10, 45, {
    {"nullius-biochemistry-pack", 20}, {"nullius-mechanical-pack", 4}, {"nullius-electrical-pack", 4},
  }, {"nullius-biochemistry-1"}),
  engineering(3, 20, 60, {
    {"nullius-biochemistry-pack", 40}, {"nullius-mechanical-pack", 8}, {"nullius-electrical-pack", 8},
    {"nullius-chemical-pack", 16}, {"nullius-physics-pack", 8},
  }, {"nullius-bioreactor-engineering-2", "nullius-physics"}),
})

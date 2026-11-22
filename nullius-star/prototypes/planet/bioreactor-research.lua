-- Bioreactor research and the goop routes off Gleba. Nutrient Technology, defined in
-- gleba-cultivation.lua, unlocks the first bioreactor tier.
local goop = data.raw.item["nullius-nutrient-goop"]
local early_packs = {
  {"nullius-geology-pack", 1}, {"nullius-climatology-pack", 1},
  {"nullius-mechanical-pack", 1}, {"nullius-electrical-pack", 1},
}

local function fluid(name, amount) return {type = "fluid", name = "nullius-" .. name, amount = amount} end
local function item(name, amount) return {type = "item", name = "nullius-" .. name, amount = amount} end

local function route(name, time, ingredients, results)
  local id = "nullius-" .. name
  data:extend({{
    type = "recipe", name = id, localised_name = {"recipe-name." .. id},
    icon = goop.icon, icon_size = goop.icon_size,
    categories = {"basic-chemistry"}, subgroup = "biology-material", order = "nullius-gz-" .. name,
    enabled = false, energy_required = time, ingredients = ingredients, results = results,
    main_product = results[1].name,
    -- A bioreactor burns goop, so its productivity never multiplies goop.
    allow_productivity = false, allow_decomposition = false,
  }})
  return id
end

-- Single-cell protein: bacteria grown on methanol and ammonia, as the ICI Pruteen
-- process. Nutrient Technology unlocks it.
route("single-cell-protein", 10,
  {fluid("methanol", 40), fluid("ammonia", 10), fluid("oxygen", 20)},
  {item("nutrient-goop", 2), fluid("wastewater", 20)})
-- Fulgora grows the same protein on its filtered hydrocarbons, at its own research.
local hydrocarbon = route("hydrocarbon-protein", 30,
  {fluid("filtered-hydrocarbons", 40), fluid("ammonia", 30)},
  {item("nutrient-goop", 1), fluid("water", 10)})
data:extend({{
  type = "technology", name = hydrocarbon, icon = goop.icon, icon_size = goop.icon_size,
  order = "nullius-dga-hydrocarbon-protein",
  prerequisites = {"nullius-nutrient-technology", "nullius-primitive-filtration"},
  effects = {{type = "unlock-recipe", recipe = hydrocarbon}},
  unit = {count = 20, time = 20, ingredients = table.deepcopy(early_packs)},
}})

local function engineering(tier, count, seconds, ingredients, prerequisites)
  local description = {"technology-description.nullius-bioreactor-engineering-" .. tier}
  return {
    type = "technology", name = "nullius-bioreactor-engineering-" .. tier,
    localised_description = description,
    icon = "__space-age__/graphics/technology/biochamber.png", icon_size = 256,
    order = "nullius-dga-bioreactor-" .. tier,
    effects = {{type = "nothing", effect_description = description}},
    prerequisites = prerequisites,
    unit = {count = count, time = seconds, ingredients = ingredients},
  }
end

-- Priced and gated as Overcharged Assembly 2 and 3, with biochemistry in place of
-- electromagnetic packs.
data:extend({
  engineering(2, 10, 45, {
    {"nullius-biochemistry-pack", 20}, {"nullius-mechanical-pack", 4}, {"nullius-electrical-pack", 4},
  }, {"nullius-nutrient-technology", "nullius-automation-2"}),
  engineering(3, 20, 60, {
    {"nullius-biochemistry-pack", 40}, {"nullius-mechanical-pack", 8}, {"nullius-electrical-pack", 8},
    {"nullius-chemical-pack", 16}, {"nullius-physics-pack", 8},
  }, {"nullius-bioreactor-engineering-2", "nullius-automation-3"}),
})

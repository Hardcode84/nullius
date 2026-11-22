local icon_dir = "__space-age__/graphics/icons/"
local planet = data.raw.planet["nullius-gleba"]
local gleba_only = {{property = "nullius-hydrogen-sulfide", min = 1}}

local probe = {
  type = "technology", name = "nullius-probe-gleba", order = "nullius-dg",
  icon = planet.icon, icon_size = 64,
  prerequisites = {"nullius-interplanetary-signal-acquisition", "nullius-organic-chemistry-1"},
  effects = {{type = "unlock-space-location", space_location = planet.name}},
  unit = {count = 40, time = 20, ingredients = {
    {"nullius-geology-pack", 1}, {"nullius-climatology-pack", 1},
    {"nullius-mechanical-pack", 1}, {"nullius-electrical-pack", 1},
  }},
}
-- Researched on Nauvis before transfer, as Pneumatic Technology and Primitive
-- Filtration are. Geology 2 supplies the crushed-mineral assays it builds on.
local nutrient = {
  type = "technology", name = "nullius-nutrient-technology", order = "nullius-dga",
  icon = icon_dir .. "nutrients.png", icon_size = 64,
  prerequisites = {probe.name, "nullius-geology-2"}, effects = {},
  unit = {count = 20, time = 15, ingredients = {
    {"nullius-geology-pack", 1}, {"nullius-climatology-pack", 1},
    {"nullius-mechanical-pack", 1}, {"nullius-electrical-pack", 1},
  }},
}
local cultivation = {
  type = "technology", name = "nullius-wild-strain-cultivation", order = "nullius-dgb",
  icon = icon_dir .. "iron-bacteria-cultivation.png", icon_size = 64,
  prerequisites = {nutrient.name}, effects = {},
  unit = {count = 8, time = 20, ingredients = {{"nullius-biochemistry-pack", 1}}},
}

data:extend({
  probe, nutrient, cultivation,
  {type = "fuel-category", name = "nullius-nutrient"},
  {type = "recipe-category", name = "gleba-hand-sampling"},
  {type = "recipe-category", name = "gleba-crushing"},
  {type = "recipe-category", name = "gleba-culture"},
  {type = "recipe-category", name = "gleba-chemosynthesis"},
  {type = "recipe-category", name = "gleba-roasting"},
})

local function item(name, image, spoil, lifetime)
  local prototype = {
    type = "item", name = "nullius-" .. name, icon = icon_dir .. image .. ".png",
    icon_size = 64, subgroup = "biology-material", order = "nullius-g-" .. name, stack_size = 100,
    spoil_result = spoil, spoil_ticks = lifetime,
  }
  data:extend({prototype})
  return prototype
end

item("gleba-rock", "iron-stromatolite")
item("mat-sample", "iron-bacteria-2")
item("crushed-gleba-rock", "tungsten-ore-1")
item("leach-residue", "calcite-2")
item("ferric-concentrate", "tungsten-ore-3")
item("culture-sludge", "spoilage-2")
item("digestate", "burnt-spoilage")
item("wild-culture", "iron-bacteria", "nullius-culture-sludge", 10 * minute)
item("domesticated-culture", "copper-bacteria", "nullius-culture-sludge", 20 * minute)
local goop = item("nutrient-goop", "nutrients", "nullius-digestate", 15 * minute)
goop.fuel_categories, goop.fuel_value, goop.burnt_result = {"nullius-nutrient"}, "8MJ", "nullius-digestate"

local raw_items = {stone = true, inserter = true}
local function item_id(name)
  return raw_items[name] and name or ("nullius-" .. name)
end

local function stacks(list)
  local result = {}
  for _, pair in ipairs(list) do
    result[#result + 1] = {type = "item", name = item_id(pair[1]), amount = pair[2]}
  end
  return result
end

local function unlock(tech, recipe)
  table.insert(tech.effects, {type = "unlock-recipe", recipe = recipe})
end

local function recipe(tech, name, category, time, ingredients, products, conditions)
  local id = "nullius-" .. name
  data:extend({{
    type = "recipe", name = id, categories = {category}, enabled = false, energy_required = time,
    ingredients = stacks(ingredients), results = stacks(products), main_product = item_id(products[1][1]),
    localised_name = {"recipe-name." .. id}, allow_productivity = false, allow_decomposition = false,
    surface_conditions = conditions and table.deepcopy(conditions) or nil,
  }})
  unlock(tech, id)
end

recipe(nutrient, "isolate-wild-culture", "gleba-hand-sampling", 12,
  {{"mat-sample", 3}}, {{"wild-culture", 2}, {"nutrient-goop", 4}}, gleba_only)
recipe(nutrient, "gleba-rock-crushing", "gleba-crushing", 2,
  {{"gleba-rock", 1}}, {{"crushed-gleba-rock", 4}})
recipe(nutrient, "gleba-stone", "gleba-crushing", 2,
  {{"gleba-rock", 2}}, {{"stone", 4}})
recipe(nutrient, "wild-culture-propagation", "gleba-culture", 6,
  {{"wild-culture", 1}, {"mat-sample", 2}}, {{"wild-culture", 4}}, gleba_only)
recipe(nutrient, "gleba-rock-leaching", "gleba-culture", 4,
  {{"crushed-gleba-rock", 2}, {"wild-culture", 1}}, {{"leach-residue", 2}, {"ferric-concentrate", 2}})
-- Fixation takes all its carbon from rock. Recycling returns spent goop with a
-- carbon loss, so it always consumes more digestate than its goop later leaves.
recipe(nutrient, "gleba-chemosynthesis", "gleba-chemosynthesis", 10,
  {{"crushed-gleba-rock", 4}, {"wild-culture", 1}}, {{"nutrient-goop", 2}})
recipe(nutrient, "gleba-digestate-recycling", "gleba-chemosynthesis", 10,
  {{"digestate", 5}, {"crushed-gleba-rock", 1}, {"wild-culture", 1}}, {{"nutrient-goop", 4}})
recipe(nutrient, "gleba-sludge-digestion", "gleba-culture", 4,
  {{"culture-sludge", 2}}, {{"digestate", 1}})
-- Assay packs cost bootstrap-grade time and materials, as the first metallurgic
-- and electromagnetic packs do.
recipe(nutrient, "gleba-biochemistry", "gleba-culture", 30,
  {{"wild-culture", 3}, {"leach-residue", 3}, {"ferric-concentrate", 2}}, {{"biochemistry-pack", 1}})
recipe(nutrient, "gleba-iron-reduction", "gleba-roasting", 4,
  {{"ferric-concentrate", 2}, {"nutrient-goop", 1}}, {{"iron-ingot", 3}})
recipe(nutrient, "gleba-silica", "gleba-roasting", 4,
  {{"leach-residue", 2}}, {{"silica", 3}})
recipe(nutrient, "gleba-motor-1", "medium-crafting", 8,
  {{"iron-wire", 2}, {"iron-plate", 1}, {"silica", 2}, {"iron-rod", 1}}, {{"motor-1", 1}}, gleba_only)
recipe(nutrient, "gleba-small-assembler-1", "small-crafting", 6,
  {{"iron-plate", 8}, {"iron-gear", 4}, {"leach-residue", 2}, {"inserter", 1}},
  {{"small-assembler-1", 1}}, gleba_only)
recipe(cultivation, "domesticate-wild-culture", "gleba-culture", 8,
  {{"wild-culture", 2}}, {{"domesticated-culture", 1}})
recipe(cultivation, "gleba-microbiology", "gleba-culture", 30,
  {{"wild-culture", 2}, {"domesticated-culture", 2}, {"glass", 1}}, {{"microbiology-pack", 1}})
unlock(cultivation, "nullius-biology-lab")

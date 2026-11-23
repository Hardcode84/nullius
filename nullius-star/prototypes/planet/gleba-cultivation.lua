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
-- Filtration are. Geology 2 supplies the crushed-mineral assays it builds on;
-- Nitrogen Chemistry 1 supplies the ammonia for single-cell protein off Gleba.
local nutrient = {
  type = "technology", name = "nullius-nutrient-technology", order = "nullius-dga",
  icon = icon_dir .. "nutrients.png", icon_size = 64,
  prerequisites = {probe.name, "nullius-geology-2", "nullius-nitrogen-chemistry-1"},
  effects = {
    {type = "nothing", effect_description = {"technology-description.nullius-bioreactor-1"}},
    {type = "unlock-recipe", recipe = "nullius-single-cell-protein"},
  },
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
item("iron-sulfide", "tungsten-ore-2")
item("wild-culture", "iron-bacteria", "nullius-culture-sludge", 10 * minute)
item("domesticated-culture", "copper-bacteria", "nullius-culture-sludge", 20 * minute)
local goop = item("nutrient-goop", "nutrients", "nullius-digestate", 15 * minute)
goop.fuel_categories, goop.fuel_value, goop.burnt_result = {"nullius-nutrient"}, "8MJ", "nullius-digestate"

-- A short name means the Nullius item when one exists, otherwise the base game item.
local function item_exists(id) return data.raw.item[id] or data.raw.tool[id] end
local function item_id(name)
  local id = item_exists("nullius-" .. name) and ("nullius-" .. name) or name
  assert(item_exists(id), "Unknown Gleba recipe item: " .. name)
  return id
end

-- A short name means a Nullius fluid when one exists, otherwise an item.
local function stacks(list)
  local result = {}
  for _, pair in ipairs(list) do
    local fluid = "nullius-" .. pair[1]
    result[#result + 1] = data.raw.fluid[fluid] and {type = "fluid", name = fluid, amount = pair[2]}
      or {type = "item", name = item_id(pair[1]), amount = pair[2]}
  end
  return result
end

local function unlock(tech, recipe)
  table.insert(tech.effects, {type = "unlock-recipe", recipe = recipe})
end

local function recipe(tech, name, category, time, ingredients, products, conditions)
  local id = "nullius-" .. name
  local results = stacks(products)
  data:extend({{
    type = "recipe", name = id, categories = {category}, enabled = false, energy_required = time,
    ingredients = stacks(ingredients), results = results, main_product = results[1].name,
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

-- Gleba chemistry takes its oxygen from the rock's ferric oxide, sulfate and carbonate.
-- Atmospheric hydrogen sulfide supplies sulfur and hydrogen, so the recipes that draw
-- on it need Gleba; reduced iron ends as iron sulfide, which smelts back to iron.
recipe(nutrient, "gleba-sulfidation", "gleba-chemosynthesis", 8,
  {{"ferric-concentrate", 2}}, {{"water", 30}, {"iron-sulfide", 1}}, gleba_only)
recipe(nutrient, "gleba-acid-liquor", "gleba-culture", 8,
  {{"ferric-concentrate", 2}, {"water", 10}, {"wild-culture", 1}},
  {{"acid-sulfuric", 20}, {"iron-sulfide", 1}}, gleba_only)
recipe(nutrient, "gleba-iron-sulfide-reduction", "gleba-roasting", 4,
  {{"iron-sulfide", 2}, {"nutrient-goop", 1}}, {{"iron-ingot", 3}})
-- Acid liquor neutralized on the rock's carbonate is Gleba's carbon dioxide.
recipe(nutrient, "gleba-neutralization", "gleba-chemosynthesis", 6,
  {{"crushed-gleba-rock", 4}, {"acid-sulfuric", 20}},
  {{"carbon-dioxide", 20}, {"gypsum", 2}, {"leach-residue", 2}})
recipe(nutrient, "gleba-gypsum-decomposition", "gleba-chemosynthesis", 6,
  {{"gypsum", 2}}, {{"oxygen", 10}, {"sulfur-dioxide", 10}, {"lime", 1}})
-- Gleba cannot vent sulfur dioxide; hydrogen sulfide reduces it onto iron.
recipe(nutrient, "gleba-sulfur-dioxide-reduction", "gleba-chemosynthesis", 6,
  {{"sulfur-dioxide", 10}, {"ferric-concentrate", 1}}, {{"water", 10}, {"iron-sulfide", 1}}, gleba_only)
-- Graphite from fixed carbon leaves the goop carbon loop.
recipe(nutrient, "gleba-digestate-pyrolysis", "gleba-chemosynthesis", 4,
  {{"digestate", 5}}, {{"graphite", 1}, {"carbon-dioxide", 10}})
recipe(nutrient, "gleba-motor-1", "medium-crafting", 8,
  {{"iron-wire", 2}, {"iron-plate", 1}, {"silica", 2}, {"iron-rod", 1}}, {{"motor-1", 1}}, gleba_only)
recipe(cultivation, "domesticate-wild-culture", "gleba-culture", 8,
  {{"wild-culture", 2}}, {{"domesticated-culture", 1}})
recipe(cultivation, "gleba-microbiology", "gleba-culture", 30,
  {{"wild-culture", 2}, {"domesticated-culture", 2}, {"glass", 1}}, {{"microbiology-pack", 1}})
unlock(cultivation, "nullius-biology-lab")

-- Off Gleba, spent and spoiled goop dissolves into sludge.
data:extend({{
  type = "recipe", name = "nullius-digestate-dissolution",
  localised_name = {"recipe-name.nullius-digestate-dissolution"},
  icon = icon_dir .. "burnt-spoilage.png", icon_size = 64,
  categories = {"nullius-water-treatment"}, subgroup = "biology-material", order = "nullius-gz-digestate",
  enabled = false, energy_required = 2,
  ingredients = {{type = "item", name = "nullius-digestate", amount = 5}, {type = "fluid", name = "nullius-water", amount = 50}},
  results = {{type = "fluid", name = "nullius-sludge", amount = 50}}, main_product = "nullius-sludge",
  allow_productivity = false, allow_decomposition = false,
}})
unlock(nutrient, "nullius-digestate-dissolution")

-- Gleba air is nitrogen and hydrogen sulfide, without the carbon dioxide of
-- ordinary air, so it is its own fluid and ordinary air recipes never take it.
-- Nutrient air filters make it; a fixed recipe ignores recipe surface conditions.
local air_icons = angelsLegacy.functions.create_gas_fluid_icon(nil,
  {element_tint["nitrogen"], element_tint["sulfur"], element_tint["nitrogen"]})
local air_color = {r = 150, g = 170, b = 60}
local void = table.deepcopy(assert(data.raw.recipe["nullius-void-air"]))
void.name, void.icons = "nullius-void-gleba-air", table.deepcopy(air_icons)
void.crafting_machine_tint = {primary = air_color}
void.ingredients = {{type = "fluid", name = "nullius-gleba-air", amount = 200}}
data:extend({
  {
    type = "fluid", name = "nullius-gleba-air", icons = air_icons,
    subgroup = "air-filtration", order = "nullius-bg", base_color = air_color, flow_color = air_color,
    heat_capacity = "0.04kJ", default_temperature = 25, max_temperature = 100, gas_temperature = 0,
    -- Nothing ships Gleba air yet, so it has no barrel.
    auto_barrel = false,
  },
  {
    type = "recipe", name = "nullius-gleba-air", localised_name = {"fluid-name.nullius-gleba-air"},
    enabled = true, hide_from_player_crafting = true, categories = {"air-filtration"},
    subgroup = "air-filtration-recipe", order = "nullius-bg", energy_required = 3, ingredients = {},
    results = {{type = "fluid", name = "nullius-gleba-air", amount = 150}}, main_product = "nullius-gleba-air",
  },
  {
    type = "recipe", name = "nullius-gleba-air-separation",
    localised_name = {"recipe-name.nullius-gleba-air-separation"},
    icons = table.deepcopy(assert(data.raw.fluid["nullius-nitrogen"]).icons),
    enabled = true, allow_decomposition = false, categories = {"distillation"},
    subgroup = "air-filtration-recipe", order = "nullius-bh",
    crafting_machine_tint = {primary = air_color}, energy_required = 1,
    ingredients = {{type = "fluid", name = "nullius-gleba-air", amount = 150}},
    results = {{type = "fluid", name = "nullius-nitrogen", amount = 90}},
    main_product = "nullius-nitrogen", surface_conditions = table.deepcopy(gleba_only),
  },
  void,
})

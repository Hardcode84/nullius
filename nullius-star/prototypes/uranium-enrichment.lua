-- Fluorine chemistry, uranium conversion to hexafluoride, centrifuge
-- enrichment, and deconversion. UF6 moves in cylinder items because the
-- centrifuge has no fluid boxes.

local CYLINDER_ICON = "__nullius-star__/graphics/icons/canister-empty.png"
local yellowcake = data.raw.item["nullius-yellowcake"].icons[1]

local function cylinder_icons(tint, overlay)
  local icons = {{icon = CYLINDER_ICON, icon_size = 64, tint = tint}}
  if overlay then
    icons[2] = {icon = overlay.icon, icon_size = overlay.icon_size, tint = overlay.tint,
      scale = 0.25, shift = {-8, -8}}
  end
  return icons
end

local function item(name, icons, order, stack_size)
  return {type = "item", name = name, icons = icons, subgroup = "uranium", order = order,
    stack_size = stack_size or 50}
end

local function recipe(spec)
  return {
    type = "recipe",
    name = spec.name,
    localised_name = spec.localised_name,
    enabled = false,
    categories = {spec.category},
    always_show_made_in = true,
    show_amount_in_title = false,
    always_show_products = true,
    energy_required = spec.time,
    no_productivity = spec.no_productivity,
    ingredients = spec.ingredients,
    results = spec.results,
    main_product = spec.main_product
  }
end

local function stack(name, amount, ignored)
  return {type = "item", name = name, amount = amount, ignored_by_productivity = ignored}
end

local function fluid(name, amount, ignored)
  return {type = "fluid", name = name, amount = amount, ignored_by_productivity = ignored}
end

-- Deconversion returns the cylinder and the fluoride, so neither may gain
-- productivity: the fluoride loss is what fluorite tops up.
local function deconversion(name, source, product)
  return recipe{name = name, localised_name = {"recipe-name." .. name}, category = "basic-chemistry", time = 4,
    ingredients = {stack(source, 1), fluid("nullius-steam", 20), fluid("nullius-hydrogen", 20)},
    results = {stack(product, 1), fluid("nullius-hydrogen-fluoride", 50, 50), stack("nullius-uf6-cylinder", 1, 1)},
    main_product = product}
end

local centrifuge = table.deepcopy(data.raw["assembling-machine"]["centrifuge"])
centrifuge.name = "nullius-centrifuge"
centrifuge.minable = {mining_time = 1, result = "nullius-centrifuge"}
centrifuge.fast_replaceable_group = nil
centrifuge.next_upgrade = nil
centrifuge.crafting_categories = {"nullius-centrifuging"}
centrifuge.crafting_speed = 1
-- Enrichment conserves cylinders and uranium, so the centrifuge takes no
-- productivity.
centrifuge.allowed_effects = {"speed", "consumption", "pollution"}

data:extend({
  {type = "recipe-category", name = "nullius-centrifuging"},
  {
    type = "item",
    name = "nullius-fluorite",
    icon = "__angelspetrochemgraphics__/graphics/icons/ore-fluorite.png",
    icon_size = 32,
    subgroup = "calcium-product",
    order = "nullius-fb",
    stack_size = 50
  },
  item("nullius-uranium-dioxide", {{icon = "__angelssmeltinggraphics__/graphics/icons/powder-lead.png",
    icon_size = 64, tint = {0.35, 0.3, 0.25}}}, "nullius-da"),
  item("nullius-uranium-tetrafluoride", {{icon = "__angelssmeltinggraphics__/graphics/icons/powder-silica.png",
    icon_size = 64, tint = {0.45, 0.85, 0.35}}}, "nullius-db"),
  item("nullius-uf6-cylinder", cylinder_icons({0.6, 0.6, 0.6}), "nullius-dc", 20),
  item("nullius-natural-uf6", cylinder_icons({0.95, 0.9, 0.55}, yellowcake), "nullius-dd", 20),
  item("nullius-low-enriched-uf6", cylinder_icons({0.7, 0.95, 0.55},
    {icon = "__base__/graphics/icons/uranium-235.png", icon_size = 64, tint = {0.7, 1, 0.7}}), "nullius-de", 20),
  item("nullius-reactor-grade-uf6", cylinder_icons({0.35, 0.95, 0.35},
    {icon = "__base__/graphics/icons/uranium-235.png", icon_size = 64}), "nullius-df", 20),
  item("nullius-depleted-uf6", cylinder_icons({0.5, 0.55, 0.5},
    {icon = "__base__/graphics/icons/uranium-238.png", icon_size = 64}), "nullius-dg", 20),
  {
    type = "item",
    name = "nullius-centrifuge",
    icon = "__base__/graphics/icons/centrifuge.png",
    icon_size = 64,
    place_result = "nullius-centrifuge",
    subgroup = "nuclear",
    order = "nullius-bb",
    stack_size = 20
  },
  centrifuge,

  -- The calcite leaves as gravel, dust, and sludge tailings. Recovering calcite
  -- from them returns less than a cycle consumes, so it cannot be refloated
  -- for fluorite indefinitely.
  recipe{name = "nullius-fluorite", category = "ore-flotation", time = 6,
    ingredients = {stack("nullius-crushed-limestone", 10), fluid("nullius-water", 100)},
    results = {stack("nullius-fluorite", 1), stack("nullius-gravel", 3), stack("nullius-mineral-dust", 4),
      fluid("nullius-sludge", 50)},
    main_product = "nullius-fluorite"},
  recipe{name = "nullius-hydrogen-fluoride", category = "basic-chemistry", time = 2,
    ingredients = {stack("nullius-fluorite", 1), fluid("nullius-acid-sulfuric", 10)},
    results = {fluid("nullius-hydrogen-fluoride", 20), stack("nullius-gypsum", 1)},
    main_product = "nullius-hydrogen-fluoride"},
  recipe{name = "nullius-uranium-dioxide", category = "wet-smelting", time = 4,
    ingredients = {stack("nullius-yellowcake", 1), fluid("nullius-hydrogen", 20)},
    results = {stack("nullius-uranium-dioxide", 1), fluid("nullius-water", 10)},
    main_product = "nullius-uranium-dioxide"},
  recipe{name = "nullius-uranium-tetrafluoride", category = "basic-chemistry", time = 3,
    ingredients = {stack("nullius-uranium-dioxide", 1), fluid("nullius-hydrogen-fluoride", 40)},
    results = {stack("nullius-uranium-tetrafluoride", 1), fluid("nullius-wastewater", 20)},
    main_product = "nullius-uranium-tetrafluoride"},
  recipe{name = "nullius-uf6-cylinder", category = "medium-crafting", time = 5,
    ingredients = {stack("nullius-steel-sheet", 2), stack("nullius-one-way-valve", 1)},
    results = {stack("nullius-uf6-cylinder", 1)}},
  -- Productivity would fill a cylinder that was never consumed.
  recipe{name = "nullius-natural-uf6", category = "basic-chemistry", time = 2, no_productivity = true,
    ingredients = {stack("nullius-uranium-tetrafluoride", 1), stack("nullius-uf6-cylinder", 1),
      fluid("nullius-fluorine", 10)},
    results = {stack("nullius-natural-uf6", 1)}},
  recipe{name = "nullius-low-enriched-uf6", localised_name = {"recipe-name.nullius-low-enriched-uf6"},
    category = "nullius-centrifuging", time = 20,
    ingredients = {stack("nullius-natural-uf6", 5)},
    results = {stack("nullius-low-enriched-uf6", 1), stack("nullius-depleted-uf6", 4)},
    main_product = "nullius-low-enriched-uf6"},
  -- The stripped stream returns to the first stage as natural feed.
  recipe{name = "nullius-reactor-grade-uf6", localised_name = {"recipe-name.nullius-reactor-grade-uf6"},
    category = "nullius-centrifuging", time = 20,
    ingredients = {stack("nullius-low-enriched-uf6", 2)},
    results = {stack("nullius-reactor-grade-uf6", 1), stack("nullius-natural-uf6", 1)},
    main_product = "nullius-reactor-grade-uf6"},
  deconversion("nullius-enriched-uranium-deconversion", "nullius-reactor-grade-uf6", "nullius-enriched-uranium"),
  deconversion("nullius-uranium-deconversion", "nullius-depleted-uf6", "nullius-uranium"),
  recipe{name = "nullius-centrifuge", category = "large-crafting", time = 30,
    ingredients = {stack("nullius-steel-plate", 20), stack("nullius-carbon-fiber", 10),
      stack("nullius-motor-2", 4), stack("nullius-processor-2", 2)},
    results = {stack("nullius-centrifuge", 1)}}
})

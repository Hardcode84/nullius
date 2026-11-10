-- given: Electrolysis 4 and Seawater Uranium Adsorption researched by a fresh force on Nauvis;
--   Fluorine Chemistry, Uranium Processing, and Uranium Enrichment researched in order.
-- place: one machine per fluorine, conversion, enrichment, and deconversion recipe, each on a 10 MW grid.
-- connect: infinity pipes supply each fluid ingredient at its port and drain each fluid product.
-- act: insert one batch of each item ingredient, or one fluid batch for electrolysis; the batch limits
--   each machine to one craft.
-- run: until every machine has finished its craft.
-- expect: each recipe locked until its research, one craft per recipe, exact item outputs including
--   returned cylinders and the cascade return stream, recorded fluid production and consumption, and
--   most of each fluid product drained through its port.
local rows = require("__nullius-star__/scenarios/recipe-rows")
local deconversion = {machine = "nullius-chemical-plant-1",
  sources = {["nullius-steam"] = 20, ["nullius-hydrogen"] = 20}, sinks = {["nullius-hydrogen-fluoride"] = 50}}
local function with(base, row)
  for key, value in pairs(base) do row[key] = value end
  return row
end
rows.run{
  case = "uranium-enrichment",
  prerequisites = {"nullius-electrolysis-4", "nullius-seawater-uranium-adsorption"},
  -- The centrifuge stages take 20 seconds at crafting speed 1.
  check_tick = rows.setup_tick + 1200 + 60,
  stages = {
    {technology = "nullius-fluorine-chemistry", rows = {
      {machine = "nullius-flotation-cell-1", recipe = "nullius-fluorite",
        items = {["nullius-crushed-limestone"] = 10}, sources = {["nullius-water"] = 100},
        sinks = {["nullius-sludge"] = 50},
        outputs = {["nullius-fluorite"] = 1, ["nullius-gravel"] = 3, ["nullius-mineral-dust"] = 4}},
      {machine = "nullius-chemical-plant-1", recipe = "nullius-hydrogen-fluoride",
        items = {["nullius-fluorite"] = 1}, sources = {["nullius-acid-sulfuric"] = 10},
        sinks = {["nullius-hydrogen-fluoride"] = 20}, outputs = {["nullius-gypsum"] = 1}},
      {machine = "nullius-priority-electrolyzer-1", recipe = "nullius-hydrogen-fluoride-electrolysis",
        fluids = {["nullius-hydrogen-fluoride"] = 240},
        sinks = {["nullius-hydrogen"] = 120, ["nullius-fluorine"] = 120}},
    }},
    {technology = "nullius-uranium-processing", rows = {
      {machine = "nullius-medium-furnace-2", recipe = "nullius-uranium-dioxide",
        items = {["nullius-yellowcake"] = 1}, sources = {["nullius-hydrogen"] = 20},
        sinks = {["nullius-water"] = 10}, outputs = {["nullius-uranium-dioxide"] = 1}},
      {machine = "nullius-chemical-plant-1", recipe = "nullius-uranium-tetrafluoride",
        items = {["nullius-uranium-dioxide"] = 1}, sources = {["nullius-hydrogen-fluoride"] = 40},
        sinks = {["nullius-wastewater"] = 20}, outputs = {["nullius-uranium-tetrafluoride"] = 1}},
      {machine = "nullius-small-assembler-1", recipe = "nullius-uf6-cylinder",
        items = {["nullius-steel-sheet"] = 2, ["nullius-one-way-valve"] = 1},
        outputs = {["nullius-uf6-cylinder"] = 1}},
      {machine = "nullius-chemical-plant-1", recipe = "nullius-natural-uf6",
        items = {["nullius-uranium-tetrafluoride"] = 1, ["nullius-uf6-cylinder"] = 1},
        sources = {["nullius-fluorine"] = 10}, outputs = {["nullius-natural-uf6"] = 1}},
    }},
    {technology = "nullius-uranium-enrichment", rows = {
      {machine = "nullius-centrifuge", recipe = "nullius-low-enriched-uf6",
        items = {["nullius-natural-uf6"] = 5},
        outputs = {["nullius-low-enriched-uf6"] = 1, ["nullius-depleted-uf6"] = 4}},
      {machine = "nullius-centrifuge", recipe = "nullius-reactor-grade-uf6",
        items = {["nullius-low-enriched-uf6"] = 2},
        outputs = {["nullius-reactor-grade-uf6"] = 1, ["nullius-natural-uf6"] = 1}},
      with(deconversion, {recipe = "nullius-enriched-uranium-deconversion",
        items = {["nullius-reactor-grade-uf6"] = 1},
        outputs = {["nullius-enriched-uranium"] = 1, ["nullius-uf6-cylinder"] = 1}}),
      with(deconversion, {recipe = "nullius-uranium-deconversion",
        items = {["nullius-depleted-uf6"] = 1},
        outputs = {["nullius-uranium"] = 1, ["nullius-uf6-cylinder"] = 1}}),
    }},
  },
}

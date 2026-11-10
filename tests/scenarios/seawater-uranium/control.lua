-- given: Seawater Uranium Adsorption researched by a fresh force on Nauvis.
-- place: nanofabricator 1, hydro plant 1, and two flotation cells 1, each on a 10 MW grid.
-- connect: infinity pipes supply each fluid ingredient at its port and drain each fluid product.
-- act: insert one batch of each item ingredient; the item ingredient limits each machine to one craft.
-- run: until every machine has finished its craft.
-- expect: one craft per recipe, exact item outputs, recorded fluid production and consumption,
--   and most of each fluid product drained through its port.
local rows = require("__nullius-star__/scenarios/recipe-rows")
rows.run{
  case = "seawater-uranium",
  prerequisites = {"nullius-biochemistry-4"},
  -- The slowest recipe takes 12 seconds at crafting speed 1.
  check_tick = rows.setup_tick + 720 + 60,
  stages = {{technology = "nullius-seawater-uranium-adsorption", rows = {
    {machine = "nullius-nanofabricator-1", recipe = "nullius-uranyl-binding-fiber",
      items = {["nullius-acrylic-fiber"] = 4}, sources = {["nullius-amino-acids"] = 2},
      outputs = {["nullius-uranyl-binding-fiber"] = 4}},
    {machine = "nullius-hydro-plant-1", recipe = "nullius-loaded-uranyl-fiber",
      items = {["nullius-uranyl-binding-fiber"] = 1}, sources = {["nullius-seawater"] = 1000},
      sinks = {["nullius-saline"] = 700, ["nullius-sludge"] = 50},
      outputs = {["nullius-loaded-uranyl-fiber"] = 1}},
    {machine = "nullius-flotation-cell-1", recipe = "nullius-uranyl-solution",
      items = {["nullius-loaded-uranyl-fiber"] = 10}, sources = {["nullius-acid-hydrochloric"] = 25},
      sinks = {["nullius-uranyl-solution"] = 20}, outputs = {["nullius-uranyl-binding-fiber"] = 9}},
    {machine = "nullius-flotation-cell-1", recipe = "nullius-yellowcake-precipitation",
      items = {["nullius-sodium-hydroxide"] = 1}, sources = {["nullius-uranyl-solution"] = 10},
      sinks = {["nullius-wastewater"] = 10}, outputs = {["nullius-yellowcake"] = 1}},
  }}},
}

-- Keep real collision boxes and fluid ports; use base graphics and void power.
local modern = require("factorio-version").is_2_1
local declarations = require("declarations")
for _, declaration in ipairs(declarations) do
  assert(declaration.forced_symmetry == (not modern and "horizontal" or nil))
  assert(declaration.use_mirroring == (modern or nil))
end
local contracts = {}
for _, layout in ipairs(require("layouts")) do
  local p = table.deepcopy(data.raw["assembling-machine"]["assembling-machine-2"])
  p.name = layout.name
  p.next_upgrade = nil
  p.minable = nil
  p.energy_source = {type="void"}
  p.crafting_categories = {"mirroring-test"}
  for key, value in pairs(layout) do p[key] = table.deepcopy(value) end
  p.forced_symmetry = declarations[1].forced_symmetry
  p.use_mirroring = declarations[1].use_mirroring
  local recipe = {type="recipe", name=p.name, ingredients={}, results={}, energy_required=1000,
    icon="__base__/graphics/icons/iron-plate.png", icon_size=64}
  if modern then recipe.categories={"mirroring-test"} else recipe.category="mirroring-test" end
  local fluids = {}
  for index, box in ipairs(p.fluid_boxes) do
    -- Remove only artwork and fluid identity; preserve each port's geometry.
    box.pipe_picture = nil
    box.pipe_covers = nil
    box.filter = nil
    local name = "mirroring-fluid-" .. index
    if not data.raw.fluid[name] then
      local f = table.deepcopy(data.raw.fluid.water)
      f.name = name
      data:extend({f})
    end
    fluids[index] = name
    local entries = box.production_type == "output" and recipe.results or recipe.ingredients
    entries[#entries+1] = {type="fluid", name=name, amount=1, fluidbox_index=#entries+1}
  end
  if #recipe.results == 0 then recipe.results={{type="item", name="iron-plate", amount=1}} end
  contracts[#contracts+1] = {name=p.name, fluids=fluids, boxes=p.fluid_boxes}
  data:extend({p, recipe})
end
-- The category must exist before prototype validation.
data:extend({{type="recipe-category", name="mirroring-test"},
  {type="mod-data", name="mirroring-contracts", data={machines=contracts}}})

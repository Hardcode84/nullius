local check_research = mods["factorio-test-support"] and require("__factorio-test-support__/launch-research")()
local technology = data.raw.technology
local fuel = technology["nullius-rocket-science-1"]
local rocket_tech = technology["nullius-rocket-science-2"]
local checkpoint = "nullius-checkpoint-rocket-fuel"
local inherited = {
  [fuel.name] = table.deepcopy(fuel.prerequisites),
  [checkpoint] = table.deepcopy(fuel.prerequisites),
  [rocket_tech.name] = table.deepcopy(rocket_tech.prerequisites),
}
for name, tech in pairs(technology) do
  if not inherited[name] then
    local required = {}
    for _, prerequisite in ipairs(tech.prerequisites or {}) do required[prerequisite] = true end
    for _, prerequisite in ipairs(table.deepcopy(tech.prerequisites or {})) do
      for _, parent in ipairs(inherited[prerequisite] or {}) do
        if not required[parent] then
          tech.prerequisites[#tech.prerequisites + 1] = parent
          required[parent] = true
        end
      end
    end
  end
end
fuel.prerequisites = {"nullius-physics"}
rocket_tech.prerequisites = {checkpoint, "nullius-composites-2"}
fuel.unit = table.deepcopy(technology["nullius-composites-2"].unit)
rocket_tech.unit = table.deepcopy(fuel.unit)

local function item(name, amount)
  return {type = "item", name = name, amount = amount}
end
local stage = table.deepcopy(data.raw.recipe["nullius-rocket"])
stage.name = "nullius-rocket-stage"
stage.categories = {"huge-crafting"}
stage.hide_from_player_crafting = false
stage.energy_required = 400
stage.allow_productivity = false
stage.maximum_productivity = 0
stage.ingredients = {
  item("nullius-box-rocket-fuel", 50),
  item("nullius-box-carbon-composite", 40),
  item("nullius-box-aluminum-sheet", 60),
  item("nullius-box-steel-beam", 20),
  item("nullius-haste-module-2", 2),
  item("radar", 3),
  item("nullius-box-heat-pipe-2", 6),
  item("nullius-box-insulation", 12),
  item("nullius-box-ceramic-powder", 20),
  item("nullius-box-gate", 1),
}
stage.results = {item(stage.name, 1)}
local titanium = table.deepcopy(stage)
titanium.name = "nullius-titanium-rocket-stage"
titanium.localised_name = {"recipe-name.nullius-titanium-rocket-stage"}
titanium.energy_required = 200
titanium.ingredients = {}
for _, ingredient in ipairs(stage.ingredients) do
  if ingredient.name ~= "nullius-box-aluminum-sheet" and ingredient.name ~= "nullius-box-steel-beam" then
    local input = table.deepcopy(ingredient)
    if input.name == "nullius-box-rocket-fuel" then input.amount = 25 end
    titanium.ingredients[#titanium.ingredients + 1] = input
  end
end
titanium.ingredients[#titanium.ingredients + 1] = item("nullius-box-titanium-sheet", 30)
local stage_item = table.deepcopy(data.raw.item["nullius-rocket"])
stage_item.name = stage.name
stage_item.order = "nullius-bb"
stage_item.localised_name = {"item-name.nullius-rocket-stage"}
stage_item.auto_recycle = false
data:extend({stage_item, stage, titanium})
for _, recipe in ipairs({stage.name, titanium.name}) do
  rocket_tech.effects[#rocket_tech.effects + 1] = {type = "unlock-recipe", recipe = recipe}
end
local rocket = data.raw.recipe["nullius-rocket"]
rocket.ingredients = {item(stage.name, 1)}
rocket.energy_required = 60
rocket.allow_productivity = true
local silo_recipe = data.raw.recipe["nullius-silo"]
silo_recipe.ingredients = {
  item("nullius-drone-launcher-1", 5), item("nullius-hangar-2", 2),
  item("nullius-beacon-1", 4), item("nullius-box-wall", 10),
  item("nullius-box-heat-pipe-2", 4), item("nullius-box-hazard-concrete", 30),
  item("nullius-box-productivity-module-1", 1), item("nullius-lab-2", 1),
}
local silo = data.raw["rocket-silo"]["nullius-silo"]
silo.launch_to_space_platforms = true
silo.to_be_inserted_to_rocket_inventory_size = nil

if check_research then check_research() end

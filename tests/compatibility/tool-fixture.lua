local modern = string.match(mods.base, "^2%.1%.") ~= nil
local machine = table.deepcopy(data.raw["assembling-machine"]["chemical-plant"])
machine.name = "compat-machine"
machine.minable = {mining_time=0.1, result="compat-machine"}
machine.crafting_categories = {"compat-secondary"}
machine.crafting_speed = 1
machine.energy_source = {type="void"}
machine.energy_usage = "1W"
local recipe = {
  type="recipe", name="compat-recipe", enabled=true, energy_required=1,
  icons={{icon="__base__/graphics/icons/copper-plate.png"}},
  ingredients={{type="item", name="iron-plate", amount=1},
    {type="fluid", name="water", amount=50, fluidbox_index=1}},
  results={{type="item", name="copper-plate", amount=2},
    {type="fluid", name="steam", amount=10, fluidbox_index=1}},
}
if modern then
  recipe.categories = {"compat-primary", "compat-secondary"}
  recipe.ingredients[2].optional_fluidbox_indexes = {2, 99}
  recipe.results[2].optional_fluidbox_indexes = {2, 99}
else
  recipe.category = "compat-primary"
  recipe.additional_categories = {"compat-secondary"}
end
local uncertain = table.deepcopy(recipe)
uncertain.name = "compat-uncertain"
uncertain.results[1][modern and "independent_probability" or "probability"] = 0.5
local shared = table.deepcopy(recipe)
shared.name = "compat-shared"
if modern then
  shared.results[1].shared_probability = {min=0.25, max=0.75}
else
  shared.results[1].probability = 0.5
end
data:extend({machine,
  {type="item", name="compat-machine", stack_size=10, place_result="compat-machine",
    icon="__base__/graphics/icons/chemical-plant.png"},
  {type="recipe-category", name="compat-primary"},
  {type="recipe-category", name="compat-secondary"},
  recipe, uncertain, shared,
  {type="fluid", name="compat-fuel", default_temperature=15, heat_capacity="1kJ",
    fuel_value="1MJ", base_color={1,0,0}, flow_color={1,0,0},
    icon="__base__/graphics/icons/fluid/water.png"},
})

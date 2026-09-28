local category = "nullius-electromagnetism-1"
local name = "nullius-electromagnetic-pack"
local recipe = {
  type="recipe", name=name, enabled=false, energy_required=20,
  always_show_made_in=true, allow_productivity=true,
  surface_conditions={{property="magnetic-field",min=99,max=99}},
  ingredients={
    {type="item",name="nullius-iron-plate",amount=2},
    {type="item",name="copper-cable",amount=4},
    {type="item",name="nullius-graphite",amount=2},
  },
  results={{type="item",name=name,amount=1}},
}
if require("factorio-version").is_2_1 then
  recipe.categories={category}
else
  recipe.category=category
end
data:extend({
  {type="recipe-category",name=category},
  {
    type="tool",name=name,
    icon="__space-age__/graphics/icons/electromagnetic-science-pack.png",icon_size=64,
    subgroup="research-pack",order="nullius-w",stack_size=200,durability=1,
    durability_description_key="description.science-pack-remaining-amount-key",
    durability_description_value="description.science-pack-remaining-amount-value",
  },
  recipe,
})
table.insert(data.raw.technology["nullius-primitive-filtration"].effects,
  {type="unlock-recipe",recipe=name})

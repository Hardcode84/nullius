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

require("prototypes.item.boxing")("electromagnetic-pack", "science", "w", nil, "tool")
for _, spec in ipairs({
  {tier=2,name="nullius-electromagnetic-pack-improved",seconds=15,
    ingredients={{"nullius-capacitor",1},{"decider-combinator",1},{"copper-cable",2}},
    product=name,subgroup="research-pack-2"},
  {tier=3,name="nullius-boxed-electromagnetic-pack",seconds=75,
    ingredients={{"nullius-box-capacitor",1},{"nullius-box-logic-circuit",1},
      {"nullius-box-insulated-wire",2}},
    product="nullius-box-electromagnetic-pack",subgroup="boxed-science"},
}) do
  local advanced=table.deepcopy(recipe)
  advanced.name=spec.name
  advanced.energy_required=spec.seconds
  advanced.subgroup=spec.subgroup
  advanced.order="nullius-w" .. spec.tier
  advanced.ingredients={}
  for _,ingredient in ipairs(spec.ingredients) do
    table.insert(advanced.ingredients,{type="item",name=ingredient[1],amount=ingredient[2]})
  end
  advanced.results={{type="item",name=spec.product,amount=5}}
  if spec.tier==2 then
    advanced.localised_name={"recipe-name.nullius-electromagnetic-pack-improved"}
  end
  if require("factorio-version").is_2_1 then
    advanced.categories={"nullius-electromagnetism-" .. spec.tier}
  else
    advanced.category="nullius-electromagnetism-" .. spec.tier
  end
  data:extend({{type="recipe-category",name="nullius-electromagnetism-" .. spec.tier},advanced})
end

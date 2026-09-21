require("legacyAngels")
local modern=require("factorio-version").is_2_1
local cases=require("scenarios/void-products/fixture")
for _,case in ipairs(cases) do
  local fluid=data.raw.fluid[case.fluid]
  if not fluid then
    fluid=table.deepcopy(data.raw.fluid.water)
    fluid.name=case.fluid
    data:extend({fluid})
  end
  fluid.icons=fluid.icons or {{icon=fluid.icon,icon_size=fluid.icon_size or 64}}
end
for _,name in ipairs({"nullius-liquid-void","nullius-gas-void","nullius-power-sink","turbine-open","turbine-closed"}) do
  if not data.raw["recipe-category"][name] then
    data:extend({{type="recipe-category",name=name}})
  end
  data:extend({{type="item-subgroup",name=name,group="fluids",order="z"}})
end
-- A secondary category must select the same decoration as a primary category.
local probes={}
for _,category in ipairs({"nullius-liquid-void","nullius-gas-void","turbine-open","turbine-closed","crafting-with-fluid"}) do
  local recipe={type="recipe",name="void-category-probe-"..category,
    icons={{icon="__base__/graphics/icons/fluid/water.png",icon_size=64}},
    ingredients={{type="fluid",name="water",amount=1}},
    results={{type="item",name="stone",amount=1}}}
  if modern then recipe.categories={"crafting-with-fluid",category} else recipe.category=category end
  if category=="crafting-with-fluid" and modern then recipe.categories={"crafting-with-fluid"} end
  data:extend({recipe})
  probes[category]=recipe
end
require("void-recipes")
local cross="__nullius-star__/graphics/icons/red_cross.png"
local energy="__nullius-star__/graphics/icons/fluid/energy.png"
for _,case in ipairs(cases) do
  local recipe=data.raw.recipe[case.name]
  if modern then
    assert(recipe.category==nil and #recipe.categories==1 and recipe.categories[1]==case.product,"native category set")
  else
    assert(recipe.categories==nil and recipe.category==case.product,"native scalar category")
  end
  if case.product~="nullius-power-sink" then
    assert(recipe.localised_name[1]=="recipe-name."..case.product,"disposal name")
    assert(recipe.localised_name[2][1]=="fluid-name."..case.fluid,"fluid name")
    assert(recipe.icons[#recipe.icons].icon==cross,"disposal overlay")
  end
end
for category,recipe in pairs(probes) do
  if category=="nullius-liquid-void" or category=="nullius-gas-void" then
    assert(recipe.localised_name[1]=="recipe-name."..category,"category name")
    assert(recipe.localised_name[2][1]=="fluid-name.water","category fluid name")
    assert(#recipe.icons==2 and recipe.icons[2].icon==cross,"category cross")
  elseif category=="turbine-open" then
    assert(#recipe.icons==3 and recipe.icons[2].icon==energy and recipe.icons[3].icon==cross,"open turbine icons")
  elseif category=="turbine-closed" then
    assert(#recipe.icons==2 and recipe.icons[2].icon==energy,"closed turbine icons")
  else
    assert(#recipe.icons==1 and recipe.localised_name==nil,"other category unchanged")
  end
end
for _,case in ipairs(require("scenarios/turbine-recipes/fixture")) do
  local recipe=data.raw.recipe[case.name]
  if case.category=="turbine-open" then
    assert(#recipe.icons==3 and recipe.icons[2].icon==energy and recipe.icons[3].icon==cross,case.name.." open icons")
  elseif case.category=="turbine-closed" then
    assert(#recipe.icons==2 and recipe.icons[2].icon==energy,case.name.." closed icons")
  end
end

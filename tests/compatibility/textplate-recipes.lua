local modern=require("factorio-version").is_2_1
data:extend({{type="recipe-category",name="medium-crafting"}})
local cases=table.deepcopy(require("scenarios/textplate-recipes/fixture"))
cases[#cases+1]={material="brass",input="iron-plate"}
for _,case in ipairs(cases) do
  if not data.raw.item[case.input] then
    data:extend({{type="item",name=case.input,icon="__base__/graphics/icons/iron-plate.png",stack_size=100}})
  end
  for _,size in ipairs({"small","large"}) do
    local name="textplate-"..size.."-"..case.material
    data:extend({
      {type="item",name=name,icon="__base__/graphics/icons/iron-plate.png",stack_size=100,localised_name={"fixture.original"}},
      {type="simple-entity-with-force",name=name,icon="__base__/graphics/icons/iron-plate.png",localised_name={"fixture.original"},picture={filename="__core__/graphics/empty.png",size=1}},
    })
    local recipe=table.deepcopy(data.raw.recipe["iron-gear-wheel"])
    recipe.name=name
    recipe.results={{type="item",name=name,amount=1}}
    recipe.energy_required=7
    recipe.enabled=true
    recipe.order="probe"
    if modern then recipe.categories={"crafting","advanced-crafting"} else recipe.category="crafting" end
    data:extend({recipe})
  end
end
for _,name in ipairs({"nullius-mechanical-separation","nullius-empiricism-1","nullius-empiricism-2","nullius-miniaturization-2","nullius-typesetting-1","nullius-typesetting-2","nullius-typesetting-3","nullius-typesetting-4"}) do
  local tech=table.deepcopy(data.raw.technology.automation)
  tech.name=name
  tech.effects={}
  tech.prerequisites={"automation"}
  data:extend({tech})
end
require("executor")

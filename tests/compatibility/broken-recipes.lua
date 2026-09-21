local cases=require("scenarios/broken-recipes/fixture")
for _,name in ipairs({"large-crafting","hand-casting"}) do
  if not data.raw["recipe-category"][name] then data:extend({{type="recipe-category",name=name}}) end
end
data:extend({{type="item-subgroup",name="broken",group="production",order="z"}})
for _,case in ipairs(cases) do
  for _,parts in ipairs({case.ingredients,case.products}) do
    for _,part in ipairs(parts) do
      if not data.raw.item[part.name] then
        data:extend({{type="item",name=part.name,stack_size=100,
          icons={{icon="__base__/graphics/icons/iron-plate.png",icon_size=64}}}})
      end
      local item=data.raw.item[part.name]
      item.icons=item.icons or {{icon=item.icon,icon_size=item.icon_size or 64}}
    end
  end
end
require("broken-recipes-source")
for _,case in ipairs(cases) do
  local recipe=data.raw.recipe[case.name]
  assert(recipe.allow_as_intermediate==false and recipe.allow_decomposition==false,case.name.." repair restrictions")
  assert(recipe.no_productivity==true and recipe.enabled==false,case.name.." repair unlock and productivity")
  assert(recipe.localised_name[1]=="recipe-name.nullius-repair",case.name.." repair name")
  assert(not data.raw.item["nullius-box-"..case.name:sub(9)],case.name.." no boxed wreck")
end

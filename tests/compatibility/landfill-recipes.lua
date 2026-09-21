local cases=require("scenarios/landfill-recipes/fixture")
for _,case in ipairs(cases) do
  if not data.raw["recipe-category"][case.category] then data:extend({{type="recipe-category",name=case.category}}) end
  for _,parts in ipairs({case.ingredients,case.products}) do
    for _,part in ipairs(parts) do
      if part.type=="fluid" and not data.raw.fluid[part.name] then
        local fluid=table.deepcopy(data.raw.fluid.water)
        fluid.name=part.name
        data:extend({fluid})
      end
    end
  end
end
for _,name in ipairs({"terrain","boxed-land-fill","masonry","dumping","boxed-dumping","biology-material"}) do
  if not data.raw["item-subgroup"][name] then data:extend({{type="item-subgroup",name=name,group="production",order="z"}}) end
end
-- Tile definitions have a separate API contract; supply item placement targets.
for _,suffix in ipairs({"sand","bauxite","iron","limestone"}) do
  local tile=table.deepcopy(data.raw.tile.landfill)
  tile.name="nullius-land-fill-"..suffix
  data:extend({tile})
end
require("landfill-source")
local function has_item(name)
  for _,kind in ipairs({"item","gun","ammo","selection-tool","capsule","module","tool","repair-tool","item-with-entity-data"}) do
    if data.raw[kind][name] then return true end
  end
  return false
end
for _,case in ipairs(cases) do
  assert(data.raw.recipe[case.name].enabled==false,case.name.." research required")
  for _,parts in ipairs({case.ingredients,case.products}) do
    for _,part in ipairs(parts) do
      if part.type=="item" and not has_item(part.name) then
        data:extend({{type="item",name=part.name,stack_size=100,icon="__base__/graphics/icons/iron-plate.png"}})
      end
    end
  end
end

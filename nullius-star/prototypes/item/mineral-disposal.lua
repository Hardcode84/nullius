local ICONPATH = "__nullius-star__/graphics/icons/"

-- Cold data-stage path: dry sand disposal, with the same bulk ratio.
for _,boxed in ipairs({false,true}) do
  local prefix = boxed and "nullius-boxed-" or "nullius-"
  local item = boxed and "nullius-box-" or "nullius-"
  local recipe = table.deepcopy(data.raw.recipe[prefix.."bauxite-disposal"])
  recipe.name = prefix.."sand-crushing"
  recipe.subgroup = boxed and "boxed-silicon" or "masonry-material"
  recipe.order = "nullius-nd"
  recipe.localised_name = boxed and
    {"recipe-name.nullius-boxed", {"recipe-name.nullius-sand-crushing"}} or
    {"recipe-name.nullius-sand-crushing"}
  recipe.icons[#recipe.icons].icon = ICONPATH.."sand.png"
  recipe.icons[#recipe.icons].tint = nil
  recipe.ingredients = {{type="item",name=item.."sand",amount=4}}
  recipe.results = {{type="item",name=item.."mineral-dust",amount=3}}
  recipe.allow_productivity = false
  recipe.no_productivity = true
  data:extend({recipe})
end

-- Cold data-stage path: gypsum disposal with matching bulk processing.
for _,boxed in ipairs({false,true}) do
  local prefix = boxed and "nullius-boxed-" or "nullius-"
  local item = boxed and "nullius-box-" or "nullius-"
  local recipe = table.deepcopy(data.raw.recipe[prefix.."limestone-disposal"])
  recipe.name = prefix.."gypsum-disposal"
  recipe.order = "nullius-ma"
  recipe.localised_name = boxed and
    {"recipe-name.nullius-boxed", {"recipe-name.nullius-gypsum-disposal"}} or
    {"recipe-name.nullius-gypsum-disposal"}
  local overlay = table.deepcopy(data.raw.item["nullius-gypsum"].icons[1])
  overlay.scale = boxed and 0.225 or 0.25
  overlay.shift = boxed and {9, -8} or {10, -9}
  recipe.icons[#recipe.icons] = overlay
  recipe.energy_required = boxed and 5 or 1
  recipe.ingredients = {{type="item",name=item.."gypsum",amount=1}}
  recipe.results = {{type="item",name=item.."mineral-dust",amount=1}}
  recipe.allow_productivity = false
  recipe.no_productivity = true
  data:extend({recipe})
end

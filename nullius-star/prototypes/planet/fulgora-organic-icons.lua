local plastic = data.raw.item["nullius-plastic"]

for _, spec in ipairs(require("shared.fulgora-organics")) do
  if spec.results[1].name ~= "nullius-iron-chloride" then
    for _, boxed in ipairs({false, true}) do
      local name = boxed and spec.name:gsub("^nullius%-", "nullius-boxed-") or spec.name
      local recipe = data.raw.recipe[name]
      local product = data.raw.item[recipe.main_product]
      recipe.icons = product.icons and table.deepcopy(product.icons) or {{
        icon=product.icon, icon_size=product.icon_size,
      }}
      table.insert(recipe.icons, {
        icon=plastic.icon, icon_size=plastic.icon_size,
        scale=boxed and 0.22 or 0.25,
        shift=boxed and {11, -9} or {12, -10},
      })
    end
  end
end

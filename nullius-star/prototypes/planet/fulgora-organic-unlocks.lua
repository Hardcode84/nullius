local specs = require("shared.fulgora-organics")

return function(technology)
  local effects = {}
  for _, spec in ipairs(specs) do
    for _, boxed in ipairs({false, true}) do
      local owner = boxed and (spec.boxed_technology or "nullius-bulk-polymer-processing") or spec.technology
      if owner == technology then
        effects[#effects+1] = {type="unlock-recipe",
          recipe=boxed and spec.name:gsub("^nullius%-", "nullius-boxed-") or spec.name}
      end
    end
  end
  return effects
end

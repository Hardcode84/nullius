-- Resolve upgrade build items once during data updates, across all item types.
return function()
  local items, visible = {}, {}
  for item_type in pairs(defines.prototypes.item) do
    for name, item in pairs(data.raw[item_type] or {}) do
      items[name] = item
      if item.place_result then
        visible[item.place_result] = visible[item.place_result] or not item.hidden
      end
    end
  end
  for entity_type in pairs(defines.prototypes.entity) do
    for name, entity in pairs(data.raw[entity_type] or {}) do
      if entity.placeable_by then
        -- Native upgrade validation uses the first explicit build item.
        local placement = entity.placeable_by.item and entity.placeable_by or entity.placeable_by[1]
        local item = assert(items[placement.item],
          "Missing build item " .. placement.item .. " for " .. name)
        visible[name] = not item.hidden
      end
    end
  end
  return visible
end

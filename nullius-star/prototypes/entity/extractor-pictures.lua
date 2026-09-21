-- Cold path: move the extractor foundation into the 2.1 graphics set.
return function(extractor)
  if not require("factorio-version").is_2_1 then return end
  local foundation = {always_draw=true, render_layer=extractor.base_render_layer,
    secondary_draw_order=-1}
  for i, direction in ipairs({"north_animation", "east_animation", "south_animation", "west_animation"}) do
    local layers = table.deepcopy(extractor.base_picture.sheets)
    local shadow = layers[2]
    -- The 2.1 sheet has larger frames and a different origin. Apply the native
    -- origin change at the extractor scale; retain its custom placement.
    shadow.width = 261
    shadow.height = 273
    local ratio = shadow.scale / 0.5
    shadow.shift = {shadow.shift[1] - 8 * ratio / 32,
      shadow.shift[2] - 5.5 * ratio / 32}
    for _, layer in ipairs(layers) do layer.x = (i-1) * layer.width end
    foundation[direction] = {layers=layers}
  end
  extractor.graphics_set.working_visualisations = {foundation}
  extractor.base_picture = nil
  extractor.base_render_layer = nil
end

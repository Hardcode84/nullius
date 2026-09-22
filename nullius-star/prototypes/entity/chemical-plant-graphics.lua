-- Cold path: use native split body layers and retain the Nullius recipe effects.
return function(entity)
  if not require("factorio-version").is_2_1 then return end
  local previous = entity.graphics_set
  local graphics = table.deepcopy(data.raw["assembling-machine"]["chemical-plant"].graphics_set)
  for _, direction in ipairs({"north", "east", "south", "west"}) do
    local old = previous.animation[direction].layers
    local function place(sprite)
      local legacy = sprite.draw_as_shadow and old[2] or old[1]
      local origin = sprite.draw_as_shadow and {27, 6} or {0.5, -9}
      local ratio = legacy.scale / 0.5
      sprite.scale = (sprite.scale or 1) * ratio
      sprite.shift = {
        sprite.shift[1] * ratio + legacy.shift[1] - origin[1] * ratio / 32,
        sprite.shift[2] * ratio + legacy.shift[2] - origin[2] * ratio / 32,
      }
    end
    for _, layer in ipairs(graphics.animation[direction].layers) do
      place(layer)
      if not layer.draw_as_shadow then layer.tint = old[1].tint end
    end
    if graphics.frozen_patch then place(graphics.frozen_patch[direction]) end
  end
  graphics.working_visualisations = previous.working_visualisations
  entity.graphics_set = graphics
end

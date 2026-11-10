-- Cold path: pair each engine's sprite layout with the Nullius size and timing.
-- Each machine draws a base-game assembler scaled about its centre, so every
-- native offset scales with the sprite.
return function(entity, tier)
  if not require("factorio-version").is_2_1 then return end
  local old = entity.graphics_set.animation.layers
  local graphics = table.deepcopy(data.raw["assembling-machine"]["assembling-machine-" .. tier].graphics_set)
  local ratio = old[1].scale / 0.5
  local speed = (old[1].animation_speed or 1) * 64 / old[1].frame_count

  local function adjust(sprite, animated)
    local shift = sprite.shift or {0, 0}
    sprite.scale = (sprite.scale or 1) * ratio
    sprite.shift = {shift[1] * ratio, shift[2] * ratio}
    if animated then sprite.animation_speed = speed end
  end
  for _, sprite in ipairs(graphics.animation.layers) do adjust(sprite, true) end
  for _, visualisation in ipairs(graphics.working_visualisations) do
    adjust(visualisation.animation, true)
  end
  if graphics.frozen_patch then adjust(graphics.frozen_patch, false) end
  graphics.animation_progress = entity.graphics_set.animation_progress
  entity.graphics_set = graphics
end

-- Cold path: pair each engine's sprite layout with the Nullius size and timing.
return function(entity, tier)
  if not require("factorio-version").is_2_1 then return end
  local old = entity.graphics_set.animation.layers
  local graphics = table.deepcopy(data.raw["assembling-machine"]["assembling-machine-" .. tier].graphics_set)
  local body_origins = {{0, 2}, {0, 4}, {0, -0.75}}
  local shadow_origins = {{8.5, 5}, {12, 4.75}, {28, 4}}
  local ratio = old[1].scale / 0.5
  local speed = (old[1].animation_speed or 1) * 64 / old[1].frame_count

  local function adjust(sprite, animated)
    local legacy = sprite.draw_as_shadow and old[2] or old[1]
    local legacy_tier = tonumber(legacy.filename:match("assembling%-machine%-(%d)/"))
    local origin = sprite.draw_as_shadow and shadow_origins[legacy_tier] or body_origins[legacy_tier]
    local shift = sprite.shift or {0, 0}
    local previous = legacy.shift or {0, 0}
    sprite.scale = (sprite.scale or 1) * ratio
    sprite.shift = {
      shift[1] * ratio + previous[1] - origin[1] / 32 * ratio,
      shift[2] * ratio + previous[2] - origin[2] / 32 * ratio,
    }
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

-- Cold path: keep the custom coloured arm and match its native shadow to it.
return function(body, shadow)
  if not require("factorio-version").is_2_1 then return shadow end
  local native = table.deepcopy(data.raw["mining-drill"]["pumpjack"].graphics_set.animation.north.layers[2])
  native.scale = body.scale
  native.animation_speed = body.animation_speed
  native.shift = table.deepcopy(shadow.shift)
  return native
end

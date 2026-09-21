-- Supply only the dependencies of the actual turbine prototype module.
data:extend({{type="fluid", name="nullius-energy", default_temperature=100,
  max_temperature=200, heat_capacity="0.1kJ", fuel_value="10kJ",
  icon="__base__/graphics/icons/fluid/steam.png", auto_barrel=false,
  base_color={1,1,1}, flow_color={1,1,1}}})
for _, name in ipairs({"turbine-open", "turbine-closed", "nullius-power-sink"}) do
  data:extend({{type="recipe-category",name=name}})
end
for _, priority in ipairs({"backup","standard","exhaust"}) do
  data:extend({{type="item-subgroup",name="energy-backup-mode-" .. priority,group="production",order=priority}})
end
for tier=1,3 do
  for _, openness in ipairs({"open","closed"}) do
    data:extend({{type="item",name="nullius-turbine-" .. openness .. "-" .. tier,
      icon="__base__/graphics/icons/steam-turbine.png",stack_size=50,order=tostring(tier)}})
  end
end
require("__nullius-star__/prototypes/entity/turbine")
local modern = string.match(mods.base, "^2%.1%.") ~= nil
local tints = {{0.25,0.4,0.6},{0.45,0.6,0.8},{0.6,0.8,1}}
for tier=1,3 do
  local lowblue, low, high = table.unpack(tints[tier])
  for _, openness in ipairs({"open","closed"}) do
    for priority, overlay in pairs({backup="green",standard="yellow",exhaust="red"}) do
      local name = "nullius-turbine-generator-" .. openness .. "-" .. priority .. "-" .. tier
      local generator = data.raw.generator[name]
      assert(generator, name)
      local tint = {priority == "backup" and low or high,
        priority == "exhaust" and low or high, openness == "open" and lowblue or high, 1}
      assert((generator.pictures ~= nil) == modern, name .. " picture schema")
      assert((generator.horizontal_animation == nil) == modern, name .. " horizontal schema")
      assert((generator.vertical_animation == nil) == modern, name .. " vertical schema")
      if modern then assert(generator.two_direction_only, name .. " two directions") end
      for _, direction in ipairs({"north","east","south","west"}) do
        local vertical = direction == "north" or direction == "south"
        local animation = modern and generator.pictures[direction].animation or
          (vertical and generator.vertical_animation or generator.horizontal_animation)
        assert(#animation.layers == 2, name .. " animated layers")
        local base, color = animation.layers[1], animation.layers[2]
        assert(base.filename == "__base__/graphics/entity/steam-turbine/steam-turbine-" .. (vertical and "V" or "H") .. ".png")
        assert(color.filename == "__nullius-star__/graphics/entity/turbine/" .. overlay .. "-turbine-" .. (vertical and "v" or "h") .. ".png")
        assert(base.width == (vertical and 217 or 320) and base.height == (vertical and 374 or 245))
        assert(color.width == (vertical and 217 or 320) and color.height == (vertical and 347 or 245))
        assert(base.frame_count == 8 and base.line_length == 4 and base.scale == 0.5)
        assert(color.frame_count == 1 and color.line_length == 1 and color.repeat_count == 8 and color.scale == 0.5)
        local shifts = vertical and {{4.75/32,0},{4.75/32,6.75/32}} or {{0,-2.75/32},{0,-2.75/32}}
        for i, layer in ipairs(animation.layers) do
          assert(layer.shift[1] == shifts[i][1] and layer.shift[2] == shifts[i][2], name .. " sprite shift")
          for j=1,4 do assert(layer.tint[j] == tint[j], name .. " tint") end
        end
      end
    end
  end
end

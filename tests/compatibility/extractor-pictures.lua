for tier=1,2 do
  local name = "nullius-extractor-" .. tier
  data:extend({{type="item", name=name, stack_size=50, place_result=name,
    icons={{icon="__base__/graphics/icons/pumpjack.png",icon_size=64}}}})
end
require("extractor-prototypes")
local modern = require("factorio-version").is_2_1
local function near(a,b) assert(math.abs(a-b)<0.0000001,"sprite position") end
for tier=1,2 do
  local extractor = data.raw["mining-drill"]["nullius-extractor-" .. tier]
  assert(extractor.mining_speed == tier, "mining speed")
  assert(extractor.energy_usage == (tier==1 and "390kW" or "775kW"), "power")
  for i,direction in ipairs({"north_animation","east_animation","south_animation","west_animation"}) do
    local layers
    if modern then
      assert(extractor.base_picture == nil and extractor.base_render_layer == nil, "old fields")
      assert(#extractor.graphics_set.working_visualisations == 1, "one foundation")
      local visual = extractor.graphics_set.working_visualisations[1]
      assert(visual.always_draw, "idle foundation")
      assert(visual.render_layer == "lower-object-above-shadow" and visual.secondary_draw_order == -1, "layer")
      layers = visual[direction].layers
    else
      assert(extractor.base_render_layer == "lower-object-above-shadow", "layer")
      layers = extractor.base_picture.sheets
    end
    assert(#layers == 2, "foundation and shadow")
    for j,layer in ipairs(layers) do
      assert(layer.filename == "__base__/graphics/entity/pumpjack/pumpjack-base" .. (j==2 and "-shadow" or "") .. ".png", "image")
      assert(layer.scale == 0.66667, "scale")
      local width = (modern or j==1) and 261 or 220
      local height = (modern or j==1) and 273 or 220
      assert(layer.width == width and layer.height == height, "frame bounds")
      if modern then assert(layer.x == (i-1)*width and layer.x+width <= 4*width, "directional frame") end
    end
    assert(layers[2].draw_as_shadow, "shadow layer")
    near(layers[1].shift[1], -3.75/32)
    near(layers[1].shift[2], -7.91666/32)
    near(layers[2].shift[1], (modern and -0.66672 or 10)/32)
    near(layers[2].shift[2], (modern and -6.500037 or 0.833333)/32)
  end
end
require("gas-vent-prototype")
local drill = data.raw["mining-drill"]["nullius-gas-vent-drill"]
assert(drill.base_picture == nil and next(drill.graphics_set) == nil, "gas vent stays invisible")

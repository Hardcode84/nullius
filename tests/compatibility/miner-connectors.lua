require("miner-connector-scaling")
local names = {"nullius-small-miner-1", "nullius-small-miner-2", "nullius-small-miner-3",
  "nullius-medium-miner-1", "nullius-medium-miner-2", "nullius-medium-miner-3",
  "nullius-large-miner-1", "nullius-large-miner-2"}
for _, name in ipairs(names) do
  data:extend({{type="item", name=name, stack_size=50, place_result=name,
    icons={{icon="__base__/graphics/icons/electric-mining-drill.png", icon_size=64}}}})
end
local modern = require("factorio-version").is_2_1
local reference = table.deepcopy(circuit_connector_definitions["electric-mining-drill"])
local function equal(a, b)
  if type(a) ~= "table" then return a == b end
  if type(b) ~= "table" then return false end
  for k,v in pairs(a) do if not equal(v,b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end
local normal = {}
local function check(reskin)
  for _, name in ipairs(names) do
    local miner = data.raw["mining-drill"][name]
    local burner = name == "nullius-small-miner-1" or name == "nullius-medium-miner-1"
    local scale = name:find("small") and 0.6666 or (name:find("large") and 1.2 or 1)
    if not burner then
      local expected = scale_connector_points(reference, scale)
      assert(#miner.circuit_connector == 4, name .. " directions")
      for i,direction in ipairs({"north","east","south","west"}) do
        local connector = miner.circuit_connector[i]
        local sprites = connector.sprites
        assert(equal(connector.points, expected[i].points), name .. " wire geometry")
        if modern then
          assert(sprites.render_layer == "object", name .. " layer")
          assert(sprites.secondary_draw_order == (i == 1 and 14 or 30), name .. " order")
          assert(miner.graphics_set.circuit_connector_layer == nil, name .. " old layer")
          assert(miner.graphics_set.circuit_connector_secondary_draw_order == nil, name .. " old order")
          expected[i].sprites.render_layer = "object"
          expected[i].sprites.secondary_draw_order = i == 1 and 14 or 30
        else
          assert(miner.graphics_set.circuit_connector_layer == "object", name .. " layer")
          assert(miner.graphics_set.circuit_connector_secondary_draw_order[direction] ==
            (i == 1 and 14 or 30), name .. " order")
        end
        assert(equal(sprites, expected[i].sprites), name .. " sprite geometry")
      end
      if reskin then
        assert(equal(miner.circuit_connector, normal[name].circuit_connector), name .. " reskin connectors")
        assert(miner.graphics_set.working_visualisations[3].north_animation.layers[2].filename:find("__reskins%-bobs__"), name .. " reskin applied")
      end
    end
  end
  assert(equal(reference, circuit_connector_definitions["electric-mining-drill"]), "base connector mutation")
end
require("miner-prototypes")
check(false)
for _, name in ipairs(names) do normal[name] = data.raw["mining-drill"][name] end
require("miner-reskin-prototypes")
check(true)
for _, name in ipairs(names) do data.raw["mining-drill"][name] = normal[name] end

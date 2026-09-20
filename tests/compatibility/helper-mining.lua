-- Isolated entity fixtures for the four production helper creation paths.
local function clone(kind, source, name)
  local prototype = table.deepcopy(data.raw[kind][source])
  prototype.name = name
  prototype.next_upgrade = nil
  prototype.fast_replaceable_group = nil
  prototype.minable = {mining_time=0.1, result="iron-plate"}
  prototype.collision_mask = {layers={}}
  data:extend({prototype})
  return prototype
end
local planet = table.deepcopy(data.raw.planet.nauvis)
planet.name = "nullius-vulcanus"
data:extend({planet})
clone("beacon", "beacon", "nullius-large-beacon-1")
for _, direction in ipairs({"horizontal", "vertical"}) do
  data:extend({{
    type="simple-entity-with-force", name="nullius-beacon-interference-" .. direction,
    picture=util.empty_sprite(), collision_mask={layers={}},
    minable={mining_time=0.1, result="iron-plate"},
  }})
end
clone("electric-energy-interface", "electric-energy-interface", "compat-stirling")
clone("heat-interface", "heat-interface", "nullius-stirling-vertical-heat-1")
data:extend({{
  type="animation", name="nullius-stirling-vertical-turbine-1",
  filename="__core__/graphics/empty.png", width=1, height=1,
}})
local machine = clone("assembling-machine", "assembling-machine-1", "compat-machine-pneumatic")
machine.collision_box = {{-0.7,-0.7},{0.7,0.7}}
for _, size in ipairs({"small", "medium", "medium2", "large"}) do
  clone("heat-interface", "heat-interface", "nullius-pneumatic-heat-" .. size)
end
clone("assembling-machine", "assembling-machine-1", "compat-vent")
clone("mining-drill", "electric-mining-drill", "nullius-gas-vent-drill")
local resource = clone("resource", "iron-ore", "nullius-gas-vent-seam")
resource.infinite = true
resource.minimum = 1
resource.normal = 1000000
resource.infinite_depletion_amount = 0

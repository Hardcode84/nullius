for _, name in ipairs({"vehicle","nullius-nuclear"}) do data:extend({{type="fuel-category",name=name}}) end
for _, case in ipairs(require("__nullius-star__/scenarios/vehicle-forces/fixture")) do
  data:extend({{type="item-with-entity-data",name=case.name,stack_size=1,
    icons={{icon="__base__/graphics/icons/car.png",icon_size=64}}}})
end
for _, name in ipairs({"nullius-car-gun","nullius-car-gun-2","nullius-car-launcher",
    "nullius-truck-gun","nullius-truck-gun-2","nullius-truck-launcher"}) do
  local gun = table.deepcopy(data.raw.gun["submachine-gun"])
  gun.name = name
  data:extend({gun})
end

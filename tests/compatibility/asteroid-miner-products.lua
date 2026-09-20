local products = require("__nullius-star__/prototypes/item/asteroid-miner-products")
for _, mineral in ipairs({"iron", "sandstone", "bauxite", "limestone", "copper", "uranium"}) do
  data:extend({{
    type="item", name="nullius-guide-drone-" .. mineral .. "-1", stack_size=1,
    icon="__base__/graphics/icons/iron-plate.png",
  }})
end
for tier=1,2 do
  data:extend({{
    type="item", name="nullius-asteroid-miner-" .. tier, stack_size=1,
    icon="__base__/graphics/icons/iron-plate.png",
    rocket_launch_products=products[tier],
  }})
end

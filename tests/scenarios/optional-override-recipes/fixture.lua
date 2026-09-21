-- Frozen recipe contracts; inherited external recipes take seven seconds and yield one item.
return {
  {name="road",mod="Transport_Drones",category="hand-casting",seconds=3,ingredients={
  {type = "item", name = "nullius-rubber", amount = 1},
  {type = "item", name = "nullius-land-fill-sand", amount = 1},
  {type = "item", name = "nullius-gravel", amount = 3}
},products={{type="item",name="road",amount=4}}},
  {name="transport-drone",mod="Transport_Drones",category="medium-crafting",seconds=10,ingredients={
  {type = "item", name = "nullius-car-1", amount = 1},
  {type = "item", name = "arithmetic-combinator", amount = 5},
  {type = "item", name = "programmable-speaker", amount = 2},
  {type = "item", name = "turbo-filter-inserter", amount = 3}
},products={{type="item",name="transport-drone",amount=3}}},
  {name="supply-depot",mod="Transport_Drones",category="large-crafting",seconds=12,ingredients={
  {type = "item", name = "nullius-large-chest-1", amount = 1},
  {type = "item", name = "nullius-steel-beam", amount = 4},
  {type = "item", name = "nullius-glass", amount = 2},
  {type = "item", name = "train-stop", amount = 1}
},products={{type="item",name="supply-depot",amount=1}}},
  {name="request-depot",mod="Transport_Drones",category="large-crafting",seconds=6,ingredients={
  {type = "item", name = "fluid-depot", amount = 1},
  {type = "item", name = "nullius-hangar-1", amount = 1}
},products={{type="item",name="request-depot",amount=1}}},
  {name="buffer-depot",mod="Transport_Drones",category="large-crafting",seconds=4,ingredients={
  {type = "item", name = "request-depot", amount = 1},
  {type = "item", name = "train-stop", amount = 1}
},products={{type="item",name="buffer-depot",amount=1}}},
  {name="fluid-depot",mod="Transport_Drones",category="large-crafting",seconds=4,ingredients={
  {type = "item", name = "supply-depot", amount = 1},
  {type = "item", name = "nullius-medium-tank-2", amount = 1},
  {type = "item", name = "nullius-barrel-pump-1", amount = 1}
},products={{type="item",name="fluid-depot",amount=1}}},
  {name="fuel-depot",mod="Transport_Drones",category="large-crafting",seconds=4,ingredients={
  {type = "item", name = "buffer-depot", amount = 1},
  {type = "item", name = "nullius-pump-2", amount = 2}
},products={{type="item",name="fuel-depot",amount=1}}},
  {name="road-network-reader",mod="Transport_Drones",category="small-crafting",seconds=5,ingredients={
  {type = "item", name = "rail-chain-signal", amount = 1},
  {type = "item", name = "nullius-sensor-1", amount = 1},
  {type = "item", name = "programmable-speaker", amount = 1}
},products={{type="item",name="road-network-reader",amount=1}}},
  {name="transport-depot-reader",mod="Transport_Drones",category="small-crafting",seconds=2,ingredients={
  {type = "item", name = "road-network-reader", amount = 1},
  {type = "item", name = "nullius-red-wire", amount = 2}
},products={{type="item",name="transport-depot-reader",amount=1}}},
  {name="transport-depot-writer",mod="Transport_Drones",category="small-crafting",seconds=3,ingredients={
  {type = "item", name = "road-network-reader", amount = 1},
  {type = "item", name = "nullius-green-wire", amount = 3}
},products={{type="item",name="transport-depot-writer",amount=1}}},
  {name="fast-road",mod="Transport_Drones",category="large-crafting",seconds=30,ingredients={
  {type = "item", name = "road", amount = 50},
  {type = "item", name = "nullius-box-black-concrete", amount = 6},
  {type = "item", name = "road-network-reader", amount = 1}
},products={{type="item",name="fast-road",amount=8}}},
  {name="boat",mod="cargo-ships",category="large-crafting",seconds=10,ingredients={
    {type="item", name="nullius-seawater-intake-1", amount=3},
    {type="item", name="nullius-portable-generator-1", amount=1},
    {type="item", name="nullius-medium-tank-2", amount=2},
	{type="item", name="nullius-rubber", amount=4},
	{type="item", name="nullius-glass", amount=1}
  },products={{type="item",name="boat",amount=1}}},
  {name="cargo_ship",mod="cargo-ships",category="huge-crafting",seconds=30,ingredients={
    {type="item", name="boat", amount=4},
    {type="item", name="nullius-steel-sheet", amount=30},
	{type="item", name="nullius-steel-beam", amount=15},
    {type="item", name="nullius-pump-2", amount=6}
  },products={{type="item",name="cargo_ship",amount=1}}},
  {name="oil_tanker",mod="cargo-ships",category="huge-crafting",seconds=20,ingredients={
    {type="item", name="cargo_ship", amount=1},
    {type="item", name="nullius-seawater-intake-2", amount=3},
    {type="item", name="nullius-medium-tank-2", amount=8}
  },products={{type="item",name="oil_tanker",amount=1}}},
  {name="port",mod="cargo-ships",category="large-fluid-assembly",seconds=15,ingredients={
    {type="item", name="train-stop", amount=2},
    {type="item", name="nullius-small-tank-1", amount=1},
    {type="item", name="nullius-steel-cable", amount=10},
    {type="item", name="concrete", amount=8},
	{type="fluid", name="nullius-nitrogen", amount=1000, fluidbox_index=1}
  },products={{type="item",name="port",amount=1}}},
  {name="buoy",mod="cargo-ships",category="small-fluid-assembly",seconds=5,ingredients={
    {type="item", name="rail-signal", amount=1},
    {type="item", name="barrel", amount=1},
    {type="item", name="nullius-steel-cable", amount=5},
    {type="item", name="concrete", amount=5},
	{type="fluid", name="nullius-nitrogen", amount=250, fluidbox_index=1}
  },products={{type="item",name="buoy",amount=1}}},
  {name="chain_buoy",mod="cargo-ships",category="small-crafting",seconds=3,ingredients={
    {type="item", name="buoy", amount=1},
    {type="item", name="programmable-speaker", amount=1}
  },products={{type="item",name="chain_buoy",amount=1}}},
  {name="floating-electric-pole",mod="cargo-ships",category="large-crafting",seconds=8,ingredients={
    {type="item", name="buoy", amount=3},
    {type="item", name="big-electric-pole", amount=2}
  },products={{type="item",name="floating-electric-pole",amount=1}}},
  {name="bridge_base",mod="cargo-ships",category="small-crafting",seconds=50,ingredients={
    {type="item", name="rail", amount=12},
    {type="item", name="nullius-steel-beam", amount=30},
	{type="item", name="concrete", amount=40},
    {type="item", name="nullius-steel-cable", amount=10},
	{type="item", name="nullius-motor-2", amount=4},
	{type="item", name="chain_buoy", amount=2}
  },products={{type="item",name="bridge_base",amount=1}}},
  {name="oil_rig",mod="cargo-ships",category="huge-crafting",seconds=60,ingredients={
      {type="item", name="nullius-large-tank-1", amount=4},
      {type="item", name="nullius-geothermal-plant-1", amount=1},
      {type="item", name="nullius-stirling-engine-1", amount=2},
	  {type="item", name="nullius-extractor-1", amount=2},
	  {type="item", name="floating-electric-pole", amount=2},
	  {type="item", name="port", amount=1}
    },products={{type="item",name="oil_rig",amount=1}}},
  {name="cargo-drone",mod="cargo-drone",category="huge-crafting",seconds=30,ingredients={
  {type="item", name="nullius-logistic-bot-2", amount=5},
  {type="item", name="nullius-portable-generator-2", amount=1},
  {type="item", name="nullius-plastic", amount=15},
  {type="item", name="nullius-textile", amount=15},
  {type="item", name="nullius-steel-cable", amount=5},
  {type="item", name="nullius-large-chest-2", amount=2},
  {type="item", name="nullius-sensor-node-2", amount=1},
  {type="fluid", name="nullius-hydrogen", amount=20000}
},products={{type="item",name="cargo-drone",amount=1}}},
  {name="cargo-drone-mooring-constant-combinator-refueler",mod="cargo-drone",category="large-crafting",seconds=10,ingredients={
  {type="item", name="nullius-pylon-2", amount=2},
  {type="item", name="nullius-relay-2", amount=1},
  {type="item", name="train-stop", amount=1},
  {type="item", name="express-underground-belt", amount=1}
},products={{type="item",name="cargo-drone-mooring-constant-combinator-refueler",amount=1}}},
  {name="cargo-drone-mooring-constant-combinator-provider",mod="cargo-drone",category="large-crafting",seconds=7,ingredients={
  {type="item", name="cargo-drone-mooring-constant-combinator-refueler", amount=1},
  {type="item", name="nullius-small-supply-chest-1", amount=1}
},products={{type="item",name="cargo-drone-mooring-constant-combinator-provider",amount=1}}},
  {name="cargo-drone-mooring-constant-combinator-requester",mod="cargo-drone",category="large-crafting",seconds=7,ingredients={
  {type="item", name="cargo-drone-mooring-constant-combinator-refueler", amount=1},
  {type="item", name="nullius-small-demand-chest-1", amount=1}
},products={{type="item",name="cargo-drone-mooring-constant-combinator-requester",amount=1}}},
  {name="cargo-drone-depot-constant-combinator",mod="cargo-drone",category="large-crafting",seconds=5,ingredients={
  {type="item", name="nullius-iron-plate", amount=2},
  {type="item", name="train-stop", amount=1},
  {type="item", name="nullius-relay-2", amount=1}
},products={{type="item",name="cargo-drone-depot-constant-combinator",amount=1}}}
}

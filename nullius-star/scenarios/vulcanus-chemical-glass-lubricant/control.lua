require("__nullius-star__/scenarios/vulcanus-manifest-runner"){
  case = "vulcanus-chemical-glass-lubricant",
  contract = require("manifest"),
  initial_technology = "nullius-pneumatic-technology",
  deadline = 10000,
  parallelism = 10,
  parallel_fixture = {
    ["nullius-foundry-1"] = 9,
    ["nullius-medium-furnace-1"] = 1,
    ["nullius-chemical-plant-1"] = 4,
  },
  fixture = {
    ["nullius-hydro-plant-1"] = 4,
    ["nullius-small-furnace-1"] = 1,
    ["nullius-medium-furnace-1"] = 1,
    ["nullius-foundry-1"] = 1,
    ["nullius-chemical-plant-1"] = 1,
    ["nullius-heat-pipe-1"] = 30,
  },
}

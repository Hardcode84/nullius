require("__nullius-star__/scenarios/vulcanus-manifest-runner"){
  case = "vulcanus-chemical-pack-10",
  contract = require("manifest"),
  initial_technologies = {
    "nullius-experimental-chemistry",
    "nullius-pneumatic-technology",
  },
  deadline = 1500,
  parallelism = 10,
  heat_fixture = false,
  parallel_fixture = {
    ["nullius-chemical-plant-1"] = 9,
  },
  fixture = {
    ["nullius-chemical-plant-1"] = 1,
  },
}

require("__nullius-star__/scenarios/vulcanus-manifest-runner"){
  case = "vulcanus-chemical-concrete-barrels",
  contract = require("manifest"),
  initial_technologies = {
    "nullius-experimental-chemistry",
    "nullius-pneumatic-technology",
  },
  deadline = 1500,
  parallelism = 10,
  heat_fixture = false,
  transition_builds = {
    ["nullius-flotation-cell-1-pneumatic"] = "nullius-flotation-cell-1",
  },
  parallel_fixture = {
    ["nullius-flotation-cell-1"] = 9,
    ["nullius-barrel-pump-1"] = 9,
  },
  fixture = {
    ["nullius-flotation-cell-1"] = 1,
    ["nullius-barrel-pump-1"] = 1,
  },
}

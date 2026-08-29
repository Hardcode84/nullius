require("__nullius-star__/scenarios/vulcanus-manifest-runner"){
  case = "vulcanus-chemical-acid-200",
  contract = require("manifest"),
  initial_technologies = {
    "nullius-sulfur-processing-1",
    "nullius-pneumatic-technology",
  },
  deadline = 10000,
  parallelism = 8,
  parallel_fixture = {
    ["nullius-seawater-intake-1"] = 7,
    ["nullius-hydro-plant-1"] = 4,
    ["nullius-chemical-plant-1"] = 7,
    ["nullius-vulcanus-radiator-1"] = 7,
  },
  fixture = {
    ["nullius-seawater-intake-1"] = 1,
    ["nullius-hydro-plant-1"] = 4,
    ["nullius-chemical-plant-1"] = 1,
    ["nullius-small-furnace-1"] = 1,
    ["nullius-vulcanus-radiator-1"] = 1,
    ["nullius-heat-pipe-1"] = 30,
  },
}

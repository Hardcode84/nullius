require("__nullius-star__/scenarios/vulcanus-manifest-runner"){
  case = "vulcanus-chemical-alkali-20",
  contract = require("manifest"),
  initial_technologies = {
    "nullius-volcanic-alkali-processing",
    "nullius-pneumatic-technology",
  },
  deadline = 13000,
  parallelism = 10,
  heat_fixture = false,
  parallel_fixture = {
    ["nullius-hydro-plant-1"] = 9,
    ["nullius-distillery-1"] = 9,
    ["nullius-chemical-plant-1"] = 9,
  },
  fixture = {
    ["nullius-hydro-plant-1"] = 1,
    ["nullius-distillery-1"] = 1,
    ["nullius-chemical-plant-1"] = 1,
  },
}

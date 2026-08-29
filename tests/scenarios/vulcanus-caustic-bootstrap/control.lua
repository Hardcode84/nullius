require("__nullius-star__/scenarios/vulcanus-manifest-runner"){
  case = "vulcanus-caustic-bootstrap",
  contract = require("manifest"),
  initial_technology = "nullius-volcanic-alkali-processing",
  deadline = 5000,
  parallelism = 2,
  heat_fixture = false,
  parallel_fixture = {
    ["nullius-chemical-plant-1"] = 1,
  },
  fixture = {
    ["nullius-chemical-plant-1"] = 1,
    ["nullius-distillery-1"] = 1,
    ["nullius-hydro-plant-1"] = 1,
  },
}

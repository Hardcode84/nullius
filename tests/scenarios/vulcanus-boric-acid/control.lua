require("__nullius-star__/scenarios/vulcanus-manifest-runner"){
  case = "vulcanus-boric-acid",
  contract = require("manifest"),
  initial_technologies = {
    "nullius-sulfur-processing-2",
    "nullius-pneumatic-technology",
  },
  deadline = 600,
  parallelism = 1,
  heat_fixture = false,
  fixture = {
    ["nullius-barrel-pump-1"] = 1,
    ["nullius-distillery-1"] = 1,
  },
}

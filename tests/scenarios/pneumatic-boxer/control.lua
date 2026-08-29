require("__nullius-star__/scenarios/vulcanus-manifest-runner"){
  case = "pneumatic-boxer",
  contract = require("manifest"),
  initial_technologies = {
    "nullius-packaging-6",
    "nullius-pneumatic-technology",
  },
  deadline = 200,
  parallelism = 1,
  heat_fixture = false,
  transition_builds = {
    ["nullius-boxer-pneumatic"] = "nullius-boxer",
  },
  fixture = {
    ["nullius-boxer"] = 1,
  },
}

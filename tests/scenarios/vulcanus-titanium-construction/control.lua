require("__nullius-star__/scenarios/vulcanus-manifest-runner"){
  case = "vulcanus-titanium-construction",
  contract = require("manifest"),
  initial_technologies = {"nullius-volcanic-titanium-metallurgy"},
  deadline = 2000,
  parallelism = 2,
  heat_fixture = false,
  parallel_fixture = {
    ["nullius-medium-assembler-1"] = 1,
  },
  fixture = {
    ["nullius-medium-assembler-1"] = 1,
  },
}

require("__nullius-star__/scenarios/vulcanus-manifest-runner"){
  case = "vulcanus-titanium-pilot",
  contract = require("manifest"),
  initial_technologies = {"nullius-volcanic-titanium-metallurgy"},
  deadline = 4500,
  parallelism = 8,
  scripted_heat = true,
  parallel_fixture = {
    ["nullius-flotation-cell-1"] = 7,
    ["nullius-medium-furnace-2"] = 1,
    ["nullius-vulcanus-radiator-2"] = 1,
  },
  fixture = {
    ["nullius-flotation-cell-1"] = 1,
    ["nullius-medium-furnace-2"] = 1,
    ["nullius-vulcanus-radiator-2"] = 1,
    ["nullius-foundry-1"] = 1,
  },
}

require("__nullius-star__/scenarios/vulcanus-manifest-runner"){
  case = "carbothermic-sodium",
  contract = require("manifest"),
  initial_technology = "nullius-sodium-processing",
  deadline = 1300,
  parallelism = 1,
  scripted_heat = true,
  fixture = {
    ["nullius-vulcanus-radiator-2"] = 1,
  },
}

local config = {
  case = "vulcanus-basic-science-10-motor-1-vulcanus",
  contract = nil,
  deadline = 17040,
  fixture = {
    ["nullius-air-filter-1"] = 8,
    ["nullius-chemical-plant-1"] = 8,
    ["nullius-distillery-1"] = 8,
    ["nullius-foundry-1"] = 8,
    ["nullius-heat-pipe-1"] = 30,
    ["nullius-hydro-plant-1"] = 8,
    ["nullius-medium-assembler-1"] = 8,
    ["nullius-seawater-intake-1"] = 8,
    ["nullius-small-assembler-1"] = 8,
    ["nullius-small-furnace-1"] = 8,
    ["nullius-vulcanus-radiator-1"] = 1,
    ["nullius-vulcanus-radiator-2"] = 1,
  },
  ordered_steps = true,
  parallelism = 8,
  scripted_heat = true,
}
config.contract = require("manifest")
require("__nullius-star__/scenarios/vulcanus-manifest-runner")(config)

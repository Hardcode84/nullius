local config = {
  case = "vulcanus-metallurgic-pack-10-so2-catalytic-decomposition",
  contract = nil,
  deadline = 14460,
  fixture = {
    ["nullius-heat-pipe-1"] = 30,
    ["nullius-hydro-plant-1"] = 16,
    ["nullius-seawater-intake-1"] = 8,
    ["nullius-small-assembler-1"] = 16,
    ["nullius-small-furnace-1"] = 16,
    ["nullius-vulcanus-radiator-1"] = 16,
  },
  ordered_steps = true,
  parallelism = 16,
  scripted_heat = true,
}
config.contract = require("manifest")
require("__nullius-star__/scenarios/vulcanus-manifest-runner")(config)

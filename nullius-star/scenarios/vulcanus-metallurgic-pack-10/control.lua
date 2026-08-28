require("__nullius-star__/scenarios/vulcanus-manifest-runner"){
  case = "vulcanus-metallurgic-pack-10",
  contract = require("manifest"),
  deadline = 71100,
  fixture = {
    ["nullius-seawater-intake-1"] = 1,
    ["nullius-hydro-plant-1"] = 4,
    ["nullius-small-furnace-1"] = 1,
    ["nullius-small-assembler-1"] = 1,
    ["nullius-vulcanus-radiator-1"] = 1,
    ["nullius-heat-pipe-1"] = 30,
  },
}

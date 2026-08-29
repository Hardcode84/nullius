require("__nullius-star__/scenarios/vulcanus-manifest-runner"){
  case = "vulcanus-metallurgic-pack-10",
  contract = require("manifest"),
  deadline = 220000,
  parallelism = 16,
  parallel_fixture = {
    ["nullius-seawater-intake-1"] = 7,
    ["nullius-hydro-plant-1"] = 12,
    ["nullius-small-furnace-1"] = 15,
    ["nullius-small-assembler-1"] = 15,
    ["nullius-vulcanus-radiator-1"] = 15,
  },
  fixture = {
    ["nullius-seawater-intake-1"] = 1,
    ["nullius-hydro-plant-1"] = 4,
    ["nullius-small-furnace-1"] = 1,
    ["nullius-small-assembler-1"] = 1,
    ["nullius-vulcanus-radiator-1"] = 1,
    ["nullius-heat-pipe-1"] = 30,
  },
}

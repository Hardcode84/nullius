local function crusher_or_foundry(id, base, recipe, row, inputs, outputs)
  return {
    id = id,
    base = base,
    recipe = recipe,
    row = row,
    machine_x = 3,
    machine_y_offset = 3,
    inputs = inputs,
    outputs = outputs,
  }
end

local function furnace(id, base, row)
  return {
    id = id,
    base = base,
    recipe = "nullius-aluminum-ingot",
    row = row,
    machine_x = 3.5,
    machine_y_offset = 2.5,
    inputs = {
      ["nullius-alumina"] = 900,
      ["nullius-graphite"] = 500,
    },
    outputs = {
      ["nullius-aluminum-ingot"] = 345,
      ["nullius-aluminum-carbide"] = 460,
    },
  }
end

require("__nullius-star__/scenarios/thermal-cell-runner"){
  case = "thermal-cell-3",
  technology = "nullius-thermal-engineering-3",
  machines_per_cell = 5,
  timeout_tick = 20000,
  min_temperature = 500,
  productivity = 0.15,
  heat_source = "nullius-reactor",
  heat_pipe = "nullius-heat-pipe-3",
  source_fuel = "nullius-fusion-cell",
  source_fuel_count = 2,
  source_connection_offset = {3, 0},
  max_heat_pipes = 20,
  freeze_daytime = false,
  clear_area = {{-18, -32}, {46, 36}},
  cells = {
    crusher_or_foundry(
      "crusher", "nullius-crusher-3", "nullius-crushed-limestone", -24,
      {["nullius-limestone"] = 800},
      {["nullius-crushed-limestone"] = 575, stone = 345}),
    furnace("small-furnace", "nullius-small-furnace-3", -8),
    furnace("medium-furnace", "nullius-medium-furnace-3", 8),
    crusher_or_foundry(
      "foundry", "nullius-foundry-3", "nullius-iron-plate", 24,
      {["nullius-iron-ingot"] = 400},
      {["nullius-iron-plate"] = 345}),
  },
}

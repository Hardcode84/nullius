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

local function furnace(id, base, row, recipe, inputs, outputs)
  return {
    id = id,
    base = base,
    recipe = recipe or "nullius-aluminum-ingot",
    row = row,
    machine_x = 3.5,
    machine_y_offset = 2.5,
    inputs = inputs or {
      ["nullius-alumina"] = 900,
      ["nullius-graphite"] = 500,
    },
    outputs = outputs or {
      ["nullius-aluminum-ingot"] = 330,
      ["nullius-aluminum-carbide"] = 440,
    },
  }
end

require("__nullius-star__/scenarios/thermal-cell-runner"){
  case = "thermal-cell-2",
  technology = "nullius-thermal-engineering-2",
  machines_per_cell = 5,
  timeout_tick = 65000,
  min_temperature = 200,
  productivity = 0.10,
  heat_source = "nullius-solar-collector-2",
  heat_pipe = "nullius-heat-pipe-2",
  source_connection_offset = {3, 0.5},
  max_heat_pipes = 25,
  freeze_daytime = true,
  clear_area = {{-18, -38}, {46, 42}},
  cells = {
    crusher_or_foundry(
      "crusher", "nullius-crusher-2", "nullius-crushed-limestone", -30,
      {["nullius-limestone"] = 800},
      {["nullius-crushed-limestone"] = 550, stone = 330}),
    furnace("small-furnace", "nullius-small-furnace-2", -16),
    furnace("medium-furnace", "nullius-medium-furnace-2", -2),
    furnace(
      "large-furnace", "nullius-large-furnace-2", 12,
      "nullius-boxed-refractory-brick",
      {["nullius-box-ceramic-powder"] = 200},
      {["nullius-box-refractory-brick"] = 660}),
    crusher_or_foundry(
      "foundry", "nullius-foundry-2", "nullius-iron-plate", 28,
      {["nullius-iron-ingot"] = 400},
      {["nullius-iron-plate"] = 330}),
  },
}

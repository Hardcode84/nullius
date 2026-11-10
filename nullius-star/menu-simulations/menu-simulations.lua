---@type data.SimulationDefinition
local nullius_solar_panels = {
  checkboard = false,
  save = "__nullius-star__/menu-simulations/solar-panels.zip",
  length = 20 * second,
  init = [[
    local logo = game.surfaces.nauvis.find_entities_filtered{name = "factorio-logo-11tiles", limit = 1}[1]
    logo.destructible = false
    game.simulation.camera_position = {logo.position.x, logo.position.y + 12}
    game.simulation.camera_zoom = 1
    game.tick_paused = false
  ]],
}

---@type data.SimulationDefinition
local nullius_labs = {
  checkboard = false,
  save = "__nullius-star__/menu-simulations/labs.zip",
  length = 15 * second,
  init = [[
    local logo = game.surfaces.nauvis.find_entities_filtered{name = "factorio-logo-16tiles", limit = 1}[1]
    logo.destructible = false
    game.simulation.camera_position = {logo.position.x, logo.position.y + 18}
    game.simulation.camera_zoom = 2/3
    game.tick_paused = false
  ]],
}

---@type data.SimulationDefinition
local nullius_fertilizer = {
  checkboard = false,
  save = "__nullius-star__/menu-simulations/fertilizer.zip",
  length = 20 * second,
  init = [[
    local logo = game.surfaces.nauvis.find_entities_filtered{name = "factorio-logo-11tiles", limit = 1}[1]
    logo.destructible = false
    game.simulation.camera_position = {logo.position.x, logo.position.y - 14}
    game.simulation.camera_zoom = 1
    game.tick_paused = false
  ]],
}

---@type data.SimulationDefinition
local nullius_rocket_fuel = {
  checkboard = false,
  save = "__nullius-star__/menu-simulations/rocket-fuel.zip",
  length = 20 * second,
  init = [[
    local logo = game.surfaces.nauvis.find_entities_filtered{name = "factorio-logo-22tiles", limit = 1}[1]
    logo.destructible = false
    game.simulation.camera_position = {logo.position.x, logo.position.y + 26}
    game.simulation.camera_zoom = 0.5
    game.tick_paused = false
  ]],
}

---@type data.SimulationDefinition
local nullius_algae = {
  checkboard = false,
  save = "__nullius-star__/menu-simulations/algae.zip",
  length = 20 * second,
  init = [[
    local logo = game.surfaces.nauvis.find_entities_filtered{name = "factorio-logo-22tiles", limit = 1}[1]
    logo.destructible = false
    game.simulation.camera_position = {logo.position.x, logo.position.y - 30}
    game.simulation.camera_zoom = 0.5
    game.tick_paused = false
  ]],
}

---@type data.SimulationDefinition
local nullius_blue_science = {
  checkboard = false,
  save = "__nullius-star__/menu-simulations/blue-science.zip",
  length = 20 * second,
  init = [[
    local logo = game.surfaces.nauvis.find_entities_filtered{name = "factorio-logo-22tiles", limit = 1}[1]
    logo.destructible = false
    game.simulation.camera_position = {logo.position.x, logo.position.y - 30}
    game.simulation.camera_zoom = 0.5
    game.tick_paused = false
  ]],
}

---@type data.SimulationDefinition
local nullius_epoxy = {
  checkboard = false,
  save = "__nullius-star__/menu-simulations/epoxy.zip",
  length = 20 * second,
  init = [[
    local logo = game.surfaces.nauvis.find_entities_filtered{name = "factorio-logo-16tiles", limit = 1}[1]
    logo.destructible = false
    game.simulation.camera_position = {logo.position.x, logo.position.y + 28}
    game.simulation.camera_zoom = 0.5
    game.tick_paused = false
  ]],
}

---@type data.SimulationDefinition
local nullius_trains = {
  checkboard = false,
  save = "__nullius-star__/menu-simulations/trains.zip",
  length = 23 * second,
  init = [[
    local logo = game.surfaces.nauvis.find_entities_filtered{name = "factorio-logo-11tiles", limit = 1}[1]
    logo.destructible = false
    game.simulation.camera_position = {logo.position.x, logo.position.y + 12}
    game.simulation.camera_zoom = 1
    game.tick_paused = false
  ]],
}

---@type data.SimulationDefinition
local nullius_early_power = {
  checkboard = false,
  save = "__nullius-star__/menu-simulations/early-power.zip",
  length = 15 * second,
  init = [[
    local logo = game.surfaces.nauvis.find_entities_filtered{name = "factorio-logo-22tiles", limit = 1}[1]
    logo.destructible = false
    game.simulation.camera_position = {logo.position.x, logo.position.y - 24}
    game.simulation.camera_zoom = 0.5
    game.tick_paused = false
  ]],
}

local simulations = {
  nullius_solar_panels = nullius_solar_panels,
  nullius_labs = nullius_labs,
  nullius_fertilizer = nullius_fertilizer,
  nullius_rocket_fuel = nullius_rocket_fuel,
  nullius_algae = nullius_algae,
  nullius_blue_science = nullius_blue_science,
  nullius_expoxy = nullius_epoxy,
  nullius_trains = nullius_trains,
  nullius_early_power = nullius_early_power,
}

-- Uncomment to debug a single visualization
-- simulations = { nullius_trains }

return simulations

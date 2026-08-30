local CASE = "vulcanus-high-temperature-resin"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local HOT_RECIPE = "nullius-high-temperature-resin"
local GAS = "nullius-compressed-volcanic-gas"

local assertions = 0
local failures = {}
local observations = {}

local function check(condition, message)
  assertions = assertions + 1
  if not condition then failures[#failures + 1] = message end
  return condition
end

local function close(actual, expected)
  return math.abs(actual - expected) < 0.000001
end

local function finish()
  local result = {
    schema = 1,
    case = CASE,
    status = (#failures == 0) and "pass" or "fail",
    factorio_version = script.active_mods.base,
    tick = game.tick,
    assertions = assertions,
    failure_count = #failures,
    failures = failures,
    observations = observations,
  }
  helpers.write_file(RESULT, helpers.table_to_json(result), false)
  if #failures > 0 then error(helpers.table_to_json(result)) end
end

local function clear(surface, area)
  surface.request_to_generate_chunks({0, 0}, 2)
  surface.force_generate_chunk_requests()
  for _, entity in ipairs(surface.find_entities_filtered{
      area = area,
      type = {"simple-entity", "tree", "cliff", "resource"},
  }) do entity.destroy() end
end

local function place(surface, name, position)
  local entity = surface.create_entity{
    name = name,
    position = position,
    force = game.forces.player,
  }
  check(entity ~= nil, "failed to place " .. name)
  return entity
end

local function fluid_box(machine, fluid, role)
  if role == "fuel" then
    for index = 1, #machine.fluidbox do
      if not machine.fluidbox.get_filter(index) then return index end
    end
    return nil
  end
  for index = 1, #machine.fluidbox do
    local filter = machine.fluidbox.get_filter(index)
    if filter and filter.name == fluid then return index end
  end
  return nil
end

local function set_fluid(machine, fluid, amount, role)
  local index = fluid_box(machine, fluid, role)
  check(index ~= nil, machine.name .. " has no fluid box for " .. fluid)
  if not index then return end
  machine.fluidbox[index] = {
    name = fluid,
    amount = amount,
    temperature = prototypes.fluid[fluid].default_temperature,
  }
  local stored = machine.fluidbox[index]
  check(stored and stored.name == fluid and close(stored.amount, amount),
    machine.name .. " failed to store " .. amount .. " " .. fluid)
end

local function terminal_check()
  script.on_nth_tick(2300, nil)
  local machine = storage.machine
  check(machine and machine.valid, "resin machine disappeared")
  if not machine or not machine.valid then finish() return end

  local epoxy_box = fluid_box(machine, "nullius-epoxy")
  local wastewater_box = fluid_box(machine, "nullius-wastewater")
  check(epoxy_box ~= nil, "resin machine has no epoxy output")
  check(wastewater_box ~= nil, "resin machine has no wastewater output")
  local epoxy = epoxy_box and machine.fluidbox[epoxy_box]
  local wastewater = wastewater_box and machine.fluidbox[wastewater_box]
  local output = machine.get_output_inventory()

  observations.products_finished = machine.products_finished
  observations.epoxy = epoxy and {
    amount = epoxy.amount,
    temperature = epoxy.temperature,
  } or nil
  observations.wastewater = wastewater and wastewater.amount or 0
  observations.items = output.get_contents()

  check(machine.products_finished == 1,
    "expected one resin cycle, found " .. machine.products_finished)
  check(epoxy and close(epoxy.amount, 40),
    "expected 40 high-temperature resin")
  check(epoxy and close(epoxy.temperature, 200),
    "high-temperature resin did not leave at 200 C")
  check(wastewater and close(wastewater.amount, 50),
    "expected 50 wastewater")
  check(output.get_item_count("barrel") == 3,
    "resin recipe did not return three barrels")
  check(output.get_item_count("nullius-alumina") == 1,
    "resin recipe did not return its alumina catalyst")
  finish()
end

local function setup()
  script.on_nth_tick(1, nil)
  local force = game.forces.player
  force.technologies["nullius-pneumatic-technology"].researched = true
  force.recipes[HOT_RECIPE].enabled = true

  local planet = game.planets["nullius-vulcanus"]
  local vulcanus = planet.surface or planet.create_surface()
  clear(vulcanus, {{-24, -16}, {24, 16}})
  local vulcanus_plant = place(vulcanus, "nullius-chemical-plant-1", {-10, 0})
  if not vulcanus_plant then finish() return end

  local position = vulcanus_plant.position
  check(remote.interfaces["nullius-test-transitions"] ~= nil,
    "transition test interface is missing")
  if not remote.interfaces["nullius-test-transitions"] then finish() return end
  check(remote.call("nullius-test-transitions", "execute", vulcanus_plant),
    "chemical plant has no pneumatic transition")
  local machine = vulcanus.find_entity(
    "nullius-chemical-plant-1-pneumatic", position)
  check(machine ~= nil, "chemical plant did not enter pneumatic mode")
  if not machine then finish() return end
  storage.machine = machine
  machine.active = false
  check(machine.set_recipe(HOT_RECIPE),
    "high-temperature resin is unavailable on Vulcanus")

  local input = machine.get_inventory(defines.inventory.assembling_machine_input)
  check(input.insert{name = "nullius-acrylonitrile-barrel", count = 2} == 2,
    "failed to insert acrylonitrile barrels")
  check(input.insert{name = "nullius-ammonia-barrel", count = 1} == 1,
    "failed to insert ammonia barrel")
  check(input.insert{name = "nullius-alumina", count = 1} == 1,
    "failed to insert alumina catalyst")
  set_fluid(machine, "nullius-benzene", 30)
  set_fluid(machine, "nullius-oxygen", 100)
  set_fluid(machine, "nullius-solvent", 10)
  set_fluid(machine, GAS, 100, "fuel")

  if #failures > 0 then finish() return end
  machine.active = true
  script.on_nth_tick(2300, terminal_check)
end

script.on_nth_tick(1, setup)

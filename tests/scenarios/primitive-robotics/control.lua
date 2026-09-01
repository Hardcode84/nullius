local CASE = "primitive-robotics"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local PORT = "nullius-clockwork-roboport"
local ROBOT = "nullius-clockwork-logistic-robot"
local STORAGE = "nullius-primitive-storage-chest"
local SUPPLY = "nullius-primitive-supply-chest"
local DEMAND = "nullius-primitive-demand-chest"
local TECHNOLOGY = "nullius-primitive-robotics"

local assertions = 0
local failures = {}
local observations = {expired_robots = 0}

local function check(condition, message)
  assertions = assertions + 1
  if not condition then failures[#failures + 1] = message end
end

local function named_amounts(entries)
  local result = {}
  for _, entry in pairs(entries) do result[entry.name] = entry.amount end
  return result
end

local function check_exact(actual, expected, label)
  for name, amount in pairs(expected) do
    check(actual[name] == amount,
      label .. " expected " .. name .. "=" .. amount)
  end
  for name, amount in pairs(actual) do
    check(expected[name] == amount,
      label .. " contained unexpected " .. name .. "=" .. amount)
  end
end

local function finish()
  if storage.finished then return end
  storage.finished = true
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

local function request(entity, count)
  local sections = entity.get_logistic_sections()
  check(sections ~= nil, entity.name .. " has no logistic sections")
  if not sections then return end
  local section = sections.get_section(1) or sections.add_section()
  check(section ~= nil, "could not create requester section")
  if section then
    section.set_slot(1, {
      value = {type = "item", name = "stone", quality = "normal"},
      min = count,
      max = count,
    })
  end
end

local function create(surface, name, position)
  local entity = surface.create_entity{
    name = name,
    position = position,
    force = game.forces.player,
  }
  check(entity ~= nil, "failed to create " .. name)
  return entity
end

local function prepare_surface()
  local planet = game.planets["nullius-vulcanus"]
  check(planet ~= nil, "missing nullius-vulcanus planet")
  if not planet then return nil end
  local surface = planet.surface or planet.create_surface()
  surface.request_to_generate_chunks({46, 50}, 6)
  surface.force_generate_chunk_requests()
  local tiles = {}
  for x = -16, 108 do
    for y = -16, 116 do
      tiles[#tiles + 1] = {name = "volcanic-soil-dark", position = {x, y}}
    end
  end
  surface.set_tiles(tiles, true, false, false, false)
  for _, entity in ipairs(surface.find_entities_filtered{
      area = {{-16, -16}, {108, 116}},
      type = {"simple-entity", "tree", "cliff", "resource"},
  }) do
    entity.destroy()
  end
  return surface
end

local function check_prototypes(surface)
  local force = game.forces.player
  local technology = force.technologies[TECHNOLOGY]
  check(technology ~= nil, "missing Primitive Robotics technology")
  if technology then
    check(technology.prototype.research_unit_count == 5,
      "Primitive Robotics does not have five research units")
    check(technology.prototype.research_unit_energy == 1800,
      "Primitive Robotics research unit time is not 30 seconds")
    check_exact(named_amounts(technology.prototype.research_unit_ingredients), {
      ["nullius-metallurgic-pack"] = 5,
      ["nullius-mechanical-pack"] = 2,
      ["nullius-electrical-pack"] = 2,
    }, "Primitive Robotics research ingredients")
    local prerequisites = {}
    for _, prerequisite in pairs(technology.prototype.prerequisites) do
      prerequisites[prerequisite.name] = 1
    end
    check_exact(prerequisites, {
      ["nullius-efficient-metallurgic-science"] = 1,
      ["nullius-weaving-1"] = 1,
    }, "Primitive Robotics prerequisites")
    technology.researched = false
    for _, name in ipairs({PORT, ROBOT, STORAGE, SUPPLY, DEMAND}) do
      check(force.recipes[name] and not force.recipes[name].enabled,
        name .. " was enabled before Primitive Robotics")
    end
    technology.researched = true
    for _, name in ipairs({PORT, ROBOT, STORAGE, SUPPLY, DEMAND}) do
      check(force.recipes[name] and force.recipes[name].enabled,
        "Primitive Robotics did not unlock " .. name)
      check(prototypes.recipe[name].surface_conditions == nil,
        name .. " recipe is surface-gated")
    end
  end

  check_exact(named_amounts(prototypes.recipe[ROBOT].ingredients), {
    ["nullius-steel-gear"] = 1,
    ["nullius-steel-wire"] = 1,
    ["nullius-aluminum-sheet"] = 1,
  }, "clockwork robot ingredients")
  check_exact(named_amounts(prototypes.recipe[STORAGE].ingredients), {
    ["iron-chest"] = 1,
    ["nullius-steel-sheet"] = 3,
    ["nullius-aluminum-sheet"] = 3,
  }, "primitive storage chest ingredients")
  check_exact(named_amounts(prototypes.recipe[SUPPLY].ingredients), {
    ["iron-chest"] = 1,
    ["nullius-steel-sheet"] = 2,
    ["nullius-steel-gear"] = 1,
  }, "primitive supply chest ingredients")
  check_exact(named_amounts(prototypes.recipe[DEMAND].ingredients), {
    ["iron-chest"] = 1,
    ["nullius-aluminum-sheet"] = 2,
    ["nullius-steel-gear"] = 1,
  }, "primitive demand chest ingredients")

  local nauvis = game.surfaces.nauvis
  for _, name in ipairs({PORT, ROBOT, STORAGE, SUPPLY, DEMAND}) do
    check(not nauvis.can_place_entity{name = name, position = {0, 0},
      force = force}, name .. " can be placed on Nauvis")
  end
  for tier = 1, 4 do
    local name = "nullius-logistic-bot-" .. tier
    check(nauvis.can_place_entity{name = name, position = {0, tier * 2},
      force = force}, name .. " cannot be placed on Nauvis")
    check(not surface.can_place_entity{name = name, position = {60, tier * 2},
      force = force}, name .. " can be placed on Vulcanus")
  end

  local port = prototypes.entity[PORT]
  local robot = prototypes.entity[ROBOT]
  check(port.void_energy_source_prototype ~= nil,
    "clockwork roboport does not use void energy")
  check(port.construction_radius == 0,
    "clockwork roboport has construction coverage")
  check(robot.min_to_charge == 0, "clockwork robot min_to_charge is not zero")
  check(robot.max_to_charge == 1, "clockwork robot max_to_charge is not one")
  check(robot.speed_multiplier_when_out_of_energy == 0,
    "clockwork robot can move without energy")

  local storage_chest = create(surface, STORAGE, {-14, 0})
  local supply_chest = create(surface, SUPPLY, {-12, 0})
  local demand_chest = create(surface, DEMAND, {-10, 0})
  if storage_chest then
    check(#storage_chest.get_inventory(defines.inventory.chest) == 6,
      "primitive storage chest does not have 6 slots")
  end
  if supply_chest then
    check(#supply_chest.get_inventory(defines.inventory.chest) == 2,
      "primitive supply chest does not have 2 slots")
  end
  if demand_chest then
    check(#demand_chest.get_inventory(defines.inventory.chest) == 2,
      "primitive requester chest does not have 2 slots")
    local sections = demand_chest.get_logistic_sections()
    local section = sections and
      (sections.get_section(1) or sections.add_section())
    if section then
      section.set_slot(1, {
        value = {type = "item", name = "stone", quality = "normal"},
        min = 1,
      })
      section.set_slot(2, {
        value = {type = "item", name = "iron-ore", quality = "normal"},
        min = 1,
      })
    end
    check(section and section.filters_count == 2,
      "primitive requester chest does not have 2 request slots")
  end
  if storage_chest then storage_chest.destroy() end
  if supply_chest then supply_chest.destroy() end
  if demand_chest then demand_chest.destroy() end
end

local function setup_networks(surface)
  storage.short_port = create(surface, PORT, {0, 0})
  storage.short_supply = create(surface, SUPPLY, {-8, 0})
  storage.short_demand = create(surface, DEMAND, {8, 0})
  if storage.short_supply then storage.short_supply.insert{name = "stone", count = 3} end
  if storage.short_demand then request(storage.short_demand, 3) end
  if storage.short_port then
    local inserted = storage.short_port.get_inventory(
      defines.inventory.roboport_robot).insert{name = ROBOT, count = 3}
    check(inserted == 3, "failed to insert three short-range robots")
  end

  storage.long_ports = {
    create(surface, PORT, {0, 100}),
    create(surface, PORT, {22, 100}),
    create(surface, PORT, {44, 100}),
    create(surface, PORT, {66, 100}),
    create(surface, PORT, {88, 100}),
  }
  storage.long_supply = create(surface, SUPPLY, {-10, 100})
  storage.long_demand = create(surface, DEMAND, {98, 100})
  if storage.long_supply then storage.long_supply.insert{name = "stone", count = 1} end
  if storage.long_demand then request(storage.long_demand, 1) end
  local connected = true
  for index = 1, #storage.long_ports - 1 do
    connected = connected and storage.long_ports[index] and
      storage.long_ports[index + 1] and
      storage.long_ports[index].logistic_network ==
        storage.long_ports[index + 1].logistic_network
  end
  check(connected, "overlapping roboports did not form one logistic network")
  if connected then
    local inserted = storage.long_ports[1].get_inventory(
      defines.inventory.roboport_robot).insert{name = ROBOT, count = 1}
    check(inserted == 1, "failed to insert long-range robot")
  end
end

local function verify()
  script.on_nth_tick(30, nil)
  local short_count = storage.short_demand and storage.short_demand.valid and
    storage.short_demand.get_item_count("stone") or 0
  local long_supply_count = storage.long_supply and storage.long_supply.valid and
    storage.long_supply.get_item_count("stone") or 0
  local long_demand_count = storage.long_demand and storage.long_demand.valid and
    storage.long_demand.get_item_count("stone") or 0
  local flying = storage.surface.count_entities_filtered{name = ROBOT}
  local spilled = storage.surface.count_entities_filtered{type = "item-entity"}
  observations.short_delivered = short_count
  observations.long_supply_remaining = long_supply_count
  observations.long_delivered = long_demand_count
  observations.flying_robots = flying
  observations.spilled_item_entities = spilled
  check(short_count == 3, "short-range network did not deliver all three items")
  check(long_supply_count == 0, "long-range robot never collected its cargo")
  check(long_demand_count == 0, "long-range robot unexpectedly delivered its cargo")
  check(flying == 0, "clockwork robots did not expire at zero energy")
  check(spilled == 0, "expired robot spilled its cargo")
  check(observations.expired_robots == 4,
    "expected four expired robots, found " .. observations.expired_robots)
  finish()
end

local function setup()
  script.on_nth_tick(1, nil)
  storage.surface = prepare_surface()
  if not storage.surface then finish() return end
  check_prototypes(storage.surface)
  setup_networks(storage.surface)
  script.on_nth_tick(30, function()
    if game.tick >= 1500 then verify() end
  end)
end

script.on_event(defines.events.on_worker_robot_expired, function(event)
  if event.robot and event.robot.name == ROBOT then
    observations.expired_robots = observations.expired_robots + 1
  end
end)

script.on_nth_tick(1, setup)

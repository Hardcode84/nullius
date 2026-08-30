local CASE = "industrial-optimization-1"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local LAB = "nullius-lab-1-pneumatic"
local PACK = "nullius-metallurgic-pack"
local GAS = "nullius-compressed-volcanic-gas"
local LAB_COUNT = 100
local PACKS_PER_LAB = 3
local TOTAL_PACKS = LAB_COUNT * PACKS_PER_LAB
local TIMEOUT_TICK = 6000
local TECHNOLOGIES = {
  {
    name = "nullius-crushing-productivity-1",
    prerequisite = "nullius-mineral-processing-1",
    recipe = "nullius-crushed-limestone",
  },
  {
    name = "nullius-smelting-productivity-1",
    prerequisite = "nullius-metallurgy-1",
    recipe = "nullius-aluminum-ingot",
  },
  {
    name = "nullius-casting-productivity-1",
    prerequisite = "nullius-metalworking-1",
    recipe = "nullius-iron-plate",
  },
}

local assertions = 0
local failures = {}
local observations = {research = {}}
local timeout

local function check(condition, message)
  assertions = assertions + 1
  if not condition then failures[#failures + 1] = message end
end

local function close(actual, expected)
  return math.abs(actual - expected) < 0.000001
end

local function finish()
  script.on_nth_tick(TIMEOUT_TICK, nil)
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

local function remaining_packs()
  local count = 0
  for _, inventory in ipairs(storage.lab_inventories or {}) do
    count = count + inventory.get_item_count(PACK)
  end
  return count
end

local function start_research(index)
  local force = game.forces.player
  local test = TECHNOLOGIES[index]
  local technology = force.technologies[test.name]
  check(force.add_research(technology),
    "Factorio refused to start " .. test.name)
  check(force.current_research == technology,
    test.name .. " is not current research")
end

local function terminal_check()
  local force = game.forces.player
  observations.terminal = {
    elapsed_ticks = game.tick - storage.started_tick,
    remaining_packs = remaining_packs(),
    finished_events = storage.finished_events,
  }
  check(storage.finished_events == #TECHNOLOGIES,
    "expected exactly three research-finished events")
  check(remaining_packs() == 0,
    "expected all 300 metallurgic packs consumed, found " ..
    remaining_packs())
  check(force.current_research == nil,
    "research queue was not empty after the third technology")

  for _, test in ipairs(TECHNOLOGIES) do
    local technology = force.technologies[test.name]
    local bonus = force.recipes[test.recipe].productivity_bonus
    check(technology.level == 2,
      test.name .. " expected level 2, found " .. technology.level)
    check(technology.research_unit_count == 400,
      test.name .. " expected next cost 400, found " ..
      technology.research_unit_count)
    check(not technology.researched,
      test.name .. " became permanently researched")
    check(close(bonus, 0.01),
      test.recipe .. " expected productivity 0.01, found " .. bonus)

    local successors = 0
    for _ in pairs(technology.successors) do successors = successors + 1 end
    check(successors == 0,
      test.name .. " unexpectedly gates " .. successors .. " technologies")
  end
  finish()
end

script.on_event(defines.events.on_research_finished, function(event)
  if storage.finished_events == nil then return end
  local expected = TECHNOLOGIES[storage.finished_events + 1]
  if not expected or event.research.name ~= expected.name then return end

  storage.finished_events = storage.finished_events + 1
  local packs = remaining_packs()
  observations.research[storage.finished_events] = {
    technology = event.research.name,
    tick = game.tick,
    elapsed_ticks = game.tick - storage.started_tick,
    by_script = event.by_script,
    remaining_packs = packs,
  }
  check(not event.by_script,
    event.research.name .. " was completed by script")
  check(packs == TOTAL_PACKS - 100 * storage.finished_events,
    event.research.name .. " consumed an unexpected number of packs")

  local next_index = storage.finished_events + 1
  script.on_nth_tick(game.tick + 1, function()
    script.on_nth_tick(game.tick, nil)
    if next_index <= #TECHNOLOGIES then
      start_research(next_index)
    else
      terminal_check()
    end
  end)
end)

local function setup()
  script.on_nth_tick(1, nil)
  local force = game.forces.player
  local planet = game.planets["nullius-vulcanus"]
  check(planet ~= nil, "missing nullius-vulcanus planet")
  if not planet then finish() return end
  local surface = planet.surface or planet.create_surface()
  check(surface ~= nil, "failed to create Vulcanus surface")
  if not surface then finish() return end

  surface.request_to_generate_chunks({0, 0}, 3)
  surface.force_generate_chunk_requests()
  local tiles = {}
  for x = -42, 42 do
    for y = -42, 42 do
      tiles[#tiles + 1] = {
        name = "volcanic-soil-dark",
        position = {x, y},
      }
    end
  end
  surface.set_tiles(tiles, true, false, false, false)
  for _, entity in ipairs(surface.find_entities_filtered{
      area = {{-42, -42}, {42, 42}},
      type = {"simple-entity", "tree", "cliff", "resource"},
  }) do
    entity.destroy()
  end

  force.technologies["nullius-efficient-metallurgic-science"].researched = true
  for _, test in ipairs(TECHNOLOGIES) do
    force.technologies[test.prerequisite].researched = true
    local technology = force.technologies[test.name]
    technology.enabled = true
    technology.researched = false
  end

  storage.lab_inventories = {}
  for row = 0, 9 do
    for column = 0, 9 do
      local lab = surface.create_entity{
        name = LAB,
        position = {column * 8 - 36, row * 8 - 36},
        direction = defines.direction.north,
        force = force,
      }
      check(lab ~= nil, "failed to place pneumatic lab")
      if not lab then finish() return end
      lab.active = false

      local inventory = lab.get_inventory(defines.inventory.lab_input)
      check(inventory ~= nil, "pneumatic lab has no input inventory")
      if not inventory then finish() return end
      check(inventory.insert{name = PACK, count = PACKS_PER_LAB} ==
          PACKS_PER_LAB,
        "failed to insert metallurgic packs into pneumatic lab")
      storage.lab_inventories[#storage.lab_inventories + 1] = inventory

      local gas_box = nil
      for index = 1, #lab.fluidbox do
        local filter = lab.fluidbox.get_filter(index)
        if filter and filter.name == GAS then gas_box = index end
      end
      if not gas_box and #lab.fluidbox == 1 then gas_box = 1 end
      check(gas_box ~= nil, "pneumatic lab has no compressed-gas input")
      if not gas_box then finish() return end
      local connection = lab.fluidbox.get_pipe_connections(gas_box)[1]
      check(connection ~= nil,
        "pneumatic lab compressed-gas input has no connection")
      if not connection then finish() return end
      local source = surface.create_entity{
        name = "infinity-pipe",
        position = connection.target_position,
        force = force,
      }
      check(source ~= nil, "failed to place compressed-gas source")
      if not source then finish() return end
      source.set_infinity_pipe_filter{
        name = GAS,
        percentage = 1,
        mode = "at-least",
        temperature = prototypes.fluid[GAS].default_temperature,
      }
    end
  end

  check(#storage.lab_inventories == LAB_COUNT,
    "expected 100 pneumatic labs")
  check(remaining_packs() == TOTAL_PACKS,
    "research fixture does not contain exactly 300 metallurgic packs")
  if #failures > 0 then finish() return end

  storage.finished_events = 0
  storage.started_tick = game.tick
  for _, lab in ipairs(surface.find_entities_filtered{name = LAB}) do
    lab.active = true
  end
  start_research(1)
  script.on_nth_tick(TIMEOUT_TICK, timeout)
end

timeout = function()
  observations.timeout = {
    current_research = game.forces.player.current_research and
      game.forces.player.current_research.name,
    research_progress = game.forces.player.research_progress,
    remaining_packs = remaining_packs(),
    finished_events = storage.finished_events or 0,
  }
  check(false, "industrial optimization research exceeded tick budget")
  finish()
end

script.on_nth_tick(1, setup)

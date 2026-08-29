local CASE = "pneumatic-barrel-pumps"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local MACHINES = {
  "nullius-barrel-pump-1",
  "nullius-barrel-pump-2",
}

local assertions = 0
local failures = {}
local observations = {machines = {}}

local function check(condition, message)
  assertions = assertions + 1
  if not condition then failures[#failures + 1] = message end
  return condition
end

local function close(actual, expected)
  return math.abs(actual - expected) < 0.000001
end

local function values_to_set(values)
  local result = {}
  for key, value in pairs(values or {}) do
    if type(key) == "number" then result[value] = true
    elseif value then result[key] = true end
  end
  return result
end

local function check_exact(actual, expected, label)
  for name, value in pairs(expected) do
    check(actual[name] == value, label .. " missing " .. name)
  end
  for name, value in pairs(actual) do
    check(expected[name] == value, label .. " contains unexpected " .. name)
  end
end

local function entities_at(surface, name, position)
  return surface.find_entities_filtered{
    name = name,
    position = position,
    radius = 0.1,
  }
end

local function research_closure(technology, visited)
  if visited[technology.name] then return end
  visited[technology.name] = true
  for _, prerequisite in pairs(technology.prerequisites) do
    research_closure(prerequisite, visited)
  end
  technology.researched = true
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

local function setup()
  script.on_nth_tick(1, nil)
  local technology = game.forces.player.technologies["nullius-pneumatic-technology"]
  if not check(technology ~= nil, "missing pneumatic technology") then
    finish()
    return
  end
  research_closure(technology, {})

  local planet = game.planets["nullius-vulcanus"]
  if not check(planet ~= nil, "missing Vulcanus planet") then finish() return end
  local surface = planet.surface or planet.create_surface()
  if not check(surface ~= nil, "failed to create Vulcanus surface") then
    finish()
    return
  end
  surface.request_to_generate_chunks({0, 0}, 3)
  surface.force_generate_chunk_requests()
  local tiles = {}
  for x = -24, 24 do
    for y = -12, 12 do
      tiles[#tiles + 1] = {name = "volcanic-soil-dark", position = {x, y}}
    end
  end
  surface.set_tiles(tiles, true, false, false, false)

  check(remote.interfaces["nullius-test-transitions"] ~= nil,
    "transition test interface is missing")
  if not remote.interfaces["nullius-test-transitions"] then finish() return end

  for index, base_name in ipairs(MACHINES) do
    local pneumatic_name = base_name .. "-pneumatic"
    local base = prototypes.entity[base_name]
    local pneumatic = prototypes.entity[pneumatic_name]
    check(base ~= nil, base_name .. " base prototype is missing")
    check(pneumatic ~= nil, pneumatic_name .. " prototype is missing")
    if base and pneumatic then
      check_exact(values_to_set(pneumatic.crafting_categories),
        values_to_set(base.crafting_categories), base_name .. " categories")
      check_exact(values_to_set(pneumatic.allowed_effects),
        values_to_set(base.allowed_effects), base_name .. " effects")
      check(close(pneumatic.get_crafting_speed(), base.get_crafting_speed()),
        base_name .. " crafting speed changed")
      check(pneumatic.module_inventory_size == base.module_inventory_size,
        base_name .. " module count changed")
      check(close(pneumatic.get_max_energy_usage(), base.get_max_energy_usage()),
        base_name .. " energy usage changed")
      check(pneumatic.electric_energy_source_prototype == nil,
        pneumatic_name .. " retained electric power")
      check(pneumatic.fluid_energy_source_prototype ~= nil,
        pneumatic_name .. " has no fluid power source")
      check(#pneumatic.items_to_place_this == 1 and
        pneumatic.items_to_place_this[1].name == base_name,
        pneumatic_name .. " has the wrong placement item")
    end

    local machine = surface.create_entity{
      name = base_name,
      position = {-10 + (index - 1) * 20, 0},
      force = game.forces.player,
    }
    if check(machine ~= nil, "failed to place " .. base_name) then
      local position = {machine.position.x, machine.position.y}
      check(remote.call("nullius-test-transitions", "execute", machine),
        base_name .. " has no pneumatic transition")
      local pneumatic_entities = entities_at(surface, pneumatic_name, position)
      check(#pneumatic_entities == 1,
        base_name .. " did not transition to " .. pneumatic_name)
      check(#entities_at(surface, "nullius-pneumatic-heat-medium", position) == 1,
        pneumatic_name .. " has the wrong heat interface")
      if #pneumatic_entities == 1 then
        check(remote.call("nullius-test-transitions", "execute",
          pneumatic_entities[1]), pneumatic_name .. " has no electric transition")
      end
      check(#entities_at(surface, base_name, position) == 1,
        pneumatic_name .. " did not transition back to " .. base_name)
      check(#entities_at(surface, "nullius-pneumatic-heat-medium", position) == 0,
        pneumatic_name .. " left an orphan heat interface")
    end
    observations.machines[base_name] = pneumatic_name
  end
  finish()
end

script.on_nth_tick(1, setup)

-- given: three technologies: geology + climatology, climatology only, and
--   geology x20 + climatology x1 per unit; declared unlimited electricity.
-- place: one lab on Nauvis and one lab on a second surface.
-- connect: each lab to its own supplied electric grid.
-- act: split packs between the labs, then give one lab both, then switch the
--   active technology, then research the asymmetric technology.
-- run: 300-tick windows with scheduled checks.
-- expect: a technology progresses only in a lab holding all its ingredients;
--   only the active technology progresses; labs lacking its ingredients idle
--   and keep their packs; one asymmetric unit consumes its full pack ratio.
local CASE = "experiment-research-lab-ingredients"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local TWO = "factorio-test-lab-two-packs"
local ONE = "factorio-test-lab-one-pack"
local ASYMMETRIC = "factorio-test-lab-asymmetric"
local GEOLOGY = "nullius-geology-pack"
local CLIMATOLOGY = "nullius-climatology-pack"
local WINDOW = 300
local UNITS_PER_WINDOW = WINDOW / 60
local TOLERANCE = 0.0005
local MISSING = defines.entity_status.missing_science_packs
local WORKING = defines.entity_status.working

local function check(ok, message)
  storage.assertions = storage.assertions + 1
  if not ok then storage.failures[#storage.failures + 1] = message end
end

local function near(value, expected, message)
  check(math.abs(value - expected) <= TOLERANCE,
    message .. ": expected " .. expected .. ", found " .. value)
end

local function finish()
  local result = {
    schema = 1,
    case = CASE,
    status = (#storage.failures == 0) and "pass" or "fail",
    factorio_version = script.active_mods.base,
    tick = game.tick,
    assertions = storage.assertions,
    failure_count = #storage.failures,
    failures = storage.failures,
    observations = storage.observations,
  }
  helpers.write_file(RESULT, helpers.table_to_json(result), false)
  if #storage.failures > 0 then error(helpers.table_to_json(result)) end
end

local function make_lab(surface)
  surface.request_to_generate_chunks({0, 0}, 1)
  surface.force_generate_chunk_requests()
  for _, entity in pairs(surface.find_entities({{-16, -16}, {16, 16}})) do
    entity.destroy()
  end
  local tiles = {}
  for x = -16, 15 do for y = -16, 15 do
    tiles[#tiles + 1] = {name = "landfill", position = {x, y}}
  end end
  surface.set_tiles(tiles)
  local force = game.forces.player
  local lab = assert(surface.create_entity{
    name = "nullius-lab-1", position = {0, 0}, force = force})
  local grid = assert(surface.create_entity{
    name = "factorio-test-planner-grid", position = {4, 0}, force = force})
  grid.power_production = 100000000
  grid.electric_buffer_size = 100000000
  assert(surface.create_entity{name = "substation", position = {0, 4}, force = force})
  return lab
end

local function packs(lab)
  return lab.get_inventory(defines.inventory.lab_input)
end

local function activate(name)
  local force = game.forces.player
  force.cancel_current_research()
  check(force.add_research(name), "cannot start " .. name)
  check(force.current_research ~= nil and force.current_research.name == name,
    name .. " is not the active technology")
end

local function record(stage)
  storage.observations[stage] = {
    progress = game.forces.player.research_progress,
    home_status = storage.home.status,
    remote_status = storage.remote.status,
    home_geology = packs(storage.home).get_item_count(GEOLOGY),
    home_climatology = packs(storage.home).get_item_count(CLIMATOLOGY),
    remote_climatology = packs(storage.remote).get_item_count(CLIMATOLOGY),
  }
end

local stages = {
  function()
    local force = game.forces.player
    record("split_packs")
    near(force.research_progress, 0, "split packs advanced the technology")
    check(storage.home.status == MISSING, "geology-only lab did not report missing packs")
    check(storage.remote.status == MISSING, "climatology-only lab did not report missing packs")
    packs(storage.home).insert{name = CLIMATOLOGY, count = 50}
  end,
  function()
    local force = game.forces.player
    record("one_complete_lab")
    near(force.research_progress, UNITS_PER_WINDOW / 1000,
      "lab with all ingredients progress")
    check(storage.home.status == WORKING, "lab with all ingredients is not working")
    check(storage.remote.status == MISSING, "incomplete remote lab started working")
    check(packs(storage.remote).get_item_count(CLIMATOLOGY) == 50,
      "incomplete remote lab consumed packs")
    storage.two_progress = force.research_progress
    packs(storage.home).remove{name = CLIMATOLOGY, count = 1000}
    activate(ONE)
  end,
  function()
    local force = game.forces.player
    record("serialized_research")
    near(force.research_progress, UNITS_PER_WINDOW / 1000,
      "active technology progress from the remote lab")
    check(storage.home.status == MISSING, "lab without the active ingredient did not idle")
    check(storage.remote.status == WORKING, "remote lab holding the active ingredient is not working")
    activate(TWO)
    near(force.research_progress, storage.two_progress,
      "inactive technology progress changed")
    local home = packs(storage.home)
    check(home.get_item_count(GEOLOGY) > 0, "idle lab lost its stocked packs")
    home.clear()
    packs(storage.remote).clear()
    check(home.insert{name = GEOLOGY, count = 20} == 20, "asymmetric geology fixture")
    check(home.insert{name = CLIMATOLOGY, count = 1} == 1, "asymmetric climatology fixture")
    activate(ASYMMETRIC)
  end,
  function()
    local force = game.forces.player
    record("asymmetric_unit")
    near(force.research_progress, 0.1, "one asymmetric unit progress")
    check(storage.home.status == MISSING, "lab did not stop after one asymmetric unit")
    check(packs(storage.home).get_item_count(GEOLOGY) == 0, "asymmetric unit left geology")
    check(packs(storage.home).get_item_count(CLIMATOLOGY) == 0, "asymmetric unit left climatology")
    finish()
  end,
}

script.on_nth_tick(1, function()
  if game.tick == 0 then return end
  script.on_nth_tick(1, nil)
  storage.assertions = 0
  storage.failures = {}
  storage.observations = {}
  local force = game.forces.player
  for _, name in pairs({TWO, ONE, ASYMMETRIC}) do
    force.technologies[name].enabled = true
  end
  for _, name in pairs({TWO, ONE, ASYMMETRIC}) do
    check(force.technologies[name].research_unit_ingredients[1] ~= nil, name .. " has no ingredients")
  end
  storage.home = make_lab(game.surfaces.nauvis)
  storage.remote = make_lab(game.create_surface(CASE))
  check(storage.home.surface ~= storage.remote.surface, "labs share a surface")
  packs(storage.home).insert{name = GEOLOGY, count = 50}
  packs(storage.remote).insert{name = CLIMATOLOGY, count = 50}
  activate(TWO)
  storage.stage = 0
  script.on_nth_tick(WINDOW, function()
    storage.stage = storage.stage + 1
    stages[storage.stage]()
    if storage.stage == #stages then script.on_nth_tick(WINDOW, nil) end
  end)
end)

local CASE = "vulcanus-gas-vent-smoke"
local RESULT = "factorio-tests/" .. CASE .. ".json"

local assertions = 0
local failures = {}

local function check(condition, message)
  assertions = assertions + 1
  if not condition then failures[#failures + 1] = message end
end

local function count(surface, name, position)
  return #surface.find_entities_filtered{
    name = name,
    position = position,
    radius = 0.1,
  }
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
  }
  helpers.write_file(RESULT, helpers.table_to_json(result), false)
  if #failures > 0 then error(helpers.table_to_json(result)) end
end

local function check_cleanup()
  script.on_nth_tick(2, nil)
  local surface = game.planets["nullius-vulcanus"].surface
  local position = storage.test_position
  check(count(surface, "nullius-lava-intake-1-gasvent", position) == 0,
    "gas-vent shell survived destruction")
  check(count(surface, "nullius-gas-vent-drill", position) == 0,
    "hidden drill survived shell destruction")
  check(count(surface, "nullius-gas-vent-seam", position) == 0,
    "hidden seam survived shell destruction")
  finish()
end

local function run()
  script.on_nth_tick(1, nil)

  local planet = game.planets["nullius-vulcanus"]
  check(planet ~= nil, "missing nullius-vulcanus planet")
  if not planet then finish() return end

  local surface = planet.surface or planet.create_surface()
  check(surface ~= nil, "failed to create Vulcanus surface")
  if not surface then finish() return end

  surface.request_to_generate_chunks({0, 0}, 1)
  surface.force_generate_chunk_requests()

  local tiles = {}
  for x = -8, 8 do
    for y = -8, 8 do
      tiles[#tiles + 1] = {
        name = (y <= 1) and "lava-hot" or "volcanic-soil-dark",
        position = {x, y},
      }
    end
  end
  surface.set_tiles(tiles, true, false, false, false)

  local shell_name = "nullius-lava-intake-1-gasvent"
  local position = surface.find_non_colliding_position(shell_name, {0, 0}, 64, 1)
  check(position ~= nil, "no valid gas-vent position near Vulcanus origin")
  if not position then finish() return end

  local ghost = surface.create_entity{
    name = "entity-ghost",
    inner_name = shell_name,
    position = position,
    force = game.forces.player,
    expires = false,
  }
  check(ghost ~= nil, "failed to create gas-vent ghost")
  if not ghost then finish() return end

  local _, shell = ghost.revive{raise_revive = true}
  check(shell ~= nil, "failed to revive gas-vent ghost")
  if not shell then finish() return end
  position = shell.position

  check(count(surface, shell_name, position) == 1,
    "expected exactly one visible gas-vent shell")
  check(count(surface, "nullius-gas-vent-drill", position) == 1,
    "production build event did not create exactly one hidden drill")
  check(count(surface, "nullius-gas-vent-seam", position) == 1,
    "production build event did not create exactly one hidden seam")

  local seams = surface.find_entities_filtered{
    name = "nullius-gas-vent-seam",
    position = position,
    radius = 0.1,
  }
  check(#seams == 1 and seams[1].amount == 1000000,
    "single gas-vent seam did not receive the expected amount")

  storage.test_position = position
  shell.destroy()
  script.on_nth_tick(2, check_cleanup)
end

script.on_nth_tick(1, run)

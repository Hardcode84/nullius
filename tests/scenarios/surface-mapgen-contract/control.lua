local CASE = "surface-mapgen-contract"
local RESULT = "factorio-tests/" .. CASE .. ".json"

local hidden_planets = {"vulcanus", "fulgora", "gleba", "aquilo"}
local generated_entity_types = {
  "cliff", "resource", "simple-entity", "tree", "unit", "unit-spawner",
}
local vulcanus_tiles = {
  ["volcanic-soil-dark"] = true,
  ["volcanic-soil-light"] = true,
  ["volcanic-ash-soil"] = true,
  ["volcanic-ash-flats"] = true,
  ["volcanic-ash-light"] = true,
  ["volcanic-ash-dark"] = true,
  ["volcanic-cracks"] = true,
  ["volcanic-cracks-warm"] = true,
  ["volcanic-folds"] = true,
  ["volcanic-folds-flat"] = true,
  lava = true,
  ["lava-hot"] = true,
  ["volcanic-folds-warm"] = true,
  ["volcanic-pumice-stones"] = true,
  ["volcanic-cracks-hot"] = true,
  ["volcanic-jagged-ground"] = true,
  ["volcanic-smooth-stone"] = true,
  ["volcanic-smooth-stone-warm"] = true,
  ["volcanic-ash-cracks"] = true,
}
local vulcanus_entities = {
  ["sulfuric-acid-geyser"] = true,
  ["huge-volcanic-rock"] = true,
  ["big-volcanic-rock"] = true,
  ["crater-cliff"] = true,
  ["cliff-vulcanus"] = true,
  ["vulcanus-chimney"] = true,
  ["vulcanus-chimney-faded"] = true,
  ["vulcanus-chimney-cold"] = true,
  ["vulcanus-chimney-short"] = true,
  ["vulcanus-chimney-truncated"] = true,
}
local nauvis_required_controls = {
  "iron-ore", "nullius-bauxite", "nullius-sandstone",
  "nullius-limestone", "nullius-geothermal",
}
local nauvis_forbidden = {
  "copper-ore", "uranium-ore", "coal", "crude-oil", "stone",
}

local assertions = 0
local failures = {}
local observations = {}

local function check(condition, message)
  assertions = assertions + 1
  if not condition then failures[#failures + 1] = message end
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

local function check_controlled_settings(surface, name)
  local settings = surface.map_gen_settings
  check(settings.no_enemies_mode == true,
    name .. " runtime map settings allow natural enemies")
  check(settings.default_enable_all_autoplace_controls == false,
    name .. " runtime map settings enable unspecified controls")
  for _, kind in pairs({"entity", "tile", "decorative"}) do
    local autoplace = settings.autoplace_settings[kind]
    check(autoplace ~= nil, name .. " has no " .. kind .. " autoplace settings")
    if autoplace then
      check(autoplace.treat_missing_as_default == false,
        name .. " enables unspecified " .. kind .. " autoplace")
    end
  end
end

local function generate(surface, position, radius)
  surface.request_to_generate_chunks(position, radius)
  surface.force_generate_chunk_requests()
end

local function check_nauvis()
  local surface = game.surfaces.nauvis
  check(surface ~= nil, "missing Nauvis surface")
  if not surface then return end
  local settings = surface.map_gen_settings
  for _, name in pairs(nauvis_required_controls) do
    check(settings.autoplace_controls[name] ~= nil,
      "Nauvis is missing autoplace control " .. name)
  end
  for _, name in pairs(nauvis_forbidden) do
    check(settings.autoplace_controls[name] == nil,
      "Nauvis retains forbidden autoplace control " .. name)
    check(settings.autoplace_settings.entity.settings[name] == nil,
      "Nauvis retains forbidden entity autoplace " .. name)
  end
  generate(surface, {512, 512}, 1)
  for _, name in pairs(nauvis_forbidden) do
    local count = prototypes.entity[name] and
      surface.count_entities_filtered{name = name} or 0
    check(count == 0, "Nauvis generated forbidden entity " .. name)
  end
end

local function check_vulcanus()
  local planet = game.planets["nullius-vulcanus"]
  check(planet ~= nil, "missing Nullius Vulcanus planet")
  if not planet then return end
  local surface = planet.surface or planet.create_surface()
  check(surface ~= nil, "failed to create Nullius Vulcanus surface")
  if not surface then return end
  check_controlled_settings(surface, "Nullius Vulcanus")
  local controls = surface.map_gen_settings.autoplace_controls
  check(controls.sulfuric_acid_geyser ~= nil,
    "Nullius Vulcanus is missing geyser autoplace control")
  check(controls.vulcanus_volcanism ~= nil,
    "Nullius Vulcanus is missing volcanism autoplace control")
  generate(surface, {0, 0}, 2)

  local bad_tiles = {}
  for _, tile in pairs(surface.find_tiles_filtered{
      area = {{-96, -96}, {96, 96}}}) do
    if not vulcanus_tiles[tile.name] then bad_tiles[tile.name] = true end
  end
  check(next(bad_tiles) == nil, "Nullius Vulcanus generated non-whitelist tiles")

  local bad_entities = {}
  for _, type_name in pairs(generated_entity_types) do
    for _, entity in pairs(surface.find_entities_filtered{type = type_name}) do
      if not vulcanus_entities[entity.name] then
        bad_entities[entity.name] = true
      end
    end
  end
  check(next(bad_entities) == nil,
    "Nullius Vulcanus generated non-whitelist entities")
  check(surface.count_entities_filtered{
      type = {"unit", "unit-spawner"}, force = "enemy"} == 0,
    "Nullius Vulcanus generated enemies")
  observations.vulcanus_bad_tiles = bad_tiles
  observations.vulcanus_bad_entities = bad_entities
end

local function check_hidden_planets()
  observations.hidden = {}
  for _, name in pairs(hidden_planets) do
    local planet = game.planets[name]
    check(planet ~= nil, "missing hidden planet " .. name)
    if planet then
      check(planet.prototype.hidden == true, name .. " planet is visible")
      local surface = planet.surface or planet.create_surface()
      check(surface ~= nil, "failed to create hidden planet surface " .. name)
      if surface then
        check_controlled_settings(surface, name)
        generate(surface, {0, 0}, 1)
        local entity_count = surface.count_entities_filtered{
          type = generated_entity_types,
        }
        local decorative_count = #surface.find_decoratives_filtered{
          area = {{-64, -64}, {64, 64}},
        }
        local nonempty_tiles = 0
        local tile_counts = {}
        for _, tile in pairs(surface.find_tiles_filtered{
            area = {{-64, -64}, {64, 64}}}) do
          tile_counts[tile.name] = (tile_counts[tile.name] or 0) + 1
          if tile.name ~= "empty-space" then nonempty_tiles = nonempty_tiles + 1 end
        end
        check(entity_count == 0, name .. " generated autoplace entities")
        check(decorative_count == 0, name .. " generated decoratives")
        check(nonempty_tiles == 0, name .. " generated playable terrain")
        observations.hidden[name] = {
          entities = entity_count,
          decoratives = decorative_count,
          nonempty_tiles = nonempty_tiles,
          tiles = tile_counts,
        }
      end
    end
  end
end

local function run()
  script.on_nth_tick(1, nil)
  check_nauvis()
  check_vulcanus()
  check_hidden_planets()
  finish()
end

script.on_nth_tick(1, run)

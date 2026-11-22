-- given: a new force with Gleba locked.
-- place: the research handler places the wreck and its android.
-- connect: Nauvis and Gleba share a space route.
-- act: recover the probe, generate terrain, and repeat activation.
-- run: two ticks.
-- expect: an empty wreck on native terrain with no vegetation, enemies or spores.
local research = require("__nullius-star__/scripts/research")
local assertions = 0
local function check(value, message)
  assertions = assertions + 1
  assert(value, message)
end

local function survey_minerals(surface, area)
  local mud = {
    ["light-mud-decal"] = true, ["dark-mud-decal"] = true,
    ["cracked-mud-decal"] = true, ["grey-cracked-mud-decal"] = true,
  }
  local water = {}
  for name in pairs(surface.map_gen_settings.autoplace_settings.tile.settings) do
    if prototypes.tile[name].fluid then water[#water + 1] = name end
  end
  local outcrop_chunks = {}
  local counts = {slab = 0, mound = 0, relief = 0, shelf = 0, lowland = 0, midland = 0, mud = 0, calcite = 0, near_water = 0, medium = 0,
    highland = 0, cliff = 0, small = 0, near_medium = 0, shore = 0, marked_shore = 0}
  for _, decoration in pairs(surface.find_decoratives_filtered{area = area}) do
    local name = decoration.decorative.name
    local pos = decoration.position
    local tile = surface.get_tile(pos)
    if mud[name] then
      counts.mud = counts.mud + 1
    elseif name == "nullius-gleba-calcite-stain-small" then
      assert(not tile.prototype.fluid, "calcite in water on " .. tile.name)
      counts.calcite = counts.calcite + 1
      if surface.count_tiles_filtered{position = pos, radius = 8, name = water, limit = 1} > 0 then
        counts.near_water = counts.near_water + 1
      end
    elseif name == "nullius-gleba-weathered-slab" or name == "nullius-gleba-mineral-mound" then
      outcrop_chunks[math.floor(pos.x / 32) .. "," .. math.floor(pos.y / 32)] = true
      if name == "nullius-gleba-weathered-slab" then
        assert(not tile.prototype.fluid, "slab in water")
        counts.slab = counts.slab + 1
        if tile.name:match("^midland") then counts.midland = counts.midland + 1 end
        if tile.name:match("^lowland") then counts.lowland = counts.lowland + 1 end
      else
        assert(tile.name:match("^lowland") or tile.name:match("^wetland"), "mound outside wetland margins")
        counts.mound = counts.mound + 1
        if tile.prototype.fluid then counts.shelf = counts.shelf + 1 end
      end
    elseif name == "nullius-gleba-pumice-relief-decal" then
      assert(not tile.prototype.fluid, "bedrock in water")
      counts.relief = counts.relief + 1
    elseif name == "nullius-gleba-medium-rock" then
      assert(not tile.prototype.fluid, "medium rock in water")
      counts.medium = counts.medium + 1
      if tile.name:match("^highland") then counts.highland = counts.highland + 1 end
      if surface.count_entities_filtered{name = "cliff-gleba", position = pos, radius = 8, limit = 1} > 0 then
        counts.cliff = counts.cliff + 1
      end
    elseif name == "nullius-gleba-small-rock" then
      assert(not tile.prototype.fluid, "small rock in water")
      counts.small = counts.small + 1
      if #surface.find_decoratives_filtered{name = "nullius-gleba-medium-rock",
          area = {{pos.x - 6, pos.y - 6}, {pos.x + 6, pos.y + 6}}} > 0 then
        counts.near_medium = counts.near_medium + 1
      end
    else
      error("unexpected Gleba decorative " .. name)
    end
  end
  for x = area[1][1], area[2][1] - 1, 8 do
    for y = area[1][2], area[2][2] - 1, 8 do
      if not surface.get_tile(x, y).prototype.fluid and
          surface.count_tiles_filtered{position = {x, y}, radius = 3, name = water, limit = 1} > 0 then
        counts.shore = counts.shore + 1
        if #surface.find_decoratives_filtered{name = "nullius-gleba-calcite-stain-small",
            area = {{x - 4, y - 4}, {x + 4, y + 4}}} > 0 then
          counts.marked_shore = counts.marked_shore + 1
        end
      end
    end
  end
  counts.outcrop_chunks = table_size(outcrop_chunks)
  local chunks = (area[2][1] - area[1][1]) * (area[2][2] - area[1][2]) / 1024
  local report = helpers.table_to_json(counts)
  check(counts.outcrop_chunks > chunks * 0.6, "outcrops too scarce at walking zoom " .. report)
  check(counts.lowland > 0 and counts.midland > 0 and counts.shelf > 0 and counts.relief > 0,
    "missing lowland, midland or shelf scenery " .. report)
  log("Gleba mineral survey " .. report)
  check(counts.mud > 0 and counts.calcite > 0, "missing mud or calcite " .. report)
  check(counts.near_water > 0.75 * counts.calcite, "calcite too far inland " .. report)
  check(counts.marked_shore > 0 and counts.marked_shore < counts.shore / 2, "unbroken or empty shoreline " .. report)
  check(counts.medium > 0 and counts.highland > 0 and counts.cliff > 0, "missing rocky terrain " .. report)
  check(counts.small > counts.medium and counts.near_medium > 0.5 * counts.small,
    "small rocks do not cluster around medium rocks " .. report)
  return counts
end

local function survey(surface)
  local area = {{-256, -256}, {256, 256}}
  surface.request_to_generate_chunks({0, 0}, 8)
  surface.force_generate_chunk_requests()
  local map = surface.map_gen_settings
  check(map.no_enemies_mode and not map.default_enable_all_autoplace_controls, "natural enemies enabled")
  check(not surface.pollutant_type and surface.get_total_pollution() == 0, "Gleba has a pollutant")
  for _, field in ipairs({"elevation", "moisture", "aux", "temperature", "cliffiness"}) do
    check(map.property_expression_names[field] == "gleba_" .. field, "unexpected terrain field " .. field)
  end
  local cliffs = map.cliff_settings
  check(cliffs.name == "cliff-gleba" and cliffs.cliff_elevation_0 == 40
    and cliffs.cliff_elevation_interval == 60, "Gleba cliff settings changed")
  check(surface.count_entities_filtered{area = area, name = "cliff-gleba"} > 0, "missing cliffs")
  for _, entity in pairs(surface.find_entities_filtered{area = area}) do
    assert(entity.type == "cliff" or entity.name == "character" or entity.name == "nullius-landing-main",
      "unexpected entity on Gleba: " .. entity.name)
  end
  local minerals = survey_minerals(surface, area)
  local built_on_slab = false
  for _, slab in pairs(surface.find_decoratives_filtered{area = area, name = "nullius-gleba-weathered-slab"}) do
    local pos = slab.position
    if surface.can_place_entity{name = "character", position = pos} and
        surface.can_place_entity{name = "iron-chest", position = pos} then
      local chest = surface.create_entity{name = "iron-chest", position = pos, force = "player"}
      assert(chest)
      chest.destroy()
      built_on_slab = true
      break
    end
  end
  check(built_on_slab, "no walkable weathered slab accepts a building")

  local tiles = map.autoplace_settings.tile.settings
  check(table_size(tiles) == 41, "expected the 41 native Gleba tiles")
  local tile_count = 0
  local biomes = {}
  for name in pairs(tiles) do
    local count = surface.count_tiles_filtered{area = area, name = name}
    if count > 0 then biomes[name:match("^[^-]+")] = true end
    tile_count = tile_count + count
  end
  check(tile_count == 512 * 512, "foreign terrain inside the survey area")
  check(biomes.wetland and biomes.lowland and biomes.midland and biomes.highland, "missing native biomes")
  local nauvis = game.surfaces.nauvis
  nauvis.request_to_generate_chunks({0, 0}, 2)
  nauvis.force_generate_chunk_requests()
  local gleba_tiles = {}
  for name in pairs(tiles) do table.insert(gleba_tiles, name) end
  check(nauvis.count_tiles_filtered{area = {{-64, -64}, {64, 64}}, name = gleba_tiles} == 0,
    "Nauvis generated Gleba terrain")
  return minerals
end

script.on_nth_tick(1, function(event)
  if event.tick == 0 then return end
  local force = game.forces.player
  local planet = game.planets["nullius-gleba"]
  local tech = force.technologies["nullius-probe-gleba"]
  if event.tick == 1 then
    check(not planet.surface and not force.is_space_location_unlocked(planet.name), "Gleba already active")
    check(table_size(tech.prerequisites) == 2 and tech.prerequisites["nullius-organic-chemistry-1"]
      and tech.prerequisites["nullius-interplanetary-signal-acquisition"], "unexpected research gate")
    check(tech.research_unit_count == 40 and tech.research_unit_energy == 20 * 60, "unexpected research cost")
    local packs = {}
    for _, ingredient in pairs(tech.research_unit_ingredients) do packs[ingredient.name] = ingredient.amount end
    check(table_size(packs) == 4, "unexpected science packs")
    for _, name in ipairs({"geology", "climatology", "mechanical", "electrical"}) do
      check(packs["nullius-" .. name .. "-pack"] == 1, "missing " .. name .. " pack")
    end
    research.complete_with_prerequisites(tech)
  else
    check(force.is_space_location_unlocked(planet.name) and planet.surface, "probe did not unlock Gleba")
    local route = prototypes.space_connection["nauvis-nullius-gleba"]
    check(route.from.name == "nauvis" and route.to.name == planet.name, "missing Nauvis route")
    remote.call("nullius-test-bodies", "activate", force, "gleba")
    local wrecks = planet.surface.find_entities_filtered{type = "container", force = force}
    check(#wrecks == 1 and wrecks[1].name == "nullius-landing-main", "expected one probe wreck")
    check(wrecks[1].get_inventory(defines.inventory.chest).is_empty(), "probe contains supplies")
    check(planet.surface.count_entities_filtered{name = "character", force = force} == 1, "expected one android")
    local tracks = prototypes.mod_data["factorio-test-gleba-music"].data
    for _, suffix in ipairs({"1-hero", "1", "2", "3", "4", "5", "6", "8", "9", "10", "11",
        "interlude-1", "interlude-4"}) do
      check(tracks["gleba-" .. suffix], "missing Gleba music track " .. suffix)
    end
    local minerals = {landing = survey(planet.surface)}
    for _, seed in ipairs({17, 42, 103}) do
      local settings = planet.surface.map_gen_settings
      settings.seed = seed
      local sample = game.create_surface("gleba-minerals-" .. seed, settings)
      sample.request_to_generate_chunks({0, 0}, 9)
      sample.force_generate_chunk_requests()
      minerals[tostring(seed)] = survey_minerals(sample, {{-256, -256}, {256, 256}})
    end
    local other = game.create_force("gleba-independent")
    remote.call("nullius-test-bodies", "activate", other, "gleba")
    local separate = planet.surface.find_entities_filtered{type = "container", force = other}
    check(#separate == 1 and separate[1].name == "nullius-landing-main"
      and separate[1].get_inventory(defines.inventory.chest).is_empty(), "second force has no empty wreck")
    wrecks[1].destroy()
    remote.call("nullius-test-bodies", "activate", force, "gleba")
    check(planet.surface.count_entities_filtered{type = "container", force = force} == 0,
      "activation recreated a destroyed wreck")
    helpers.write_file("factorio-tests/gleba-activation.json", helpers.table_to_json{
      schema = 1, case = "gleba-activation", status = "pass", failure_count = 0,
      assertions = assertions, minerals = minerals, tick = event.tick, factorio_version = script.active_mods.base,
    }, false)
    script.on_nth_tick(1, nil)
  end
end)

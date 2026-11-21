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
  local mud = {
    ["light-mud-decal"] = true, ["dark-mud-decal"] = true,
    ["cracked-mud-decal"] = true, ["grey-cracked-mud-decal"] = true,
  }
  local decorations = surface.find_decoratives_filtered{area = area}
  check(#decorations > 0, "missing native mud markings")
  for _, decoration in pairs(decorations) do
    assert(mud[decoration.decorative.name], "unexpected decorative on Gleba: " .. decoration.decorative.name)
  end

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
    survey(planet.surface)
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
      assertions = assertions, tick = event.tick, factorio_version = script.active_mods.base,
    }, false)
    script.on_nth_tick(1, nil)
  end
end)

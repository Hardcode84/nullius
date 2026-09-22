-- Probe reactivation system for Nullius*.
-- When a probe tech is researched, create the planet surface,
-- spawn a dormant android and probe wreckage, then offer body switch.

local probe = {}

local destinations = {
  ["nullius-probe-vulcanus"] = "nullius-vulcanus",
  ["nullius-probe-fulgora"] = "nullius-fulgora",
}

local function fulgora_landing_site(surface, pos, force)
  local position = surface.find_non_colliding_position("nullius-landing-main", pos, 64, 1)
  if not position then error("Fulgora probe has no safe landing position") end
  local wreck = surface.create_entity{name = "nullius-landing-main", position = position, force = force}
  if not wreck then error("Fulgora probe could not create its wreck") end
end

-- Vulcanus probe landing site: spawn broken equipment.
local function vulcanus_landing_site(surface, pos, force)
  -- Clear area around landing position.
  for _, entity in pairs(surface.find_entities_filtered{
      area = {{pos.x - 16, pos.y - 16}, {pos.x + 16, pos.y + 16}},
      force = "neutral", collision_mask = "player"}) do
    if entity.valid then
      entity.destroy()
    end
  end

  -- Spawn probe wreck (container with starting supplies).
  local wreck_pos = surface.find_non_colliding_position(
      "nullius-landing-main", pos, 32, 2)
  if wreck_pos == nil then wreck_pos = pos end

  local wreck = surface.create_entity{
    name = "nullius-landing-main",
    position = wreck_pos,
    force = force,
  }
  if not wreck or not wreck.valid then
    error("Vulcanus probe could not create its supply wreck")
  end
  if wreck and wreck.valid then
    -- Vulcanus probe supplies.
    -- Bootstrap sequence: no electricity. One free/void lava intake provides
    -- lava; another intake toggled to free-gas mode (Ctrl+R) vents compressed
    -- gas for free (diminishing returns), powering the first pneumatic hydro
    -- plant. Once lava processing runs, its net-positive gas surplus sustains
    -- the factory.

    -- Phase A: Pneumatic bootstrap (no Stirling, no electrical grid).
    -- Two intakes: one free lava, one toggled to free-gas.
    wreck.insert({name = "nullius-seawater-intake-1", count = 2})

    -- Phase B: First gas loop (hydro-plant processes lava + piping).
    wreck.insert({name = "nullius-hydro-plant-1", count = 4})
    wreck.insert({name = "nullius-small-furnace-1", count = 4})
    wreck.insert({name = "pipe", count = 50})
    wreck.insert({name = "nullius-heat-pipe-1", count = 50})
    wreck.insert({name = "pipe-to-ground", count = 10})

    -- Phase C: Basic manufacturing.
    wreck.insert({name = "nullius-extractor-1", count = 2})
    wreck.insert({name = "nullius-air-filter-1", count = 2})
    wreck.insert({name = "nullius-distillery-1", count = 2})
    wreck.insert({name = "nullius-chemical-plant-1", count = 2})
    wreck.insert({name = "nullius-foundry-1", count = 4})
    wreck.insert({name = "nullius-small-assembler-1", count = 4})
    wreck.insert({name = "inserter", count = 12})
    wreck.insert({name = "iron-chest", count = 4})

    -- Phase D: Electronics rebuild requires silicon insulation.
    -- No electronics in wreck (melted). Player must craft from scratch.

    -- Phase E: Science.
    wreck.insert({name = "nullius-lab-1", count = 1})

    -- Misc: belts/splitters for cooling conveyors and explosives for cliffs.
    wreck.insert({name = "transport-belt", count = 50})
    wreck.insert({name = "splitter", count = 4})
    wreck.insert({name = "cliff-explosives", count = 30})
  end
end

-- Create a dormant android on the target surface.
local function spawn_android(surface, pos, force)
  local spawn_pos = surface.find_non_colliding_position(
      "character", pos, 32, 1)
  if not spawn_pos then error("Probe android has no safe landing position on " .. surface.name) end

  local android = surface.create_entity{
    name = "character",
    position = spawn_pos,
    force = force,
  }

  -- Equip android with starting armor and equipment (same as Nauvis android).
  if android and android.valid then
    local armor_inv = android.get_inventory(defines.inventory.character_armor)
    if armor_inv then
      armor_inv.insert({name = "nullius-chassis-1", count = 1})
      local body = armor_inv.find_item_stack("nullius-chassis-1")
      if body and body.grid then
        if script.active_mods["Companion_Drones"] then
          body.grid.put({name = "nullius-solar-panel-1"})
          body.grid.put({name = "nullius-battery-1"})
          body.grid.put({name = "nullius-battery-1"})
          body.grid.put({name = "nullius-battery-1"})
        else
          body.grid.put({name = "nullius-charger-1"})
          body.grid.put({name = "nullius-hangar-1"})
          body.grid.put({name = "nullius-solar-panel-1"})
          body.grid.put({name = "nullius-battery-1", position = {2, 4}})
          body.grid.put({name = "nullius-battery-1", position = {3, 4}})
          body.grid.put({name = "nullius-solar-panel-1"})
          body.grid.put({name = "nullius-battery-1"})
          body.grid.put({name = "nullius-battery-1"})
        end
        for _, eq in pairs(body.grid.equipment) do
          if eq.max_energy > eq.energy then
            eq.energy = eq.max_energy
          end
        end
      end
    end
    -- Starting inventory items.
    local main_inv = android.get_inventory(defines.inventory.character_main)
    if main_inv then
      if not script.active_mods["Companion_Drones"] then
        main_inv.insert({name = "nullius-construction-bot-1", count = 6})
      end
    end
  end

  return android
end

-- Landing stock belongs to a force. The body is shared by that force.
function probe.get_landing(force, planet_name)
  local landings = storage.nullius_probe_landings
  local planets = landings and landings[force.index]
  return planets and planets[planet_name or "nullius-vulcanus"]
end

function probe.attach_player(player)
  for _, planet_name in ipairs({"nullius-vulcanus", "nullius-fulgora"}) do
    local landing = probe.get_landing(player.force, planet_name)
    local android = landing and landing.android
    if android and android.valid then
      add_body_to_queue(player, android)
      if not android.player then
        android.associated_player = nil
        add_chart_tag(player, android)
      end
    end
  end
end

function probe.is_body(unit)
  for _, planets in pairs(storage.nullius_probe_landings or {}) do
    for _, landing in pairs(planets) do
      if landing.unit == unit then return true end
    end
  end
  return false
end

function probe.replace_body(oldunit, newchar)
  for _, planets in pairs(storage.nullius_probe_landings or {}) do
    for _, landing in pairs(planets) do
      if landing.unit == oldunit then
        landing.android = newchar
        landing.unit = newchar.unit_number
      end
    end
  end
end

-- Cold configuration-change path: published releases stored one Vulcanus
-- record per force. Retain empty records so destroyed probes cannot respawn.
function probe.migrate_landings()
  for force, landings in pairs(storage.nullius_probe_landings or {}) do
    if landings.android or landings.unit or next(landings) == nil then
      storage.nullius_probe_landings[force] = {["nullius-vulcanus"] = landings}
    end
  end
end

-- Research activation is idempotent, including after loss of the body or wreck.
function probe.on_probe_researched(tech_name, force)
  local planet_name = destinations[tech_name]
  if not planet_name then return end
  if not probe.get_landing(force, planet_name) then
    local planet = game.planets[planet_name]
    if not planet.surface then planet.create_surface() end
    local surface = planet.surface
    local pos = {x = 0, y = 0}
    surface.request_to_generate_chunks(pos, 2)
    surface.force_generate_chunk_requests()
    if planet_name == "nullius-vulcanus" then
      vulcanus_landing_site(surface, pos, force)
    else
      fulgora_landing_site(surface, pos, force)
    end
    local android = spawn_android(surface, {x = 5, y = 5}, force)
    if not android or not android.valid then
      error(planet_name .. " probe could not create its android")
    end
    storage.nullius_probe_landings = storage.nullius_probe_landings or {}
    storage.nullius_probe_landings[force.index] = storage.nullius_probe_landings[force.index] or {}
    storage.nullius_probe_landings[force.index][planet_name] = {
      android = android, unit = android.unit_number,
    }
    force.chart(surface, {{-64, -64}, {64, 64}})
    force.print({"nullius-probe.activated", {"space-location-name." .. planet_name}})
  end
  force.unlock_space_location(planet_name)
  for _, player in pairs(force.players) do probe.attach_player(player) end
end

return probe

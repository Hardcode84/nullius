-- given: a new force, the production research tree, and no Fulgora surface.
-- place: research creates the production probe wreck and equipped android.
-- connect: independent landing records for two planets and two forces.
-- act: complete each probe research, then repeat activation.
-- run: three ticks.
-- expect: one idle body and wreck per force and planet; no Fulgora supplies.
local research = require("__nullius-star__/scripts/research")
local count = 0
local function check(value, message)
  count = count + 1
  assert(value, message)
end
local function landing(force, name)
  local surface = game.planets["nullius-" .. name].surface
  check(surface ~= nil, name .. " has no surface")
  check(force.is_space_location_unlocked("nullius-" .. name), name .. " is locked")
  local bodies = surface.find_entities_filtered{name = "character", force = force}
  local wrecks = surface.find_entities_filtered{name = "nullius-landing-main", force = force}
  check(#bodies == 1, name .. " must have one body per force")
  check(#wrecks == 1, name .. " must have one wreck per force")
  check(not bodies[1].player and not bodies[1].associated_player, "research occupied the body")
  local armor = bodies[1].get_inventory(defines.inventory.character_armor).find_item_stack("nullius-chassis-1")
  check(armor and armor.grid and #armor.grid.equipment > 0, "probe android has no equipment")
  check(surface.can_place_entity{name = "character", position = bodies[1].position,
    force = force, build_check_type = defines.build_check_type.manual_ghost}, "probe landing is not walkable")
  if name == "fulgora" then
    check(wrecks[1].get_inventory(defines.inventory.chest).is_empty(), "Fulgora has undeclared supplies")
  else
    check(wrecks[1].get_item_count("nullius-seawater-intake-1") == 2, "Vulcanus supplies changed")
  end
  return bodies[1]
end
script.on_nth_tick(1, function()
  local force = game.forces.player
  if game.tick == 1 then
    check(game.planets["nullius-fulgora"].surface == nil, "Fulgora was created before research")
    check(commands.commands["nullius-fulgora"] ~= nil, "missing Fulgora command")
    local tech = force.technologies["nullius-probe-fulgora"]
    check(tech.prerequisites["nullius-interplanetary-signal-acquisition"] ~= nil, "missing signal prerequisite")
    check(tech.prerequisites["nullius-insulation-1"] ~= nil, "missing insulation prerequisite")
    research.complete_with_prerequisites(tech)
  elseif game.tick == 2 then
    storage.fulgora_body = landing(force, "fulgora")
    check(not force.technologies["nullius-probe-vulcanus"].researched, "Fulgora requires Vulcanus")
    research.complete_with_prerequisites(force.technologies["nullius-probe-vulcanus"])
  elseif game.tick == 3 then
    local vulcanus = landing(force, "vulcanus")
    check(landing(force, "fulgora") == storage.fulgora_body, "Vulcanus replaced Fulgora")
    local other = game.create_force("probe-independent")
    for _, name in ipairs({"fulgora", "vulcanus"}) do
      for _ = 1, 2 do
        remote.call("nullius-test-bodies", "activate", force, name)
        remote.call("nullius-test-bodies", "activate", other, name)
      end
      local original = landing(force, name)
      local separate = landing(other, name)
      check(original ~= separate, "forces share a probe")
      check(original == (name == "fulgora" and storage.fulgora_body or vulcanus), "activation replaced body")
    end
    helpers.write_file("factorio-tests/fulgora-activation.json", helpers.table_to_json{
      schema = 1, case = "fulgora-activation", status = "pass", failure_count = 0,
      assertions = count, tick = game.tick, factorio_version = script.active_mods.base,
    }, false)
    script.on_nth_tick(1, nil)
  end
end)

-- given: a new force, the production research tree, and no Fulgora surface.
-- place: research creates the production probe wreck and equipped android.
-- connect: independent landing records for two planets and two forces.
-- act: complete each probe research, then repeat activation.
-- run: three ticks.
-- expect: one idle body and wreck per force and planet; exact Fulgora starter supplies, including 30 cliff explosives.
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
    force = force, build_check_type = defines.build_check_type.manual_ghost}, "probe landing is not walkable: "..name.." force="..force.name.." position="..helpers.table_to_json(bodies[1].position))
  if name == "fulgora" then
    local expected={
      ['nullius-extractor-1']=3,['nullius-hydro-plant-1']=4,['nullius-distillery-1']=3,
      ['nullius-air-filter-1']=4,['nullius-chemical-plant-1']=2,['nullius-electrolyzer-1']=2,
      ['nullius-crusher-1']=2,['nullius-small-furnace-1']=1,['nullius-medium-furnace-1']=1,
      ['nullius-foundry-1']=1,['nullius-small-assembler-1']=2,['nullius-flotation-cell-1']=1,
      ['nullius-combustion-chamber-1']=1,['nullius-chimney-1']=3,['nullius-lab-1']=1,
      ['small-electric-pole']=32,pipe=200,['pipe-to-ground']=40,['nullius-small-tank-1']=8,
      ['nullius-one-way-valve']=8,['transport-belt']=100,inserter=24,['wooden-chest']=10,
      ['cliff-explosives']=30,
      splitter=8,['underground-belt']=20,['nullius-grid-battery-1']=4,
    }
    local chests=surface.find_entities_filtered{name='wooden-chest',force=force}
    check(#chests==2,'two salvage chests per force')
    local containers={wrecks[1],chests[1],chests[2]}
    local expected_total=0
    for item,n in pairs(expected) do
      local actual=0
      for _,container in ipairs(containers) do actual=actual+container.get_item_count(item) end
      check(actual==n,'starter amount '..item..': '..actual)
      expected_total=expected_total+n
    end
    local actual_total=0
    for _,container in ipairs(containers) do
      actual_total=actual_total+container.get_inventory(defines.inventory.chest).get_item_count()
      check(surface.get_tile(container.position).name:find('nullius-fulgora-sediment',1,true)~=1,
        'starter container on restricted sand')
    end
    check(actual_total==expected_total,'undeclared starter items')
    check(wrecks[1].get_item_count('cliff-explosives')==30,'explosives must be in wreck')
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
    local wreck=game.planets['nullius-fulgora'].surface.find_entities_filtered{
      name='nullius-landing-main',force=force}[1]
    check(wreck.remove_item{name='cliff-explosives',count=30}==30,'take starter explosives')
    remote.call('nullius-test-bodies','activate',force,'fulgora')
    check(wreck.get_item_count('cliff-explosives')==0,'activation refilled looted wreck')
    helpers.write_file("factorio-tests/fulgora-activation.json", helpers.table_to_json{
      schema = 1, case = "fulgora-activation", status = "pass", failure_count = 0,
      assertions = count, tick = game.tick, factorio_version = script.active_mods.base,
    }, false)
    script.on_nth_tick(1, nil)
  end
end)

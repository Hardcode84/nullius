-- given: one launcher and eight scout drones as finite action-test stock.
-- given: checkpoint prerequisites researched; no production statistics injected.
-- place: launcher on a Fulgora island, eight targets beyond its minimum range.
-- act: fire the drones.
-- expect: consumption statistics complete the exploration checkpoint.
script.on_nth_tick(1, function()
  if game.tick == 0 then return end
  script.on_nth_tick(1, nil)
  local force = game.create_force('fulgora-exploration')
  local function research(tech)
    if tech.researched then return end
    for _, prerequisite in pairs(tech.prerequisites) do research(prerequisite) end
    tech.researched = true
  end
  local checkpoint = force.technologies['nullius-checkpoint-exploration']
  for _, prerequisite in pairs(checkpoint.prerequisites) do research(prerequisite) end
  local planet = game.planets['nullius-fulgora']
  local surface = planet.surface or planet.create_surface()
  surface.request_to_generate_chunks({0, 0}, 1)
  surface.request_to_generate_chunks({128, 0}, 1)
  surface.force_generate_chunk_requests()
  for _, entity in pairs(surface.find_entities_filtered{area={{-8,-8},{8,8}}}) do entity.destroy() end
  local tiles = {}
  for x=-8,8 do for y=-8,8 do
    tiles[#tiles+1] = {name='fulgoran-rock', position={x,y}}
  end end
  surface.set_tiles(tiles)
  assert(surface.can_place_entity{name='nullius-drone-launcher-1', position={0,0}, force=force})
  local launcher = assert(surface.create_entity{name='nullius-drone-launcher-1', position={0,0}, force=force})
  assert(launcher.insert{name='nullius-scout-drone-1', count=8} == 8)
  for i=1,8 do
    assert(surface.create_entity{name='nullius-scout-flare', position={128,i*4}, force=force,
      movement={0,0}, height=0, vertical_speed=0, frame_speed=1})
  end
  storage.launcher = launcher
end)
script.on_nth_tick(2000, function()
  if game.tick == 0 then return end
  local launcher = storage.launcher
  assert(launcher.get_item_count('nullius-scout-drone-1') == 0, 'Eight drones must fire')
  assert(launcher.force.get_item_production_statistics(launcher.surface).get_output_count('nullius-scout-drone-1') == 8)
  assert(remote.call('nullius-test-checkpoints', 'progress', launcher.force.name, 'exploration') == 1)
  assert(launcher.force.technologies['nullius-checkpoint-exploration'].researched, 'Checkpoint must complete')
  helpers.write_file('factorio-tests/fulgora-exploration-checkpoint.json', helpers.table_to_json{
    schema=1, case='fulgora-exploration-checkpoint', status='pass', failure_count=0,
    assertions=4, tick=game.tick, factorio_version=script.active_mods.base,
  }, false)
  script.on_nth_tick(2000, nil)
end)

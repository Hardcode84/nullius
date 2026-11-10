-- given: the active mod's checkpoint definitions; no production or stock.
-- act: export the runtime requirements for progression analysis.
-- expect: the runtime interface supplies checkpoint requirements.
script.on_nth_tick(1, function()
  if game.tick == 0 then return end
  local definitions = remote.call('nullius-test-checkpoints', 'definitions')
  assert(next(definitions), 'Missing checkpoint definitions')
  local research,enabled_recipes={},{}
  for name,technology in pairs(game.forces.player.technologies) do
    research[name]={enabled=technology.enabled,researched=technology.researched,
      level=technology.level,count=technology.research_unit_count}
  end
  for name,recipe in pairs(game.forces.player.recipes) do
    if recipe.enabled then enabled_recipes[#enabled_recipes+1]=name end
  end
  helpers.write_file('factorio-tests/checkpoint-contracts.json', helpers.table_to_json{
    schema=1, case='checkpoint-contracts', status='pass', failure_count=0,
    assertions=1, tick=game.tick, definitions=definitions, research=research, enabled_recipes=enabled_recipes,
    factorio_version=script.active_mods.base,
  }, false)
  script.on_nth_tick(1, nil)
end)

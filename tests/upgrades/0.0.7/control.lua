-- given: released Volcanic Alkali Processing research, a hydro plant set to volcanic
-- causticization and a chemical plant set to volcanic saline; a second force without
-- that research.
-- act: save, then load and reload with the candidate mod; reset technology effects.
-- expect: the research and recipes carry over under their common names, both machines
-- keep their recipes, and the unresearched force gains nothing.
script.on_init(function() remote.call("release-upgrade", "seed") end)
script.on_nth_tick(1, function()
  remote.call("release-upgrade", "verify")
  if game.tick == 1 then game.auto_save("release-upgraded") end
end)

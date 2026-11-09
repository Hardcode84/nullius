-- given: released Astronomy and Nuclear Power 1 research, before radio recipes
-- and the reactor split existed; a second force without nuclear research.
-- act: save, then load and reload with the candidate mod; reset technology effects.
-- expect: new Astronomy recipes are enabled; planet research stays separate;
-- reactors stay unlocked only where Nuclear Power 1 was researched.
script.on_init(function() remote.call("release-upgrade", "seed") end)
script.on_nth_tick(1,function()
  remote.call("release-upgrade", "verify")
  if game.tick==1 then game.auto_save("release-upgraded") end
end)

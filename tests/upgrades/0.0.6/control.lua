-- given: released Astronomy research, before radio recipes existed.
-- act: save, then load and reload with the candidate mod.
-- expect: new Astronomy recipes are enabled; planet research stays separate.
script.on_init(function() remote.call("release-upgrade", "seed") end)
script.on_nth_tick(1,function()
  remote.call("release-upgrade", "verify")
  if game.tick==1 then game.auto_save("release-upgraded") end
end)

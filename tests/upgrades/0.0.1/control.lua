-- given: the tagged 0.0.1 mod and one force with probe research.
-- place: the production probe creates its android and supply wreck.
-- connect: one map marker refers to that android.
-- act: save with 0.0.1, then load with the candidate mod.
-- run: the runner advances two ticks after configuration change.
-- expect: retain the body, inventory, marker, research, and one supply wreck.
script.on_init(function() remote.call("release-upgrade", "seed") end)
script.on_nth_tick(1, function()
  remote.call("release-upgrade", "verify")
  script.on_nth_tick(1, nil)
end)

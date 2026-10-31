storage.nullius_legacy_tanks = {}
for _, force in pairs(game.forces) do
  storage.nullius_legacy_tanks[force.index] = force.technologies["nullius-plumbing-6"].researched
end

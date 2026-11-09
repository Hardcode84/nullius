-- The reactor recipes moved from Nuclear Power 1 to Nuclear Reactor, its new
-- prerequisite. Forces that researched Nuclear Power 1 keep their reactors.
for _, force in pairs(game.forces) do
  local technologies = force.technologies
  if technologies["nullius-nuclear-power-1"].researched then
    technologies["nullius-nuclear-reactor"].researched = true
  end
end

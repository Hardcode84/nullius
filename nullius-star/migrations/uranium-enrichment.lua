-- Uranium smelting and tritium enrichment left Uranium Processing; uranium now
-- comes from centrifuge enrichment. Forces that researched Uranium Processing
-- keep making uranium and enriched uranium.
for _, force in pairs(game.forces) do
  local technologies = force.technologies
  if technologies["nullius-uranium-processing"].researched then
    technologies["nullius-fluorine-chemistry"].researched = true
    technologies["nullius-uranium-enrichment"].researched = true
  end
end

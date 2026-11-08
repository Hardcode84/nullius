-- Return the research cost for a planet's launch materials.
return function(science_pack)
  return {count = 10, time = 45, ingredients = {
    {science_pack, 20}, {"nullius-electrical-pack", 4},
    {"nullius-chemical-pack", 4}, {"nullius-physics-pack", 2},
  }}
end

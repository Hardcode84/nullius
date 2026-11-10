local astronomy = {
  planets = {"fulgora", "nauvis", "vulcanus"},
  dishes = {"nullius-radio-dish", "nullius-radio-dish-pneumatic"},
  field_prefix = "nullius-dish-collision-",
}
function astronomy.is_dish(name)
  return name == astronomy.dishes[1] or name == astronomy.dishes[2]
end
function astronomy.recording(planet)
  return "nullius-" .. planet .. "-interferometric-recording"
end
function astronomy.sets()
  local sets = {}
  for mask = 1, 2 ^ #astronomy.planets - 1 do
    local set = {}
    for i, planet in ipairs(astronomy.planets) do
      if math.floor(mask / 2 ^ (i - 1)) % 2 == 1 then set[#set + 1] = planet end
    end
    sets[#sets + 1] = set
  end
  return sets
end
return astronomy

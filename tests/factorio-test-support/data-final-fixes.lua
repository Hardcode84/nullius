-- The runtime API exposes track names but omits their planet assignments.
local tracks = {}
for name, sound in pairs(data.raw["ambient-sound"]) do
  for _, planet in ipairs(sound.planets or {}) do
    if planet == "nullius-gleba" then tracks[name] = true end
  end
end
data:extend({{type = "mod-data", name = "factorio-test-gleba-music", data = tracks}})

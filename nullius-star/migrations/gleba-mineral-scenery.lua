local surface = game.planets["nullius-gleba"].surface
if not surface then return end

local minerals = {"nullius-gleba-calcite-stain-small", "nullius-gleba-medium-rock", "nullius-gleba-small-rock"}
local map = surface.map_gen_settings
for _, name in ipairs(minerals) do
  map.autoplace_settings.decorative.settings[name] = {}
end
surface.map_gen_settings = map
surface.regenerate_decorative(minerals)

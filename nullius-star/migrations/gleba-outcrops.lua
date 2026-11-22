local surface = game.planets["nullius-gleba"].surface
if not surface then return end

local minerals = {}
local map = surface.map_gen_settings
local native = surface.planet.prototype.map_gen_settings
for name in pairs(native.autoplace_settings.decorative.settings) do
  if name:match("^nullius%-gleba%-") then
    minerals[#minerals + 1] = name
    map.autoplace_settings.decorative.settings[name] = native.autoplace_settings.decorative.settings[name]
  end
end
surface.map_gen_settings = map
surface.destroy_decoratives{name = minerals}
surface.regenerate_decorative(minerals)

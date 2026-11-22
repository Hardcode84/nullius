-- Tints every sprite of a mode variant, except shadows, and its icons.
local function tint_graphics(value, tint)
  if type(value) ~= "table" or value.draw_as_shadow then return end
  if value.filename or value.filenames or value.stripes then
    value.tint = table.deepcopy(tint)
  end
  for _, child in pairs(value) do
    if type(child) == "table" then tint_graphics(child, tint) end
  end
end

return function(prototype, tint)
  tint_graphics(prototype.graphics_set, tint)
  for _, icon in ipairs(prototype.icons) do icon.tint = table.deepcopy(tint) end
end

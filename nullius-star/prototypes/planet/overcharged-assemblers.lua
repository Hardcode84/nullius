-- Cold data path: copy the resolved ordinary machines, including mod changes.
local tint = {r = 0.65, g = 0.8, b = 1}
local productivity = require("thermal-machine-config").productivity
local function tint_graphics(value)
  if type(value) ~= "table" or value.draw_as_shadow then return end
  if value.filename or value.filenames or value.stripes then
    value.tint = table.deepcopy(tint)
  end
  for _, child in pairs(value) do
    if type(child) == "table" then tint_graphics(child) end
  end
end

for _, spec in ipairs(require("shared.overcharged-assemblers")) do
  local base = assert(data.raw["assembling-machine"][spec.base])
  local variant = table.deepcopy(base)
  variant.name = spec.base .. "-overcharged"
  variant.localised_name = {"entity-name.nullius-overcharged-assembler",
    base.localised_name or {"entity-name." .. spec.base}}
  variant.localised_description = {"entity-description.nullius-overcharged-assembler",
    tostring(productivity[spec.tier] * 100), tostring(10 ^ spec.tier)}
  variant.placeable_by = {item = spec.base, count = 1}
  variant.hidden = true
  table.insert(variant.crafting_categories, "nullius-electromagnetism-1")
  if spec.tier >= 2 then
    table.insert(variant.crafting_categories, "nullius-electromagnetism-2")
  end
  if spec.tier == 3 then
    for _, category in ipairs(base.crafting_categories) do
      if category == "large-assembly" then
        table.insert(variant.crafting_categories, "nullius-electromagnetism-3")
        break
      end
    end
  end
  variant.next_upgrade = nil
  variant.energy_source.usage_priority = "tertiary"
  variant.energy_usage = tostring(util.parse_energy(base.energy_usage) * 60 * 10 ^ spec.tier) .. "W"
  variant.energy_source.drain = tostring(util.parse_energy(base.energy_source.drain) * 60 * 10 ^ spec.tier) .. "W"
  variant.effect_receiver = variant.effect_receiver or {}
  variant.effect_receiver.base_effect = variant.effect_receiver.base_effect or {}
  variant.effect_receiver.base_effect.productivity = productivity[spec.tier]
  tint_graphics(variant.graphics_set)
  for _, icon in ipairs(variant.icons) do icon.tint = table.deepcopy(tint) end
  data:extend({variant})
end

-- Preserve native terrain probabilities before the mod removes oil and ruins.
-- Cloned tiles are enabled only on the reference surface in the terrain test.
local settings = table.deepcopy(data.raw.planet.fulgora.map_gen_settings)
settings.autoplace_controls.scrap = nil
settings.autoplace_settings.entity = {treat_missing_as_default=false,settings={}}
settings.autoplace_settings.decorative = {treat_missing_as_default=false,settings={}}
local tiles = {}
for name in pairs(settings.autoplace_settings.tile.settings) do
  local tile = table.deepcopy(data.raw.tile[name])
  tile.name = 'factorio-test-'..name
  tile.hidden = true
  tiles[tile.name] = {}
  data:extend({tile})
end
settings.autoplace_settings.tile = {treat_missing_as_default=false,settings=tiles}
data:extend({{type='mod-data',name='factorio-test-fulgora-reference',data=settings}})

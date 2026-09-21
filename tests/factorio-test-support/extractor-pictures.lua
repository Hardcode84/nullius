for tier=1,2 do
  local drill = table.deepcopy(data.raw["mining-drill"]["nullius-extractor-" .. tier])
  drill.name = "factorio-test-extractor-" .. tier
  drill.minable = nil
  drill.next_upgrade = nil
  drill.fast_replaceable_group = nil
  drill.energy_source = {type="void"}
  data:extend({drill})
end
local resource = table.deepcopy(data.raw.resource["crude-oil"])
resource.name = "factorio-test-extractor-resource"
resource.autoplace = nil
resource.infinite = false
resource.minable = {mining_time=1,results={{type="fluid",name="water",amount=10}}}
data:extend({resource})
local vent = data.raw["mining-drill"]["nullius-gas-vent-drill"]
assert(vent.base_picture == nil and next(vent.graphics_set) == nil, "visible gas-vent drill graphics")

for _,prefix in ipairs({"nullius-well-", "nullius-legacy-well-"}) do
  for tier=1,2 do
    local well = table.deepcopy(data.raw["assembling-machine"][prefix .. tier])
    well.name = "factorio-test-" .. prefix .. tier
    well.minable = nil
    well.placeable_by = nil
    well.next_upgrade = nil
    well.fast_replaceable_group = nil
    well.energy_source = {type="void"}
    data:extend({well})
  end
end
local collector = table.deepcopy(data.raw.pipe.pipe)
collector.name = "factorio-test-well-collector"
collector.minable = nil
collector.next_upgrade = nil
collector.fast_replaceable_group = nil
collector.fluid_box.volume = 10000
data:extend({collector})

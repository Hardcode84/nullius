-- Declared external power; native mining speed, resource selection and output.
local drill = table.deepcopy(data.raw["mining-drill"]["electric-mining-drill"])
drill.name = "factorio-test-drone-miner"
drill.energy_source = {type="void"}
drill.energy_usage = "1W"
drill.next_upgrade = nil
drill.fast_replaceable_group = nil
data:extend({drill})

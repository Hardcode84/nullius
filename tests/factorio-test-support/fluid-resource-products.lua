-- A powered native drill with no external fluid input or output connection.
local drill = table.deepcopy(data.raw["mining-drill"]["pumpjack"])
drill.name = "factorio-test-fluid-resource-drill"
drill.minable = nil
drill.next_upgrade = nil
drill.fast_replaceable_group = nil
drill.energy_source = {type="void"}
drill.energy_usage = "1W"
drill.mining_speed = 1
drill.resource_searching_radius = 0.49
drill.resource_categories = {"basic-fluid"}
drill.module_slots = 0
drill.allowed_effects = {}
drill.output_fluid_box.filter = nil
drill.output_fluid_box.pipe_connections = {}
data:extend({drill})

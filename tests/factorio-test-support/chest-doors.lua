-- Native logistics, with one declared initial charge and four robots per grid.
local port = table.deepcopy(data.raw.roboport.roboport)
port.name = "factorio-test-chest-port"
port.minable = nil
port.next_upgrade = nil
port.fast_replaceable_group = nil
port.logistics_radius = 16
port.construction_radius = 16
port.logistics_connection_distance = 16
port.energy_source = {type="electric",usage_priority="secondary-input",buffer_capacity="50MJ",input_flow_limit="0W"}
port.energy_usage = "50kW"
data:extend({port})

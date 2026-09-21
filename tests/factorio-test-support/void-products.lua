-- One native recipe executor. The scenario supplies five batches of fluid.
local machine = table.deepcopy(data.raw["assembling-machine"]["assembling-machine-2"])
machine.name = "factorio-test-void-products"
machine.minable = nil
machine.next_upgrade = nil
machine.fast_replaceable_group = nil
machine.energy_source = {type="void"}
machine.energy_usage = "1W"
machine.crafting_speed = 1
machine.crafting_categories = {"nullius-liquid-void", "nullius-gas-void", "nullius-power-sink"}
machine.module_slots = 0
machine.allowed_effects = {}
machine.effect_receiver = {uses_module_effects=false, uses_beacon_effects=false, uses_surface_effects=false}
machine.fluid_boxes = {{production_type="input", volume=100000,
  pipe_connections={{flow_direction="input",direction=defines.direction.north,position={0,-1}}}}}
machine.fluid_boxes_off_when_no_fluid_recipe = false
data:extend({machine})
local buffer = table.deepcopy(data.raw.pipe.pipe)
buffer.name = "factorio-test-void-buffer"
buffer.minable = nil
buffer.next_upgrade = nil
buffer.fast_replaceable_group = nil
buffer.fluid_box.volume = 1000
data:extend({buffer})
local pump = table.deepcopy(data.raw.pump.pump)
pump.name = "factorio-test-void-pump"
pump.minable = nil
pump.next_upgrade = nil
pump.fast_replaceable_group = nil
pump.energy_source = {type="void"}
pump.energy_usage = "1W"
data:extend({pump})

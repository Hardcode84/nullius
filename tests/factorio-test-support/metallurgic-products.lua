local machine = table.deepcopy(data.raw["assembling-machine"]["assembling-machine-2"])
machine.name = "factorio-test-metallurgic-products"
machine.minable = nil
machine.next_upgrade = nil
machine.fast_replaceable_group = nil
machine.energy_source = {type="void"}
machine.energy_usage = "1W"
machine.crafting_speed = 10
machine.crafting_categories = {"medium-crafting"}
machine.module_slots = 0
machine.allowed_effects = {"productivity"}
machine.effect_receiver = {base_effect={productivity=1},
  uses_module_effects=false, uses_beacon_effects=false, uses_surface_effects=false}
machine.fluid_boxes = nil
data:extend({machine})

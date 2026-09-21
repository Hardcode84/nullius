-- Void power is the only external supply. All four boxes pass to the unboxer.
local machine=table.deepcopy(data.raw["assembling-machine"]["assembling-machine-2"])
machine.name="factorio-test-boxing"
machine.minable=nil
machine.next_upgrade=nil
machine.fast_replaceable_group=nil
machine.energy_source={type="void"}
machine.crafting_speed=1
machine.crafting_categories={"packaging"}
machine.module_slots=0
machine.allowed_effects={}
machine.effect_receiver={uses_module_effects=false,uses_beacon_effects=false,uses_surface_effects=false}
machine.fluid_boxes=nil
data:extend({machine})

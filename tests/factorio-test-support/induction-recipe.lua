for _,category in ipairs({"small-crafting","crafting"}) do
  local machine=table.deepcopy(data.raw["assembling-machine"]["assembling-machine-2"])
  machine.name="factorio-test-induction-"..category
  machine.minable=nil
  machine.next_upgrade=nil
  machine.fast_replaceable_group=nil
  machine.crafting_categories={category}
  machine.crafting_speed=1
  machine.energy_source={type="void"}
  machine.module_slots=0
  machine.allowed_effects={}
  machine.effect_receiver={uses_module_effects=false,uses_beacon_effects=false,uses_surface_effects=false}
  data:extend({machine})
end

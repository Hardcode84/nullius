-- Separate executors prove category acceptance and rejection.
for _,category in ipairs({"huge-crafting","tiny-crafting"}) do
  local machine=table.deepcopy(data.raw["assembling-machine"]["assembling-machine-2"])
  machine.name="factorio-test-terrain-"..category
  machine.minable=nil
  machine.next_upgrade=nil
  machine.fast_replaceable_group=nil
  machine.energy_source={type="void"}
  machine.crafting_speed=60
  machine.crafting_categories={category}
  machine.module_slots=0
  machine.allowed_effects={}
  machine.effect_receiver={uses_module_effects=false,uses_beacon_effects=false,uses_surface_effects=false}
  machine.fluid_boxes=nil
  data:extend({machine})
end

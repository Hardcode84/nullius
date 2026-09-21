data:extend({{type="recipe-category",name="factorio-test-primitive-rejected"}})
for _,category in ipairs({"tiny-crafting","medium-crafting","factorio-test-primitive-rejected"}) do
  local machine=table.deepcopy(data.raw["assembling-machine"]["assembling-machine-2"])
  machine.name=category=="factorio-test-primitive-rejected" and category or "factorio-test-primitive-"..category
  machine.minable=nil
  machine.next_upgrade=nil
  machine.fast_replaceable_group=nil
  machine.energy_source={type="void"}
  machine.crafting_speed=60
  machine.crafting_categories={category}
  machine.module_slots=0
  machine.allowed_effects={}
  machine.fluid_boxes=nil
  data:extend({machine})
end

-- Separate executors prove category acceptance and rejection.
for _,category in ipairs({"tiny-crafting","small-crafting","medium-crafting","large-crafting","huge-crafting","nullius-electrolysis"}) do
  if not data.raw["recipe-category"][category] then data:extend({{type="recipe-category",name=category}}) end
  local machine=table.deepcopy(data.raw["assembling-machine"]["assembling-machine-2"])
  machine.name="factorio-test-alignment-"..category
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

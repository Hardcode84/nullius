-- One declared batch per executor. Speed shortens tests; recipe times stay native.
local machine=table.deepcopy(data.raw["assembling-machine"]["assembling-machine-2"])
machine.name="factorio-test-turbine-recipe"
machine.minable=nil
machine.next_upgrade=nil
machine.fast_replaceable_group=nil
machine.energy_source={type="void"}
machine.crafting_speed=60
machine.crafting_categories={"turbine-open","turbine-closed","large-crafting","huge-assembly"}
machine.module_slots=0
machine.allowed_effects={}
machine.effect_receiver={uses_module_effects=false,uses_beacon_effects=false,uses_surface_effects=false}
machine.fluid_boxes={
  {production_type="input",volume=10000,pipe_connections={{flow_direction="input",direction=defines.direction.north,position={0,-1}}}},
  {production_type="output",volume=10000,pipe_connections={{flow_direction="output",direction=defines.direction.south,position={-1,1}}}},
  {production_type="output",volume=10000,pipe_connections={{flow_direction="output",direction=defines.direction.south,position={1,1}}}}
}
machine.fluid_boxes_off_when_no_fluid_recipe=false
data:extend({machine})

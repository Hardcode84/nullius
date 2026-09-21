for _,kind in ipairs({"barrel","unbarrel"}) do
  local machine=table.deepcopy(data.raw["assembling-machine"]["assembling-machine-2"])
  machine.name="factorio-test-"..kind
  machine.minable=nil
  machine.next_upgrade=nil
  machine.fast_replaceable_group=nil
  machine.energy_source={type="void"}
  machine.crafting_speed=1
  machine.crafting_categories={"nullius-"..kind}
  machine.module_slots=0
  machine.allowed_effects={}
  machine.effect_receiver={uses_module_effects=false,uses_beacon_effects=false,uses_surface_effects=false}
  machine.fluid_boxes={{production_type=kind=="barrel" and "input" or "output",volume=100,
    pipe_connections={{flow_direction=kind=="barrel" and "input" or "output",direction=defines.direction.north,position={0,-1}}}}}
  data:extend({machine})
end

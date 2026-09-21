-- Two separate finite fluid feeds; outputs stay in the machine.
local categories={"hand-casting","huge-assembly","huge-crafting","large-assembly","large-crafting","large-fluid-assembly","machine-casting","medium-crafting","medium-only-assembly","small-assembly","small-crafting","small-fluid-assembly","tiny-assembly","tiny-crafting","factorio-test-plumbing-rejected"}
data:extend({{type="recipe-category",name="factorio-test-plumbing-rejected"}})
for _,category in ipairs(categories) do
  local machine=table.deepcopy(data.raw["assembling-machine"]["assembling-machine-2"])
  machine.name="factorio-test-plumbing-"..category
  machine.minable=nil
  machine.next_upgrade=nil
  machine.fast_replaceable_group=nil
  machine.collision_box={{-3.4,-3.4},{3.4,3.4}}
  machine.selection_box={{-3.5,-3.5},{3.5,3.5}}
  machine.energy_source={type="void"}
  machine.crafting_speed=60
  machine.crafting_categories={category}
  machine.module_slots=0
  machine.allowed_effects={}
  machine.effect_receiver={uses_module_effects=false,uses_beacon_effects=false,uses_surface_effects=false}
  machine.fluid_boxes={}
  -- Exactly two inputs keep the two-fluid recipes on separate ports.
  for i=1,2 do
    machine.fluid_boxes[i]={production_type="input",volume=10000,
      pipe_connections={{flow_direction="input",direction=defines.direction.north,position={2*i-4,-3}}}}
  end
  machine.fluid_boxes[3]={production_type="output",volume=10000,
    pipe_connections={{flow_direction="output",direction=defines.direction.south,position={0,3}}}}
  machine.fluid_boxes_off_when_no_fluid_recipe=false
  data:extend({machine})
end

local buffer=table.deepcopy(data.raw.pipe["factorio-test-void-buffer"])
buffer.name="factorio-test-plumbing-buffer"
buffer.fluid_box.volume=10000
data:extend({buffer})

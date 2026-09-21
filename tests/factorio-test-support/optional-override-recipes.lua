-- One finite feed per fluid ingredient; outputs stay in the machine.
local cases=require("__nullius-star__/scenarios/optional-override-recipes/fixture")
data:extend({{type="recipe-category",name="factorio-test-optional-override-rejected"}})
local variants={["factorio-test-optional-override-rejected"]={category="factorio-test-optional-override-rejected",inputs=0,outputs=0}}
for _,case in ipairs(cases) do
  local inputs,outputs=0,0
  for _,part in ipairs(case.ingredients) do if part.type=="fluid" then inputs=inputs+1 end end
  for _,part in ipairs(case.products) do if part.type=="fluid" then outputs=outputs+1 end end
  for _,part in ipairs(case.ingredients) do inputs=math.max(inputs,part.port or 0) end
  for _,part in ipairs(case.products) do outputs=math.max(outputs,part.port or 0) end
  variants[case.name]={category=case.category,inputs=inputs,outputs=outputs,case=case}

end
for name,variant in pairs(variants) do
  local machine=table.deepcopy(data.raw["assembling-machine"]["assembling-machine-2"])
  machine.name="factorio-test-optional-override-"..name
  machine.minable=nil
  machine.next_upgrade=nil
  machine.fast_replaceable_group=nil
  machine.collision_box={{-3.4,-3.4},{3.4,3.4}}
  machine.selection_box={{-3.5,-3.5},{3.5,3.5}}
  machine.energy_source={type="void"}
  machine.crafting_speed=60
  machine.crafting_categories={variant.category}
  machine.module_slots=0
  machine.allowed_effects={}
  machine.effect_receiver={uses_module_effects=false,uses_beacon_effects=false,uses_surface_effects=false}
  machine.fluid_boxes={}
  -- Match port counts to each recipe to prevent merged input connections.
  for i=1,variant.inputs do
    machine.fluid_boxes[#machine.fluid_boxes+1]={production_type="input",volume=100000,
      pipe_connections={{flow_direction="input",direction=defines.direction.north,position={2*i-4,-3}}}}
  end
  for i=1,variant.outputs do
    machine.fluid_boxes[#machine.fluid_boxes+1]={production_type="output",volume=(variant.inputs==0 and variant.case and #variant.case.ingredients==0) and variant.case.products[i].amount or 100000,
      pipe_connections={{flow_direction="output",direction=defines.direction.south,position={2*i-4,3}}}}
  end
  machine.fluid_boxes_off_when_no_fluid_recipe=false
  data:extend({machine})
end

for _,case in ipairs(cases) do
  for _,part in ipairs(case.ingredients) do
    if part.type=="fluid" then
      local buffer=table.deepcopy(data.raw.pipe["factorio-test-void-buffer"])
      buffer.name="factorio-test-optional-override-buffer-"..case.name
      buffer.fluid_box.volume=part.amount
      data:extend({buffer})
    end
  end
end

local pump=table.deepcopy(data.raw.pump["factorio-test-void-pump"])
pump.name="factorio-test-optional-override-pump"
pump.pumping_speed=10000
data:extend({pump})

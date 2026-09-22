local contracts = require("recipe-test-contracts")
for name, recipe in pairs(contracts) do
  local machine = table.deepcopy(data.raw["assembling-machine"]["assembling-machine-2"])
  machine.name = "test-" .. name
  machine.minable = nil
  machine.next_upgrade = nil
  machine.fast_replaceable_group = nil
  machine.collision_box = {{-6.4,-6.4},{6.4,6.4}}
  machine.selection_box = {{-6.5,-6.5},{6.5,6.5}}
  machine.energy_source = {type="void"}
  machine.crafting_speed = 60
  machine.crafting_categories = recipe.categories or {recipe.category or "crafting"}
  machine.module_slots = 0
  machine.allowed_effects = {}
  machine.effect_receiver = {uses_module_effects=false,uses_beacon_effects=false,uses_surface_effects=false}
  machine.fluid_boxes = {}
  for _, spec in ipairs({{parts=recipe.ingredients,kind="input",direction=defines.direction.north,y=-6},
                         {parts=recipe.results,kind="output",direction=defines.direction.south,y=6}}) do
    local count = 0
    for _, part in ipairs(spec.parts) do if part.type == "fluid" then count = count + 1 end end
    for _, part in ipairs(spec.parts) do count = math.max(count, part.fluidbox_index or 0) end
    assert(count <= 6, "Too many fluid ports: " .. name)
    for i=1,count do
      machine.fluid_boxes[#machine.fluid_boxes+1] = {
        production_type=spec.kind,volume=100000,
        pipe_connections={{flow_direction=spec.kind,direction=spec.direction,position={2*i-7,spec.y}}}}
    end
  end
  machine.fluid_boxes_off_when_no_fluid_recipe = false
  data:extend({machine})
  for _, part in ipairs(recipe.ingredients) do
    if part.type == "fluid" then
      local buffer = table.deepcopy(data.raw.pipe.pipe)
      buffer.name = "test-buffer-" .. name .. "-" .. part.name
      buffer.minable = nil
      buffer.fast_replaceable_group = nil
      buffer.fluid_box.volume = part.amount
      data:extend({buffer})
    end
  end
end
local pump = table.deepcopy(data.raw.pump.pump)
pump.name = "test-recipe-pump"
pump.energy_source = {type="void"}
pump.pumping_speed = 10000
data:extend({pump})

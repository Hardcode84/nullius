local hide_connections = require("prototypes.entity.hide-fluid-connections")
local boxes = require("boxes")
for index, row in ipairs(boxes) do
  row.box.hide_connection_info = nil
  hide_connections(row.box)
  -- Preserve the complete box in the comparison contract. Load its connection
  -- schema natively with base artwork and the original fluid filter name.
  local box = table.deepcopy(row.box)
  box.pipe_picture = nil
  box.pipe_covers = nil
  if box.filter and not data.raw.fluid[box.filter] then
    local fluid = table.deepcopy(data.raw.fluid.water)
    fluid.name = box.filter
    data:extend({fluid})
  end
  local crafting = box.production_type == "input" or box.production_type == "output"
  local entity = table.deepcopy(crafting
    and data.raw["assembling-machine"]["assembling-machine-2"] or data.raw.pipe.pipe)
  if row.path[1] == "pump" then
    entity = table.deepcopy(data.raw.pump.pump)
  end
  entity.name = "hidden-connection-test-" .. index
  entity.next_upgrade = nil
  entity.collision_box = row.collision_box
  if crafting then entity.fluid_boxes = {box} else entity.fluid_box = box end
  data:extend({entity})
end
data:extend({{type="mod-data", name="hidden-connections", data={boxes=boxes}}})

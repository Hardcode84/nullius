local modern = require("__nullius-star__/factorio-version").is_2_1
local field = modern and "wagon_connection_graphics" or "fluid_wagon_connector_graphics"
local names={"nullius-pump-1","nullius-pump-2","nullius-togglable-pump-1",
  "nullius-togglable-pump-2","nullius-togglable-pump-3"}
for _,name in ipairs(names) do
  local source=data.raw.pump[name]
  assert(source[field]~=nil,"wagon connector graphics: " .. name)
  assert(source[field]==data.raw.pump.pump[field],"native connector graphics: " .. name)
  assert(source.fluid_wagon_connector_frame_count==35,"connector frames")
  local pump=table.deepcopy(source)
  pump.name="factorio-test-" .. name
  pump.minable=nil
  pump.placeable_by=nil
  pump.next_upgrade=nil
  pump.fast_replaceable_group=nil
  pump.energy_source={type="void"}
  data:extend({pump})
end

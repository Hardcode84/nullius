local modern = require("__nullius-star__/factorio-version").is_2_1
local field = modern and "wagon_connection_graphics" or "fluid_wagon_connector_graphics"
local names={"nullius-pump-1","nullius-pump-2","nullius-togglable-pump-1",
  "nullius-togglable-pump-2","nullius-togglable-pump-3"}
for _, name in ipairs({"nullius-togglable-pump-1-pneumatic",
  "nullius-togglable-pump-2-pneumatic", "nullius-togglable-pump-3-pneumatic"}) do
  if data.raw.pump[name] then names[#names+1] = name end
end
for _,name in ipairs(names) do
  local source=data.raw.pump[name]
  assert(source[field]~=nil,"wagon connector graphics: " .. name)
  assert(table.compare(source[field], data.raw.pump.pump[field]),"native connector graphics: " .. name)
  assert(source.fluid_wagon_connector_frame_count==35,"connector frames")
  if modern then
    assert(source.fluid_wagon_connector_alignment_tolerance == nil, "obsolete alignment tolerance: " .. name)
    assert(source.fluid_wagon_tank_valve_max_distance == data.raw.pump.pump.fluid_wagon_tank_valve_max_distance,
      "native pump arm reach: " .. name)
  else
    local tolerance = mods.Mini_Trains and name:match("^nullius%-pump%-") and 20/32 or 2/32
    assert(source.fluid_wagon_connector_alignment_tolerance == tolerance, "legacy alignment tolerance: " .. name)
    assert(source.fluid_wagon_tank_valve_max_distance == nil, "2.1 arm reach on 2.0: " .. name)
  end
  local pump=table.deepcopy(source)
  pump.name="factorio-test-" .. name
  pump.minable=nil
  pump.placeable_by=nil
  pump.next_upgrade=nil
  pump.fast_replaceable_group=nil
  pump.energy_source={type="void"}
  data:extend({pump})
end

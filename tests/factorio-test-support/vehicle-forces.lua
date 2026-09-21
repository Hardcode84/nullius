local cases = require("__nullius-star__/scenarios/vehicle-forces/fixture")
for _, case in ipairs(cases) do
  local car = table.deepcopy(data.raw.car[case.name])
  car.name = "factorio-test-reference-" .. case.name
  car.minable = nil
  car.braking_force = nil
  car.friction_force = nil
  if string.match(mods.base,"^2%.0%.") then
    -- Exercise the original engine conversion, independent of the port.
    car.braking_power = case.power
    car.friction = case.friction
  else
    car.braking_force = case.force
    car.friction_force = case.friction
  end
  data:extend({car})
end

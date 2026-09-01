local hot_surface = {
  {property = "nullius-ambient-temperature", min = 100},
}
local cool_surface = {
  {property = "nullius-ambient-temperature", max = 50},
}

for tier = 1, 4 do
  local name = "nullius-logistic-bot-" .. tier
  local prototype = data.raw["logistic-robot"][name]
  if not prototype then error("Missing " .. name) end
  prototype.surface_conditions = table.deepcopy(cool_surface)
end

local function clone(type_name, template, name)
  local result = table.deepcopy(data.raw[type_name][template])
  result.name = name
  result.localised_name = {"entity-name." .. name}
  result.localised_description = {"entity-description." .. name}
  result.icons = table.deepcopy(data.raw.item[name].icons)
  result.minable = {mining_time = 0.5, result = name}
  result.fast_replaceable_group = nil
  result.next_upgrade = nil
  result.surface_conditions = table.deepcopy(hot_surface)
  return result
end

local roboport = clone("roboport", "nullius-hangar-1",
  "nullius-clockwork-roboport")
roboport.energy_source = {type = "void"}
roboport.energy_usage = "1W"
roboport.recharge_minimum = "1J"
roboport.charging_energy = "0W"
roboport.logistics_radius = 12
roboport.logistics_connection_distance = 24
roboport.construction_radius = 0
roboport.draw_construction_radius_visualization = false
roboport.robot_slots_count = 2
roboport.material_slots_count = 0

local robot = clone("logistic-robot", "nullius-logistic-bot-1",
  "nullius-clockwork-logistic-robot")
robot.max_payload_size = 1
robot.max_payload_size_after_bonus = 1
robot.speed = 0.1
robot.max_speed = 0.1
robot.max_energy = "1MJ"
robot.energy_per_tick = "1kJ"
robot.energy_per_move = "0J"
robot.min_to_charge = 0
robot.max_to_charge = 1
robot.speed_multiplier_when_out_of_energy = 0

local storage = clone("logistic-container", "nullius-small-storage-chest-1",
  "nullius-primitive-storage-chest")
storage.inventory_size = 6
storage.max_logistic_slots = 1

local supply = clone("logistic-container", "nullius-small-supply-chest-1",
  "nullius-primitive-supply-chest")
supply.inventory_size = 2

local demand = clone("logistic-container", "nullius-small-demand-chest-1",
  "nullius-primitive-demand-chest")
demand.inventory_size = 2
demand.max_logistic_slots = 2
demand.trash_inventory_size = nil

data:extend({roboport, robot, storage, supply, demand})

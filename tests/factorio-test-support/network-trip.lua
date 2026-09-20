-- Test-only electrical fixtures with declared capacities and rates.
local source = table.deepcopy(data.raw["electric-energy-interface"]["electric-energy-interface"])
source.name = "factorio-test-trip-source"
source.localised_name = "Network trip source"
source.minable = nil
source.energy_source = {type="electric",buffer_capacity="100kJ",usage_priority="primary-output",
  input_flow_limit="0W",output_flow_limit="1MW",drain="0W"}
source.energy_production="1MW"
source.energy_usage="0W"
source.collision_mask={layers={}}
local load=table.deepcopy(source)
load.name="factorio-test-trip-load"
load.localised_name="Network trip load"
load.energy_source={type="electric",buffer_capacity="100kJ",usage_priority="secondary-input",
  input_flow_limit="100kW",output_flow_limit="0W",drain="0W"}
load.energy_production="0W"
load.energy_usage="100kW"
local battery=table.deepcopy(data.raw.accumulator.accumulator)
battery.name="factorio-test-trip-battery"
battery.localised_name="Network trip battery"
battery.minable=nil
battery.energy_source={type="electric",buffer_capacity="10MJ",usage_priority="tertiary",
  input_flow_limit="600kW",output_flow_limit="600kW",drain="0W"}
battery.collision_mask={layers={}}
local poles={}
for _,offline in ipairs({false,true}) do
  local pole=table.deepcopy(data.raw["electric-pole"]["factorio-test-lightning-pole"])
  pole.name=offline and "factorio-test-trip-pole-offline" or "factorio-test-trip-pole"
  pole.localised_name=offline and "Offline experiment pole" or "Online experiment pole"
  pole.fast_replaceable_group="factorio-test-trip-pole"
  pole.supply_area_distance=offline and 0 or 3
  poles[#poles+1]=pole
end
data:extend({source,load,battery,poles[1],poles[2]})

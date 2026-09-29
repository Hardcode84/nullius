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
local primary_load=table.deepcopy(load)
primary_load.name="factorio-test-trip-primary-load"
primary_load.localised_name="Primary network trip load"
primary_load.energy_source.usage_priority="primary-input"
local sink=table.deepcopy(load)
sink.name="factorio-test-trip-sink"
sink.localised_name="Network trip sink"
sink.flags={"not-on-map","not-blueprintable","not-deconstructable"}
sink.hidden=true
sink.selectable_in_game=false
sink.collision_box={{0,0},{0,0}}
sink.selection_box={{0,0},{0,0}}
sink.picture={filename="__core__/graphics/empty.png",width=1,height=1}
sink.energy_source={type="electric",buffer_capacity="1TJ",usage_priority="primary-input",
  input_flow_limit="1TW",output_flow_limit="0W",drain="0W"}
sink.energy_usage="1TW"
data:extend({source,load,primary_load,sink,battery,poles[1],poles[2]})

for _,watts in ipairs({0,100000,200000,900000,1000000,1000060,1100000,1100060,1200000,2000000,2400000,2400060}) do
  local fixture=table.deepcopy(source)
  fixture.name="factorio-test-trip-source-"..watts
  fixture.energy_production=watts.."W"
  fixture.energy_source.output_flow_limit=watts.."W"
  data:extend({fixture})
end

local threshold_load=table.deepcopy(load)
threshold_load.name="factorio-test-trip-load-1200000"
threshold_load.energy_usage="1200000W"
threshold_load.energy_source.input_flow_limit="1200000W"
data:extend({threshold_load})

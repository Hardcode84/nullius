local sink = table.deepcopy(data.raw["electric-energy-interface"]["electric-energy-interface"])
sink.name = "factorio-test-turbine-load"
sink.minable = nil
sink.energy_source = {type="electric",buffer_capacity="1MJ",usage_priority="primary-input",
  input_flow_limit="20MW",output_flow_limit="0W"}
sink.energy_production = "0W"
sink.energy_usage = "10MW"
data:extend({sink})

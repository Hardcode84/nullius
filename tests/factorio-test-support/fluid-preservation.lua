for _, name in ipairs({"compat-fluid-source", "compat-fluid-target"}) do
  local boiler = table.deepcopy(data.raw.boiler.boiler)
  boiler.name = name
  boiler.fast_replaceable_group = "compat-fluid"
  boiler.next_upgrade = nil
  data:extend({boiler})
end

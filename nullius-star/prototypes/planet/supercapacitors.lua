local config=require("shared.supercapacitors")
local tint={r=0.4,g=0.85,b=1}
local function tint_graphics(value)
  if type(value)~="table" or value.draw_as_shadow then return end
  if value.filename or value.filenames or value.stripes then value.tint=table.deepcopy(tint) end
  for _,child in pairs(value) do tint_graphics(child) end
end
for _,name in ipairs(config.machines) do
  local base=data.raw.accumulator[name]
  local variant=table.deepcopy(base)
  variant.name=name.."-supercapacitor"
  variant.localised_name={"entity-name.nullius-supercapacitor",base.localised_name or {"entity-name."..name}}
  variant.localised_description={"entity-description.nullius-supercapacitor",
    tostring(config.flow_factor),tostring(config.capacity_factor*100),tostring(config.leakage_per_second*100)}
  variant.hidden=true
  variant.placeable_by={item=name,count=1}
  variant.next_upgrade=nil
  local source=variant.energy_source
  local capacity=util.parse_energy(source.buffer_capacity)*config.capacity_factor
  source.buffer_capacity=tostring(capacity).."J"
  for _,field in ipairs({"input_flow_limit","output_flow_limit"}) do
    source[field]=tostring(util.parse_energy(source[field])*60*config.flow_factor).."W"
  end
  source.drain="0W"
  for _,icon in ipairs(variant.icons) do icon.tint=table.deepcopy(tint) end
  tint_graphics(variant.chargable_graphics)
  data:extend({variant})
end

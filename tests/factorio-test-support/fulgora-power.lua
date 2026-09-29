local original_battery=table.deepcopy(data.raw.accumulator['nullius-grid-battery-1'])
original_battery.name='factorio-test-power-original-battery'
original_battery.energy_source.input_flow_limit='200kW'
data:extend({original_battery})

-- Test-only collector output candidates; all other properties stay unchanged.
for _,mw in ipairs({0.5,1,2,5,100}) do
  local collector=table.deepcopy(data.raw['lightning-attractor']['nullius-pole-lightning-collector'])
  collector.name='factorio-test-power-collector-'..math.floor(mw*1000)
  collector.energy_source.output_flow_limit=mw..'MW'
  data:extend({collector})
end
local bolt=data.raw.lightning['nullius-fulgora-lightning']
local observation={type='direct',action_delivery={type='instant',
  target_effects={type='script',effect_id='fulgora-power-capture'}}}
bolt.attractor_hit_effect=bolt.attractor_hit_effect and {bolt.attractor_hit_effect,observation} or observation

for _,mw in ipairs({2,8}) do
  local sink=table.deepcopy(data.raw['electric-energy-interface']['factorio-test-trip-load'])
  sink.name='factorio-test-power-dump-'..mw
  sink.energy_source.buffer_capacity='1MJ'
  sink.energy_source.usage_priority='tertiary'
  sink.energy_source.input_flow_limit=mw..'MW'
  sink.energy_usage=mw..'MW'
  data:extend({sink})
end

-- Two-second burst candidates and rapid-charge batteries for the tuning witness.
for _,mw in ipairs({10,25,50,100}) do
  local collector=table.deepcopy(data.raw['lightning-attractor']['nullius-pole-lightning-collector'])
  collector.name='factorio-test-burst-collector-'..mw
  collector.energy_source.output_flow_limit=mw..'MW'
  collector.energy_source.buffer_capacity=(2*mw)..'MJ'
  data:extend({collector})
end
local battery=table.deepcopy(data.raw.accumulator['nullius-grid-battery-1'])
battery.name='factorio-test-burst-battery'
battery.energy_source.input_flow_limit='15MW'
data:extend({battery})
for _,mw in ipairs({32,100,160,400,800,1600}) do
  local sink=table.deepcopy(data.raw['electric-energy-interface']['factorio-test-power-dump-8'])
  sink.name='factorio-test-power-dump-'..mw
  sink.energy_source.buffer_capacity=(mw/30)..'MJ'
  sink.energy_source.input_flow_limit=mw..'MW'
  sink.energy_usage=mw..'MW'
  data:extend({sink})
end

local fast_battery=table.deepcopy(battery)
fast_battery.name='factorio-test-burst-battery-fast'
fast_battery.energy_source.input_flow_limit='50MW'
data:extend({fast_battery})

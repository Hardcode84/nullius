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

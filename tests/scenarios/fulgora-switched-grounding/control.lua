local reference=require('__nullius-star__/scenarios/fulgora-power-audit/fixture')[5]
local profiles={}
for _,mode in ipairs({{name='fixed'}, {name='all-80-30',permanent=0,high=80,low=30},
    {name='reserve-4-80-30',permanent=4,high=80,low=30},
    {name='reserve-8-80-30',permanent=8,high=80,low=30},
    {name='reserve-4-98-90',permanent=4,high=98,low=90}}) do
  local profile={}
  for k,v in pairs(reference) do profile[k]=v end
  profile.name=mode.name;profile.load_name=reference.name
  profile.switched=mode.name~='fixed'
  profile.permanent=mode.permanent;profile.high=mode.high;profile.low=mode.low
  profiles[#profiles+1]=profile
end
require('__nullius-star__/scenarios/fulgora-power-grid')('fulgora-switched-grounding',profiles)

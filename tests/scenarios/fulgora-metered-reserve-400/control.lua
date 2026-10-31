local profile={}
for k,v in pairs(require('__nullius-star__/scenarios/fulgora-power-audit/fixture')[5]) do profile[k]=v end
profile.name='reserve-400MW';profile.reserve_kW=400000;profile.load_name='science-60-spread'
profile.switched=true;profile.metered=true;profile.permanent=0
require('__nullius-star__/scenarios/fulgora-power-grid')('fulgora-metered-reserve-400',{profile})

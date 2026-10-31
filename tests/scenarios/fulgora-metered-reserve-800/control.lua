local profile={}
for k,v in pairs(require('__nullius-star__/scenarios/fulgora-power-audit/fixture')[5]) do profile[k]=v end
profile.name='reserve-800MW';profile.reserve_kW=800000;profile.load_name='science-60-spread'
profile.switched=true;profile.metered=true;profile.permanent=0
require('__nullius-star__/scenarios/fulgora-power-grid')('fulgora-metered-reserve-800',{profile})

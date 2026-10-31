local profiles={}
for _,source in ipairs(require('__nullius-star__/scenarios/fulgora-power-audit/fixture')) do
  if source.layout=='starter' then
    local profile={}
    for key,value in pairs(source) do profile[key]=value end
    profile.starter_switching=true
    profile.current_stock=source.name=='starter-mean' or source.name=='starter-full'
    if source.name=='starter-mean' then profile.minimum_supply_percent=99.99 end
    profiles[#profiles+1]=profile
  end
end
require('__nullius-star__/scenarios/fulgora-power-grid')('fulgora-starter-current',profiles)

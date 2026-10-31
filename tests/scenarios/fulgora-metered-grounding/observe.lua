-- Observe every switch transition; capture the sampled flow that precedes a trip.
return function(rows,check)
  for _,row in ipairs(rows or {}) do
    if row.switches then
      row.controller=row.controller or {changes=0,max_changes_per_sample=0,checked_samples=0,recent={}}
      local c=row.controller
      local window=math.floor((game.tick-1)/30)
      if c.window~=window then c.window=window;c.counts={} end
      local mask=0
      row.states=row.states or {}
      for i,switch in ipairs(row.switches) do
        local state=switch.power_switch_state
        if state then mask=mask+2^(i-1) end
        if row.states[i]~=nil and row.states[i]~=state then
          c.counts[i]=(c.counts[i] or 0)+1;c.changes=c.changes+1
          c.max_changes_per_sample=math.max(c.max_changes_per_sample,c.counts[i])
          check(c.counts[i]<=1,'bank changed more than once per meter sample')
        end
        row.states[i]=state
      end
      if game.tick%30==1 then c.offline=remote.call('nullius-test-overload','offline',row.poles[1]) end
      local offline=c.offline
      if game.tick%30==0 and not offline then
        local flow=row.sensor.electric_network.parent_network.flow_last_tick
        c.recent[#c.recent+1]={tick=game.tick,banks=mask,
          offered_kW=(flow.primary_output+flow.secondary_output+flow.solar_output)*60/1000,
          demand_kW=(flow.primary_demand+flow.secondary_demand+flow.tertiary_demand)*60/1000}
        if #c.recent>6 then table.remove(c.recent,1) end
      elseif game.tick%30==1 then
        if offline and not c.trip_tick then c.trip_tick=game.tick-1 end
        if not offline then
          local section=remote.call('nullius-test-grid-meter','output',row.sensor).get_control_behavior().get_section(1)
          local o,d=section.get_slot(1).min,section.get_slot(2).min
          c.target=math.max(0,math.min(31,math.ceil((o-2*d+800000*mask+2)/800000)))
        end
      elseif game.tick%30==16 and c.target and not offline then
        check(mask==c.target,'native controller did not select calculated bank target')
        c.checked_samples=c.checked_samples+1
      end
    end
  end
end

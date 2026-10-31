-- Given: the wreck's poles and coils, plus four declared power switches.
-- Connect: separate coil feeds; the meter controls each switch without script writes.
return function(profile,row,pole,place,check)
  local ids=defines.wire_connector_id
  local function wire(a,aid,b,bid)
    local left=a.get_wire_connector(aid,true)
    local right=b.get_wire_connector(bid,true)
    check(left.is_connected_to(right) or left.connect_to(right),'starter wire cannot reach '..a.name..' '..a.position.x..','..a.position.y..' -> '..b.name..' '..b.position.x..','..b.position.y)
  end
  local main={}
  row.starter_banks={};row.isolated_poles={}
  for i=0,3 do
    local line={}
    for j=0,8 do line[j+1]=pole('small-electric-pole',j*6,2+i*42) end
    main[i+1]=line
    local coil=place('nullius-grounding-coil',62,i*42,true)
    local feed=pole('small-electric-pole',62,3+i*42)
    row.isolated_poles[feed.unit_number]=true
    feed.get_wire_connector(ids.pole_copper,true).disconnect_all()
    local switch=place('power-switch',54,3+i*42,false)
    switch.power_switch_state=false
    wire(line[9],ids.pole_copper,switch,ids.power_switch_left_copper)
    wire(feed,ids.pole_copper,switch,ids.power_switch_right_copper)
    check(coil.electric_network_id==feed.electric_network_id,'coil feed has no supply coverage')
    check(feed.electric_network_id~=line[9].electric_network_id,'coil bank bypasses its switch')
    row.starter_banks[i+1]={switch=switch,feed=feed,main=line[9]}
    for j=1,8 do wire(line[j],ids.circuit_red,line[j+1],ids.circuit_red) end
    wire(line[9],ids.circuit_red,switch,ids.circuit_red)
  end
  local trunk={}
  for i,y in ipairs({2,30,51,81,104,128}) do trunk[i]=pole('big-electric-pole',-2,y) end
  for i=1,5 do wire(trunk[i],ids.circuit_red,trunk[i+1],ids.circuit_red) end
  for i,line in ipairs(main) do
    local nearest=trunk[1]
    for _,candidate in ipairs(trunk) do
      if math.abs(candidate.position.y-line[1].position.y)<math.abs(nearest.position.y-line[1].position.y) then nearest=candidate end
    end
    wire(line[1],ids.circuit_red,nearest,ids.circuit_red)
  end
  return function()
    local sensor=row.batteries[1]
    remote.call('nullius-test-grid-meter','set',sensor,{offered={type='virtual',name='signal-O'}})
    -- Noncollecting test wires connect the off-grid storage fixture only.
    local previous=sensor
    local relays={}
    for dx=-114,-6,6 do relays[#relays+1]={dx,70} end
    for _,pos in ipairs({{-6,64},{-6,58},{-2,55}}) do relays[#relays+1]=pos end
    for _,pos in ipairs(relays) do
      local relay=place('factorio-test-audit-wire',pos[1],pos[2],false)
      relay.get_wire_connector(ids.pole_copper,true).disconnect_all()
      wire(previous,ids.circuit_red,relay,ids.circuit_red);previous=relay
    end
    wire(previous,ids.circuit_red,trunk[3],ids.circuit_red)
    for i,bank in ipairs(row.starter_banks) do
      local control=bank.switch.get_or_create_control_behavior()
      control.circuit_condition={first_signal={type='virtual',name='signal-O'},
        comparator='>',constant=(2*(i-1)-1)*profile.grounding_MW/profile.coils*1000}
      control.circuit_enable_disable=true
    end
  end
end

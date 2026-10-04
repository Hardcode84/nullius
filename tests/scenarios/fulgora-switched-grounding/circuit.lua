-- Real accumulator output, decider feedback latch, and copper power switch.
-- Switch on: A > high OR (S > 0 AND A > low). No scripted switching or resets.
return function(surface,x,profile,row,place,check)
  local ids=defines.wire_connector_id
  game.forces.player.technologies['nullius-supercapacitors'].researched=true
  game.forces.player.recipes['nullius-grid-battery-1'].enabled=true
  local function wire(a,aid,b,bid)
    check(a.get_wire_connector(aid,true).connect_to(b.get_wire_connector(bid,true)), 'wire failed '..a.name..' -> '..b.name)
  end
  local main={}
  for _,px in ipairs({380,440}) do main[#main+1]=place('factorio-test-audit-distribution',px,12,false) end
  for i,p in ipairs(main) do
    p.get_wire_connector(ids.pole_copper,true).disconnect_all()
    wire(p,ids.pole_copper,i==1 and row.poles[16] or main[i-1],ids.pole_copper)
  end
  local bank=place('factorio-test-audit-distribution',520,12,false)
  bank.get_wire_connector(ids.pole_copper,true).disconnect_all()
  local previous=bank
  for px=560,896,48 do
    local pole=place('factorio-test-audit-distribution',px,12,false)
    pole.get_wire_connector(ids.pole_copper,true).disconnect_all()
    wire(previous,ids.pole_copper,pole,ids.pole_copper);previous=pole
  end
  for i=0,31-profile.permanent do
    local cx=600+(i%8)*42;local cy=12+math.floor(i/8)*42
    place('nullius-grounding-coil',cx,cy,true)
    if cy>12 then
      local feed=place('factorio-test-audit-distribution',cx,cy,false)
      -- Neighbouring bank poles connect automatically; no main pole is in range.
      check(feed.electric_network_id==bank.electric_network_id,'disconnected grounding bank')
    end
  end
  local tiles={}
  for dx=424,486 do for y=20,28 do tiles[#tiles+1]={name='fulgoran-rock',position={x+dx,y}} end end
  surface.set_tiles(tiles,true)
  row.sensor=place('nullius-grid-battery-1-supercapacitor',430,24,true)
  row.switch=place('power-switch',480,24,false)
  row.switch.power_switch_state=false
  local left=place('factorio-test-audit-wire',474,24,false)
  local right=place('factorio-test-audit-wire',486,24,false)
  left.get_wire_connector(ids.pole_copper,true).disconnect_all()
  right.get_wire_connector(ids.pole_copper,true).disconnect_all()
  wire(main[2],ids.pole_copper,left,ids.pole_copper)
  wire(bank,ids.pole_copper,right,ids.pole_copper)
  wire(left,ids.pole_copper,row.switch,ids.power_switch_left_copper)
  wire(right,ids.pole_copper,row.switch,ids.power_switch_right_copper)
  local latch=place('decider-combinator',435,24,false)
  row.sensor.get_or_create_control_behavior().read_charge=true
  row.sensor.get_or_create_control_behavior().output_signal={type='virtual',name='signal-A'}
  latch.get_or_create_control_behavior().parameters={conditions={
    {first_signal={type='virtual',name='signal-A'},comparator='>',constant=profile.high},
    {first_signal={type='virtual',name='signal-S'},comparator='>',constant=0,compare_type='or'},
    {first_signal={type='virtual',name='signal-A'},comparator='>',constant=profile.low,compare_type='and'}},
    outputs={{signal={type='virtual',name='signal-S'},copy_count_from_input=false,constant=1}}}
  wire(row.sensor,ids.circuit_red,latch,ids.combinator_input_red)
  wire(latch,ids.combinator_output_green,latch,ids.combinator_input_green)
  local relay=place('factorio-test-audit-wire',440,24,false)
  relay.get_wire_connector(ids.pole_copper,true).disconnect_all()
  wire(latch,ids.combinator_output_red,relay,ids.circuit_red)
  wire(relay,ids.circuit_red,left,ids.circuit_red)
  wire(left,ids.circuit_red,row.switch,ids.circuit_red)
  local control=row.switch.get_or_create_control_behavior()
  control.circuit_condition={first_signal={type='virtual',name='signal-S'},comparator='>',constant=0}
  control.circuit_enable_disable=true
  check(control.circuit_condition.first_signal.name=='signal-S','switch condition missing')
  check(main[2].electric_network_id~=bank.electric_network_id,'grounding switch bypassed')
  row.bank=bank
end

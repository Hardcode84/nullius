-- given: native storms, separate binary coil banks, no injected bank energy.
-- connect: test distribution wires; one collecting pylon per bank.
-- act: production meter and native combinators operate every power switch.
local controller=require('__nullius-star__/scenarios/fulgora-metered-grounding/controller')
return function(surface,x,profile,row,place,check)
  local ids=defines.wire_connector_id
  game.forces.player.technologies['nullius-supercapacitors'].researched=true
  game.forces.player.recipes['nullius-grid-battery-1'].enabled=true
  local function wire(a,aid,b,bid)
    local aa=a.get_wire_connector(aid,true);local bb=b.get_wire_connector(bid,true)
    if not aa.can_wire_reach(bb) and aid~=ids.pole_copper then
      local dx=b.position.x-a.position.x;local dy=b.position.y-a.position.y
      local steps=math.ceil(math.sqrt(dx*dx+dy*dy)/6)
      local previous=aa
      local color=(aid==ids.circuit_red or aid==ids.combinator_output_red) and ids.circuit_red or ids.circuit_green
      for j=1,steps-1 do
        local relay=place('factorio-test-audit-wire',a.position.x-x+dx*j/steps,a.position.y+dy*j/steps,false)
        relay.get_wire_connector(ids.pole_copper,true).disconnect_all()
        local connector=relay.get_wire_connector(color,true)
        check(previous.connect_to(connector),'circuit relay wire failed');previous=connector
      end
      check(previous.connect_to(bb),'last circuit relay wire failed')
      return
    end
    check(aa.is_connected_to(bb) or aa.connect_to(bb),'metered bank wire failed '..a.name..' '..a.position.x..','..a.position.y..' -> '..b.name..' '..b.position.x..','..b.position.y)
  end
  local function copper(a,b) wire(a,ids.pole_copper,b,ids.pole_copper) end
  local function isolated(name,dx,y)
    local p=place(name,dx,y,false);p.get_wire_connector(ids.pole_copper,true).disconnect_all();return p
  end
  local tiles={}
  for dx=410,465 do for y=20,48 do tiles[#tiles+1]={name='fulgoran-rock',position={x+dx,y}} end end
  surface.set_tiles(tiles,true)
  local bridge=isolated('factorio-test-audit-distribution',380,0);copper(row.poles[16],bridge)
  local main=isolated('factorio-test-audit-distribution',440,12);copper(bridge,main)
  row.sensor=place('nullius-grid-battery-1-supercapacitor',420,24,true)
  remote.call('nullius-test-grid-meter','set',row.sensor,{offered={type='virtual',name='signal-O'},
    demand={type='virtual',name='signal-D'}})
  local outputs,hold=controller(
    row.sensor,place,wire,400000,5)
  row.memory=hold;row.switches={};row.bank_coils={};row.bank_poles={}
  local trunk=main
  for i=1,5 do
    local y=100+(i-1)*176
    while trunk.position.y<y-50 do
      local next=isolated('factorio-test-audit-distribution',440,trunk.position.y+48)
      copper(trunk,next);trunk=next
    end
    if trunk.position.y~=y then
      local next=isolated('factorio-test-audit-distribution',440,y);copper(trunk,next);trunk=next
    end
    local branch=isolated('factorio-test-audit-distribution',500,y);copper(trunk,branch)
    local first
    local feeds={}
    for j=0,2^(i-1)-1 do
      local cx=600+(j%4)*42;local cy=y+math.floor(j/4)*42
      local coil=place('nullius-grounding-coil',cx,cy,true);row.bank_coils[#row.bank_coils+1]=coil
      local feed=isolated('factorio-test-audit-distribution',cx+3,cy+3)
      feeds[j+1]=feed
      if j>0 then copper(feeds[j%4>0 and j or j-3],feed) else first=feed end
    end
    local collector=place('big-electric-pole',600,y+6,true)
    collector.get_wire_connector(ids.pole_copper,true).disconnect_all();copper(collector,first)
    row.bank_poles[#row.bank_poles+1]=collector
    local pad={}
    for dx=548,556 do for dy=y-4,y+4 do pad[#pad+1]={name='fulgoran-rock',position={x+dx,dy}} end end
    surface.set_tiles(pad,true)
    local switch=place('power-switch',552,y,false);switch.power_switch_state=false
    row.switches[i]=switch
    local left=isolated('factorio-test-audit-wire',546,y)
    local right=isolated('factorio-test-audit-wire',558,y)
    copper(branch,left);copper(first,right)
    wire(left,ids.pole_copper,switch,ids.power_switch_left_copper)
    wire(right,ids.pole_copper,switch,ids.power_switch_right_copper)
    -- Circuit wires use the same distribution trunk as copper, with a separate
    -- signal per bank so the five switch conditions remain independent.
    local bit=outputs[i]
    local rename=place('arithmetic-combinator',430+(i-1)*3,45,false)
    rename.get_or_create_control_behavior().parameters={first_signal={type='virtual',name='signal-S'},
      operation='+',second_constant=0,output_signal={type='virtual',name='signal-'..i}}
    wire(bit,ids.combinator_output_red,rename,ids.combinator_input_red)
    wire(rename,ids.combinator_output_red,main,ids.circuit_red)
    local previous=main
    for _,p in pairs(surface.find_entities_filtered{name='factorio-test-audit-distribution',
        area={{x+439,25},{x+441,y+1}}}) do
      wire(previous,ids.circuit_red,p,ids.circuit_red);previous=p
    end
    wire(previous,ids.circuit_red,branch,ids.circuit_red)
    wire(branch,ids.circuit_red,left,ids.circuit_red)
    wire(left,ids.circuit_red,switch,ids.circuit_red)
    local behavior=switch.get_or_create_control_behavior()
    behavior.circuit_condition={first_signal={type='virtual',name='signal-'..i},comparator='>',constant=0}
    behavior.circuit_enable_disable=true
    check(first.electric_network_id~=main.electric_network_id,'metered bank bypasses switch')
  end
end

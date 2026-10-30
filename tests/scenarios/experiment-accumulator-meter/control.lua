-- given: one real client, Fulgora surface, unlocked supercapacitors, declared
-- 1 MW primary sources, 100 kW and 1.2 MW loads, no lightning or collectors.
-- place/connect: grid battery with a hidden constant-combinator output joined by
-- script-origin wires; player-origin wire from the battery to a power switch
-- between two grids; a second battery covered by two unwired grids.
-- act: write offered/demand kW every 30 ticks; open GUIs; switch battery mode;
-- blueprint, revive, copy settings; stop writes, snapshot, reload, compare, resume.
-- expect: observations of each API path; assertions on the established ones.
local CASE="experiment-accumulator-meter"
local ids=defines.wire_connector_id
local PANEL="factorio_test_meter"
local SIGNALS={offered={type="virtual",name="signal-O"},demand={type="virtual",name="signal-D"}}
local function check(ok,message) storage.assertions=storage.assertions+1;assert(ok,message) end
local function observe(key,value) storage.observations[key]=value end

-- Parent networks have no id; key them by their lowest sub-network id.
local function parent_key(parent)
  local id=math.huge
  for _,sub in pairs(parent.sub_networks) do id=math.min(id,sub.id) end
  return id
end
local function flow_kw(entity)
  local network=entity.electric_network
  local parent=network.parent_network
  local flow=parent.flow_last_tick
  return {network=network.object_name,network_id=network.id,parent_key=parent_key(parent),
    offered=math.floor((flow.primary_output+flow.secondary_output+flow.solar_output)*60/1000+0.5),
    demand=math.floor((flow.primary_demand+flow.secondary_demand+flow.tertiary_demand)*60/1000+0.5)}
end
local function output_for(entity)
  local output=assert(entity.surface.create_entity{name="factorio-test-meter-output",
    position=entity.position,force=entity.force})
  for _,id in ipairs({ids.circuit_red,ids.circuit_green}) do
    check(entity.get_wire_connector(id,true).connect_to(output.get_wire_connector(id,true),
      false,defines.wire_origin.script),"script wire failed")
  end
  return output
end
local function write(row)
  if not (row.entity.valid and row.output.valid) then return end
  local values=flow_kw(row.entity)
  local behavior=row.output.get_or_create_control_behavior()
  local section=behavior.sections_count>0 and behavior.get_section(1) or behavior.add_section()
  section.set_slot(1,{value={type="virtual",name="signal-O",quality="normal"},min=values.offered})
  section.set_slot(2,{value={type="virtual",name="signal-D",quality="normal"},min=values.demand})
  row.last=values
end
local function connections(entity)
  local result={}
  for _,id in ipairs({ids.circuit_red,ids.circuit_green}) do
    for _,c in pairs(entity.get_wire_connector(id,true).connections) do
      result[#result+1]={connector=id,target=c.target.owner.name,origin=c.origin}
    end
  end
  table.sort(result,function(a,b) return a.connector..a.target..a.origin<b.connector..b.target..b.origin end)
  return result
end
local function signals(entity,id)
  local network=entity.get_circuit_network(id)
  local result={}
  for _,s in pairs(network and network.signals or {}) do result[s.signal.name]=s.count end
  return result
end
local function panel(player)
  local old=player.gui.relative[PANEL]
  if old then return old end
  local frame=player.gui.relative.add{type="frame",name=PANEL,direction="vertical",caption="Grid meter",
    anchor={gui=defines.relative_gui_type.accumulator_gui,position=defines.relative_gui_position.right}}
  for _,key in ipairs({"offered","demand"}) do
    local flow=frame.add{type="flow",name=key,direction="horizontal"}
    flow.add{type="label",caption=key}
    flow.add{type="choose-elem-button",name="signal",elem_type="signal",signal=SIGNALS[key]}
  end
  return frame
end
local function screenshot(player,entity,name)
  game.take_screenshot{player=player,by_player=player,show_gui=true,position=entity.position,
    zoom=1,force_render=true,path=CASE.."/"..name..".png"}
end
local function place(name,x,y,raise)
  return assert(storage.surface.create_entity{name=name,position={x,y},force="player",raise_built=raise})
end
local function isolate(pole) pole.get_wire_connector(ids.pole_copper,true).disconnect_all() end

script.on_init(function() storage.stage="setup";storage.assertions=0;storage.joins=0;storage.observations={};storage.meters={} end)
script.on_event(defines.events.on_player_joined_game,function(event)
  storage.joins=storage.joins+1
end)
script.on_event(defines.events.script_raised_revive,function(event)
  storage.observations.revive_tags=event.tags or "nil"
  storage.observations.revive_name=event.entity.name
end)
script.on_event(defines.events.on_entity_settings_pasted,function(event)
  storage.observations.paste_event={source=event.source.name,destination=event.destination.name}
end)

local stages={}
function stages.setup(player)
  local surface=game.planets["nullius-fulgora"].create_surface()
  surface.request_to_generate_chunks({0,0},3);surface.force_generate_chunk_requests()
  for _,entity in pairs(surface.find_entities()) do entity.destroy() end
  local tiles={}
  for x=-20,50 do for y=-15,60 do tiles[#tiles+1]={name="fulgoran-rock",position={x,y}} end end
  surface.set_tiles(tiles,true)
  storage.surface=surface
  player.force.technologies["nullius-supercapacitors"].researched=true
  player.force.recipes["nullius-grid-battery-1"].enabled=true
  player.set_controller{type=defines.controllers.god};player.teleport({4,4},surface)
  -- Grid A: battery meter and 1 MW source. Grid B: 1.2 MW load behind the switch.
  storage.pa=place("factorio-test-trip-pole",0,0);isolate(storage.pa)
  storage.source=place("factorio-test-trip-source-1000000",-1,1)
  place("factorio-test-trip-load",-1,-1)
  storage.battery=place("nullius-grid-battery-1",1.5,1.5,true)
  storage.battery.energy=storage.battery.electric_buffer_size
  local control=storage.battery.get_or_create_control_behavior()
  control.read_charge=true;control.output_signal={type="virtual",name="signal-A"}
  storage.pb=place("factorio-test-trip-pole",14,0);isolate(storage.pb)
  place("factorio-test-trip-load-1200000",15,1)
  storage.switch=place("power-switch",8,0)
  storage.switch.power_switch_state=false
  check(storage.pa.get_wire_connector(ids.pole_copper,true).connect_to(
    storage.switch.get_wire_connector(ids.power_switch_left_copper,true),false),"left copper")
  check(storage.pb.get_wire_connector(ids.pole_copper,true).connect_to(
    storage.switch.get_wire_connector(ids.power_switch_right_copper,true),false),"right copper")
  check(storage.battery.get_wire_connector(ids.circuit_red,true).connect_to(
    storage.switch.get_wire_connector(ids.circuit_red,true),false),"player circuit wire")
  local switch=storage.switch.get_or_create_control_behavior()
  switch.circuit_enable_disable=true
  switch.circuit_condition={first_signal=SIGNALS.offered,comparator=">",constant=1500}
  storage.meters[1]={entity=storage.battery,output=output_for(storage.battery)}
  check(storage.pa.electric_network_id~=storage.pb.electric_network_id,"switch bypassed")
  return "gui"
end
function stages.gui(player)
  player.opened=storage.battery
  observe("battery_gui_type",player.opened_gui_type)
  check(player.opened==storage.battery and player.opened_gui_type==defines.gui_type.entity,"battery GUI not opened")
  local frame=panel(player)
  observe("panel_anchor",{gui=frame.anchor.gui,position=frame.anchor.position})
  check(frame.anchor.gui==defines.relative_gui_type.accumulator_gui,"panel not anchored to accumulator GUI")
  check(frame.offered.signal.elem_type=="signal" and frame.offered.signal.elem_value.name=="signal-O","signal picker")
  return "signals"
end
function stages.signals(player)
  check(player.opened==storage.battery,"battery GUI closed")
  screenshot(player,storage.battery,"battery")
  local seen=signals(storage.switch,ids.circuit_red)
  observe("meter_one_source",storage.meters[1].last)
  observe("switch_signals_one_source",seen)
  local wires=connections(storage.battery)
  observe("battery_connections",wires)
  check(#wires==3 and wires[1].origin==defines.wire_origin.script and wires[2].origin==defines.wire_origin.player
    and wires[3].origin==defines.wire_origin.script,"battery wires: two script wires and one player wire")
  check(seen["signal-D"]==100,"demand signal missing from player wire")
  check(seen["signal-A"]==100,"charge signal missing from player wire")
  check(seen["signal-O"]==1000,"offered signal missing from player wire")
  check(not storage.switch.power_switch_state,"switch closed below threshold")
  storage.source2=place("factorio-test-trip-source-1000000",-1,-2)
  return "switch_on"
end
function stages.switch_on(player)
  observe("meter_two_sources",storage.meters[1].last)
  observe("switch_signals_two_sources",signals(storage.switch,ids.circuit_red))
  observe("switch_state",storage.switch.power_switch_state)
  observe("merged",storage.pa.electric_network_id==storage.pb.electric_network_id)
  return "merged_sample"
end
function stages.merged_sample(player)
  observe("meter_merged",storage.meters[1].last)
  check(storage.switch.power_switch_state,"meter signal did not close the switch")
  check(storage.meters[1].last.offered==2000 and storage.meters[1].last.demand==1300,
    "meter does not read the switch-merged parent network")
  -- Overlap: battery inside supply areas of two unwired grids, C with a source.
  storage.pc=place("factorio-test-trip-pole",0,30);isolate(storage.pc)
  place("factorio-test-trip-source-1000000",-1,31)
  storage.pd=place("factorio-test-trip-pole",5,30);isolate(storage.pd)
  place("factorio-test-trip-load",6,31)
  storage.overlap=place("nullius-grid-battery-1",2.5,30.5,true)
  storage.overlap.energy=0
  storage.meters[2]={entity=storage.overlap,output=output_for(storage.overlap)}
  storage.overlap_start=game.tick
  return "overlap"
end
function stages.overlap(player)
  local subs={}
  for _,sub in pairs(storage.overlap.electric_networks) do
    subs[#subs+1]={id=sub.id,parent=parent_key(sub.parent_network)}
  end
  table.sort(subs,function(a,b) return a.id<b.id end)
  local c,d=storage.pc.electric_network,storage.pd.electric_network
  observe("overlap",{primary_network_id=storage.overlap.electric_network.id,
    primary_object=storage.overlap.electric_network.object_name,
    subs=subs,c_id=c.id,c_parent=parent_key(c.parent_network),d_id=d.id,d_parent=parent_key(d.parent_network),
    c_flow=flow_kw(storage.pc),d_flow=flow_kw(storage.pd),meter=storage.meters[2].last,
    energy_MJ=storage.overlap.energy/1e6,ticks=game.tick-storage.overlap_start})
  local primary=storage.overlap.electric_network.id
  check(#subs==2 and subs[1].parent~=subs[2].parent,"overlap battery must join two separate parent networks")
  check((primary==c.id or primary==d.id) and storage.meters[2].last.network_id==primary,
    "meter must read the primary network")
  -- Charging demand appears in both networks; the battery passes C energy to D.
  local cf,df=flow_kw(storage.pc),flow_kw(storage.pd)
  check(cf.demand==50000 and df.demand==49100,"battery charge demand must appear in both networks")
  check(math.abs(storage.overlap.energy-0.45e6)<1,"battery must net 0.9 MW: 1 MW from C less 100 kW to D")
  return "transition"
end
function stages.transition(player)
  local position=storage.battery.position
  observe("transition_result",remote.call("nullius-test-transitions","execute",storage.battery))
  observe("old_valid",storage.battery.valid)
  local cap=storage.surface.find_entity("nullius-grid-battery-1-supercapacitor",position)
  check(cap~=nil,"supercapacitor not created")
  storage.cap=cap
  observe("cap_connections",connections(cap))
  observe("output_after_transition",{valid=storage.meters[1].output.valid,
    connections=storage.meters[1].output.valid and connections(storage.meters[1].output) or {}})
  local control=cap.get_control_behavior()
  observe("cap_control",{read_charge=control and control.read_charge,
    signal=control and control.output_signal and control.output_signal.name})
  observe("opened_after_transition",player.opened~=nil)
  local wires=connections(cap)
  check(#wires==1 and wires[1].target=="power-switch" and wires[1].origin==defines.wire_origin.player,
    "mode switch must keep player wires and drop script wires")
  check(storage.meters[1].output.valid and #connections(storage.meters[1].output)==0,
    "mode switch must leave the hidden output disconnected")
  check(control.read_charge and control.output_signal.name=="signal-A","mode switch lost charge settings")
  check(player.opened==nil,"mode switch must close the battery GUI")
  player.opened=cap
  observe("cap_gui_type",player.opened_gui_type)
  check(player.opened==cap and player.gui.relative[PANEL]~=nil,"supercapacitor GUI or panel missing")
  return "blueprint"
end
function stages.blueprint(player)
  check(player.opened==storage.cap,"supercapacitor GUI closed")
  screenshot(player,storage.cap,"supercapacitor")
  -- The meter must follow the replacement; reconnect explicitly when wires were lost.
  local row=storage.meters[1]
  if not row.output.valid or #connections(storage.cap)<3 then
    if row.output.valid then row.output.destroy() end
    row.output=output_for(storage.cap)
  end
  row.entity=storage.cap
  local inventory=game.create_inventory(1)
  inventory.insert{name="blueprint"}
  local blueprint=inventory[1]
  local mapping=blueprint.create_blueprint{surface=storage.surface,force="player",area={{-3,-3},{10,4}}}
  local names,cap_index={},nil
  for index,entity in pairs(mapping) do
    names[#names+1]=entity.name
    if entity==storage.cap then cap_index=index end
  end
  table.sort(names)
  observe("blueprint_entities",names)
  local wires={}
  for _,wire in pairs(blueprint.get_blueprint_entities() or {}) do
    for _,w in pairs(wire.wires or {}) do wires[#wires+1]=w end
  end
  observe("blueprint_wires",wires)
  check(#names==2 and names[1]=="nullius-grid-battery-1-supercapacitor" and names[2]=="power-switch",
    "hidden output must stay out of blueprints")
  check(#wires==2,"blueprint must keep only the player wire")
  check(cap_index~=nil,"supercapacitor missing from blueprint")
  blueprint.set_blueprint_entity_tags(cap_index,{meter={offered="signal-O",demand="signal-D"}})
  local ghosts=blueprint.build_blueprint{surface=storage.surface,force="player",position={3,46},raise_built=true}
  local ghost
  for _,g in pairs(ghosts) do if g.ghost_name=="nullius-grid-battery-1-supercapacitor" then ghost=g end end
  check(ghost~=nil,"supercapacitor ghost missing")
  observe("ghost_tags",ghost.tags or "nil")
  check(ghost.tags and ghost.tags.meter.offered=="signal-O","blueprint tags missing from ghost")
  ghost.revive{raise_revive=true}
  check(storage.observations.revive_tags.meter and storage.observations.revive_tags.meter.demand=="signal-D",
    "revive event lost ghost tags")
  inventory.destroy()
  local other=place("nullius-grid-battery-1",30.5,2.5,true)
  other.copy_settings(storage.cap,player)
  local control=other.get_control_behavior()
  observe("copied_control",{read_charge=control and control.read_charge,
    signal=control and control.output_signal and control.output_signal.name})
  check(storage.observations.paste_event and storage.observations.paste_event.destination=="nullius-grid-battery-1",
    "copy_settings by player must raise on_entity_settings_pasted")
  observe("panel_children",#player.gui.relative[PANEL].children)
  return "pre_reload"
end
local function output_state(row)
  local section=row.output.get_control_behavior().get_section(1)
  local filters={}
  for _,f in pairs(section.filters) do filters[#filters+1]={name=f.value.name,min=f.min} end
  return {enabled=row.output.get_control_behavior().enabled,filters=filters,
    output_red=signals(row.output,ids.circuit_red),switch_red=signals(storage.switch,ids.circuit_red),
    cap_red=signals(storage.cap,ids.circuit_red)}
end
-- Writes stop before the save, so post-load slots can only come from the save.
function stages.pre_reload(player)
  storage.suspended=true
  return "save"
end
function stages.save(player)
  local state=output_state(storage.meters[1])
  observe("saved_state",state)
  check(#state.filters==2 and state.switch_red["signal-O"]==state.filters[1].min and
    state.switch_red["signal-D"]==state.filters[2].min,"settled wire signals must match the slots")
  storage.snapshot=state
  storage.joins_before=storage.joins
  helpers.write_file("factorio-tests/multiplayer-action.json",helpers.table_to_json{id=1,action="reload"},false)
  return "reload"
end
function stages.reload(player)
  local peer=game.get_player("nullius-test-b")
  if storage.joins<storage.joins_before+2 or not (peer and peer.connected) then return "reload" end
  local state,saved=output_state(storage.meters[1]),storage.snapshot
  observe("reload_state",state)
  check(helpers.table_to_json(state.filters)==helpers.table_to_json(saved.filters),"combinator slots changed on reload")
  for _,name in ipairs({"signal-A","signal-O","signal-D"}) do
    check(state.switch_red[name]==saved.switch_red[name],name.." changed on reload")
  end
  local row=storage.meters[1]
  observe("reload",{output_valid=row.output.valid,cap_connections=connections(storage.cap),
    panel=player.gui.relative[PANEL]~=nil})
  check(row.output.valid and #connections(storage.cap)==3 and player.gui.relative[PANEL]~=nil,
    "meter wires or panel lost on reload")
  storage.suspended=false
  return "resumed"
end
function stages.resumed(player)
  local row,state=storage.meters[1],output_state(storage.meters[1])
  observe("resumed",{meter=row.last,filters=state.filters})
  check(state.filters[1].min==row.last.offered and state.filters[2].min==row.last.demand,"meter writes did not resume")
  helpers.write_file("factorio-tests/"..CASE..".json",helpers.table_to_json{schema=1,case=CASE,
    status="pass",failure_count=0,assertions=storage.assertions,tick=game.tick,
    factorio_version=script.active_mods.base,observations=storage.observations},false)
  return "done"
end
function stages.done() return "done" end

script.on_nth_tick(30,function()
  if game.tick==0 then return end
  local player=game.get_player("nullius-test-a")
  if not player or not player.connected then return end
  if not storage.suspended then
    for _,row in pairs(storage.meters) do write(row) end
  end
  storage.stage=stages[storage.stage](player)
end)

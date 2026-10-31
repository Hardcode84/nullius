-- given: a real client, Fulgora, full batteries, a 1 MW debug source and 100 kW
-- load, unlocked supercapacitors; no collectors or lightning.
-- place/connect: a production metered battery, a power switch, and circuit wires.
-- act: select/clear signals, switch mode, clone, blueprint/revive, copy settings,
-- rebuild, destroy and reload. Expect: one output per opt-in battery, preserved
-- settings and wires, native charge plus metered signals, no output on Nauvis.
local CASE='fulgora-grid-meter'
local REMOTE='nullius-test-grid-meter'
local PANEL='nullius_grid_meter'
local ids=defines.wire_connector_id
local function call(method,...) return remote.call(REMOTE,method,...) end
local function check(ok,message) storage.assertions=storage.assertions+1;assert(ok,message) end
local function place(name,x,y,extra)
  local args={name=name,position={x,y},force='player',raise_built=true}
  for k,v in pairs(extra or {}) do args[k]=v end
  return assert(storage.surface.create_entity(args),name)
end
local function settings(entity) return call('settings',entity) end
local function output(entity) return call('output',entity) end
local function signals(entity)
  local values={}
  local net=entity.get_circuit_network(ids.circuit_red)
  for _,v in pairs(net and net.signals or {}) do
    values[(v.signal.type or 'item')..':'..v.signal.name]=v.count
  end
  return values
end
local function choose(player,key,value)
  local frame=player.gui.relative[PANEL]
  check(frame~=nil,'meter panel missing')
  local element=frame[key]['nullius_grid_meter_'..key]
  element.elem_value=value
  call('changed',{player_index=player.index,element=element})
end
local function configure(entity)
  call('set',entity,{offered={type='virtual',name='signal-O'},demand={type='virtual',name='signal-D'}})
end
local function count() return storage.surface.count_entities_filtered{name='nullius-grid-meter-output'} end
script.on_init(function() storage.assertions=0;storage.stage='setup';storage.joins=0 end)
script.on_event(defines.events.on_player_joined_game,function() storage.joins=storage.joins+1 end)
local stages={}
function stages.setup(player)
  local s=game.planets['nullius-fulgora'].create_surface();storage.surface=s
  s.request_to_generate_chunks({0,0},3);s.force_generate_chunk_requests()
  for _,e in pairs(s.find_entities()) do e.destroy() end
  local tiles={}
  for x=-20,80 do for y=-20,60 do tiles[#tiles+1]={name='fulgoran-rock',position={x,y}} end end
  s.set_tiles(tiles,true)
  player.force.technologies['nullius-supercapacitors'].researched=true
  player.force.recipes['nullius-grid-battery-1'].enabled=true
  player.set_controller{type=defines.controllers.god};player.teleport({5,5},s)
  local pole=place('factorio-test-trip-pole',0,0,{raise_built=false})
  place('factorio-test-trip-source-1000000',-1,1,{raise_built=false})
  place('factorio-test-trip-load',-1,-1,{raise_built=false})
  local b=place('nullius-grid-battery-1',1.5,1.5);storage.battery=b
  b.energy=b.electric_buffer_size
  local control=b.get_or_create_control_behavior();control.read_charge=true
  control.output_signal={type='virtual',name='signal-A'}
  storage.switch=place('power-switch',5,0)
  b.get_wire_connector(ids.circuit_red,true).connect_to(storage.switch.get_wire_connector(ids.circuit_red,true))
  check(count()==0,'unconfigured battery has output')
  player.opened=b
  return 'configure'
end
function stages.configure(player)
  choose(player,'offered',{type='virtual',name='signal-O'})
  choose(player,'demand',{type='virtual',name='signal-D'})
  check(count()==1,'two pickers duplicated output')
  return 'read'
end
function stages.read(player)
  local v=signals(storage.switch)
  check(v['virtual:signal-O']==1000 and v['virtual:signal-D']==100 and v['virtual:signal-A']==100,'meter or charge values')
  choose(player,'offered',{type='fluid',name='nullius-water'})
  return 'fluid'
end
function stages.fluid(player)
  local v=signals(storage.switch)
  check(v['fluid:nullius-water']==1000 and not v['virtual:signal-O'],'stale output after picker change')
  choose(player,'offered',nil);choose(player,'demand',nil)
  check(count()==0 and output(storage.battery)==nil,'clearing signals left output')
  choose(player,'offered',{type='virtual',name='signal-O'})
  choose(player,'demand',{type='virtual',name='signal-D'})
  return 'mode'
end
function stages.mode(player)
  local old=output(storage.battery)
  check(remote.call('nullius-test-transitions','execute',storage.battery),'mode transition')
  storage.battery=storage.surface.find_entity('nullius-grid-battery-1-supercapacitor',{1.5,1.5})
  check(storage.battery and not old.valid and count()==1,'mode output lifecycle')
  check(settings(storage.battery).offered.name=='signal-O','mode lost settings')
  player.opened=storage.battery
  return 'mode_read'
end
function stages.mode_read(player)
  local v=signals(storage.switch)
  check(v['virtual:signal-O']==1000 and v['virtual:signal-D']~=nil and v['virtual:signal-A']~=nil,'mode lost script/player wires')
  check(player.gui.relative[PANEL].offered.nullius_grid_meter_offered.elem_value.name=='signal-O','mode picker state')
  storage.clone=storage.battery.clone{position={20.5,1.5},surface=storage.surface,force='player'}
  check(count()==2 and settings(storage.clone).demand.name=='signal-D','clone settings/output')
  storage.surface.clone_area{source_area={{0,0},{3,3}},destination_area={{30,0},{33,3}},
    destination_surface=storage.surface,clone_tiles=false,clone_entities=true,clone_decoratives=false,
    clear_destination_entities=true,expand_map=true}
  check(count()==3,'area clone copied an orphan output')
  local copy=place('nullius-grid-battery-1',40.5,1.5)
  copy.copy_settings(storage.battery,player)
  check(count()==4 and settings(copy).offered.name=='signal-O','settings paste between modes')
  call('set',storage.clone,{})
  copy.copy_settings(storage.clone,player)
  check(count()==2 and output(copy)==nil,'empty settings paste did not remove output')
  return 'blueprint'
end
function stages.blueprint(player)
  local inventory=game.create_inventory(1);inventory[1].set_stack{name='blueprint'}
  local bp=inventory[1]
  local mapping=bp.create_blueprint{surface=storage.surface,force='player',area={{0,0},{3,3}}}
  call('blueprint',bp,mapping)
  local entries=bp.get_blueprint_entities()
  check(#entries==1 and entries[1].name==storage.battery.name,'output leaked into blueprint')
  check(entries[1].tags.nullius_grid_meter.offered.name=='signal-O','missing blueprint tags')
  local ghosts=bp.build_blueprint{surface=storage.surface,force='player',position={50,10},raise_built=true}
  local g=ghosts[1]
  check(settings(g).demand.name=='signal-D','ghost lost meter settings')
  local _,revived=g.revive{raise_revive=true}
  check(revived and output(revived) and count()==3,'revive lost settings')
  storage.revived=revived
  inventory.destroy()
  local old=output(storage.battery)
  call('rebuild')
  check(not old.valid and count()==3 and settings(storage.battery).offered.name=='signal-O','configuration rebuild')
  storage.removed=output(storage.revived)
  storage.revived.destroy()
  return 'destroyed'
end
function stages.destroyed(player)
  check(not storage.removed.valid and count()==2,'script destruction left output')
  local other=game.surfaces.nauvis.create_entity{name='nullius-grid-battery-1',position={0,0},force='player',raise_built=true}
  configure(other)
  check(output(other)==nil,'meter outside Fulgora')
  player.opened=other
  return 'elsewhere'
end
function stages.elsewhere(player)
  check(player.gui.relative[PANEL]==nil,'meter panel outside Fulgora')
  player.opened=storage.battery
  storage.joins_before=storage.joins
  helpers.write_file('factorio-tests/multiplayer-action.json',helpers.table_to_json{id=1,action='reload'},false)
  return 'reload'
end
function stages.reload(player)
  if storage.joins<storage.joins_before+2 then return 'reload' end
  check(count()==2 and settings(storage.battery).offered.name=='signal-O','reload settings or outputs')
  local v=signals(storage.switch)
  check(v['virtual:signal-O']==1000 and v['virtual:signal-D']~=nil,'reload circuit output')
  check(player.gui.relative[PANEL]~=nil,'reload GUI')
  helpers.write_file('factorio-tests/'..CASE..'.json',helpers.table_to_json{schema=1,case=CASE,status='pass',
    failure_count=0,assertions=storage.assertions,tick=game.tick,factorio_version=script.active_mods.base},false)
  return 'done'
end
function stages.done() return 'done' end
script.on_nth_tick(60,function()
  if game.tick==0 then return end
  local player=game.get_player('nullius-test-a')
  if player and player.connected then storage.stage=stages[storage.stage](player) end
end)

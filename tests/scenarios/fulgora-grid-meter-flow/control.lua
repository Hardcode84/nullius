-- given: controlled 2 MW generation, 100 kW demand, full production battery.
-- place/connect: a registered pole and a metered battery, red and green outputs.
-- act: trip, remove generation, reset, move and destroy the battery.
-- expect: rounded flow, frozen readings offline, resumed flow after reset, no orphans.
local M='nullius-test-grid-meter'
local ids=defines.wire_connector_id
local function check(ok,msg) storage.assertions=storage.assertions+1;assert(ok,msg) end
local function readings()
  local output=remote.call(M,'output',storage.battery)
  local section=output.get_control_behavior().get_section(1)
  return section.get_slot(1).min,section.get_slot(2).min
end
script.on_init(function() storage.assertions=0 end)
script.on_nth_tick(1,function()
  if game.tick==0 then return end
  local tick=game.tick
  if tick==1 then
    local s=game.planets['nullius-fulgora'].create_surface();storage.surface=s
    s.request_to_generate_chunks({0,0},1);s.force_generate_chunk_requests()
    for _,e in pairs(s.find_entities()) do e.destroy() end
    local tiles={};for x=-10,10 do for y=-10,10 do tiles[#tiles+1]={name='fulgoran-rock',position={x,y}} end end
    s.set_tiles(tiles,true)
    local function place(name,x,y)
      return assert(s.create_entity{name=name,position={x,y},force='player',raise_built=true})
    end
    storage.pole=place('factorio-test-trip-pole',0,0)
    storage.source=place('factorio-test-trip-source-2000000',1,0)
    place('factorio-test-trip-load',1,1)
    storage.battery=place('nullius-grid-battery-1',-1.5,-1.5)
    storage.battery.energy=storage.battery.electric_buffer_size
    remote.call(M,'set',storage.battery,{offered={type='virtual',name='signal-O'},demand={type='virtual',name='signal-D'}})
  elseif tick==61 then
    local o,d=readings();check(o==2000 and d==100,'online meter flow')
    storage.offered=o;storage.demand=d
  elseif tick==121 then
    check(remote.call('nullius-test-overload','offline',storage.pole),'network did not trip')
    local o,d=readings();check(o==storage.offered and d==storage.demand,'offline meter changed')
    storage.source.destroy()
  elseif tick==151 then
    local o,d=readings();check(o==storage.offered and d==storage.demand,'offline meter read shutdown sink')
    remote.call('nullius-test-overload','reset',storage.pole,storage.pole.force)
  elseif tick==211 then
    local o=readings();check(o==0,'reset meter retained old offer')
    check(storage.battery.teleport({-2.5,-1.5}),'move battery')
  elseif tick==271 then
    local output=remote.call(M,'output',storage.battery)
    check(output.position.x==storage.battery.position.x,'meter output did not move')
    for _,id in ipairs({ids.circuit_red,ids.circuit_green}) do
      check(storage.battery.get_wire_connector(id,true).is_connected_to(output.get_wire_connector(id,true),defines.wire_origin.script),
        'moved meter wire lost')
    end
    storage.output=output;storage.battery.destroy()
  elseif tick==301 then
    check(not storage.output.valid,'destroyed meter left output')
    game.forces.player.technologies['nullius-supercapacitors'].researched=true
    for tier=1,3 do
      local name='nullius-grid-battery-'..tier
      game.forces.player.recipes[name].enabled=true
      local battery=assert(storage.surface.create_entity{name=name,position={tier*8,8},force='player',raise_built=true})
      remote.call(M,'set',battery,{offered={type='virtual',name='signal-O'}})
      check(remote.call(M,'output',battery)~=nil,'missing meter on tier '..tier)
      check(remote.call('nullius-test-transitions','execute',battery),'tier mode transition')
      battery=storage.surface.find_entity(name..'-supercapacitor',{tier*8,8})
      check(battery and remote.call(M,'output',battery)~=nil,'missing supercapacitor meter on tier '..tier)
      battery.destroy{raise_destroy=true}
    end
  elseif tick==302 then
    check(storage.surface.count_entities_filtered{name='nullius-grid-meter-output'}==0,'tier checks left orphan outputs')
    helpers.write_file('factorio-tests/fulgora-grid-meter-flow.json',helpers.table_to_json{schema=1,
      case='fulgora-grid-meter-flow',status='pass',failure_count=0,assertions=storage.assertions,
      tick=tick,factorio_version=script.active_mods.base},false)
    script.on_nth_tick(1,nil)
  end
end)

-- given: real multiplayer clients, a pole item and a blueprint, no power supply.
-- place: one player-built pole on Fulgora; blueprint its full footprint.
-- act: save/reload, build a second pole, and mine the first.
-- expect: helpers are absent from blueprints and persist once across reload.
local NAME='nullius-pole-lightning-collector'
local function check(ok,message) storage.assertions=storage.assertions+1; assert(ok,message) end
script.on_init(function() storage.stage='build'; storage.assertions=0; storage.joins=0 end)
script.on_event(defines.events.on_player_joined_game,function(e)
  if game.get_player(e.player_index).name=='nullius-test-a' then storage.joins=storage.joins+1 end
end)
script.on_nth_tick(30,function()
  local player=game.get_player('nullius-test-a')
  if not player or not player.connected then return end
  if storage.stage=='build' then
    local surface=game.planets['nullius-fulgora'].create_surface()
    storage.surface=surface
    surface.request_to_generate_chunks({0,0},1); surface.force_generate_chunk_requests()
    for _,e in pairs(surface.find_entities_filtered{area={{-8,-8},{8,8}}}) do e.destroy() end
    local tiles={}
    for x=-8,8 do for y=-8,8 do tiles[#tiles+1]={name='fulgoran-rock',position={x,y}} end end
    surface.set_tiles(tiles,true)
    player.set_controller{type=defines.controllers.god}; player.teleport({0,0},surface)
    player.cursor_stack.set_stack{name='small-electric-pole',count=1}
    player.build_from_cursor{position={0,0}}
    storage.pole=surface.find_entities_filtered{type='electric-pole',position={0,0},radius=1}[1]
    check(storage.pole~=nil,'player build failed')
    check(surface.count_entities_filtered{name=NAME}==1,'player build missing collector')
    player.cursor_stack.set_stack{name='blueprint',count=1}
    player.cursor_stack.create_blueprint{surface=surface,force=player.force,area={{-2,-2},{2,2}}}
    local entities=player.cursor_stack.get_blueprint_entities()
    check(#entities==1 and entities[1].name=='small-electric-pole','blueprint contains helper')
    storage.stage='reload'
    helpers.write_file('factorio-tests/multiplayer-action.json',helpers.table_to_json{id=1,action='reload'},false)
  elseif storage.stage=='reload' and storage.joins>=2 and game.get_player('nullius-test-b') and game.get_player('nullius-test-b').connected then
    check(storage.pole.valid,'pole lost on reload')
    check(storage.surface.count_entities_filtered{name=NAME}==1,'reload collector count')
    player.cursor_stack.build_blueprint{surface=storage.surface,force=player.force,position={4,0},by_player=player}
    local ghost=storage.surface.find_entities_filtered{type='entity-ghost'}[1]
    check(ghost and ghost.ghost_name=='small-electric-pole','blueprint pole ghost')
    local _,pole=ghost.revive{raise_revive=true}
    check(pole~=nil and storage.surface.count_entities_filtered{name=NAME}==2,'blueprint revival collector')
    check(player.mine_entity(storage.pole,true),'player mining failed')
    storage.stage='finish'
  elseif storage.stage=='finish' and game.tick>=1800 then
    check(storage.surface.count_entities_filtered{name=NAME}==1,'player mining orphan')
    helpers.write_file('factorio-tests/fulgora-pole-players.json',helpers.table_to_json{
      schema=1,case='fulgora-pole-players',status='pass',failure_count=0,
      assertions=storage.assertions,tick=game.tick,factorio_version=script.active_mods.base},false)
    script.on_nth_tick(30,nil)
  end
end)

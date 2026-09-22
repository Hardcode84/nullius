-- given: production graphics, footprints and speeds; void power, one plate each
-- place: all eight base assemblers on one surface
-- act/run: craft for 300 ticks after a real client joins
-- expect: one stick per machine; server and client results agree
script.on_init(function() storage.assertions=0 end)
script.on_event(defines.events.on_player_joined_game, function(event)
  local player=game.get_player(event.player_index)
  local surface=player.surface
  surface.request_to_generate_chunks({0,0},2);surface.force_generate_chunk_requests()
  for _,e in pairs(surface.find_entities_filtered{area={{-20,-20},{50,30}}}) do
    if e.type~="character" then e.destroy() end
  end
  local tiles={}
  for x=-20,50 do for y=-20,30 do tiles[#tiles+1]={name="grass-1",position={x,y}} end end
  surface.set_tiles(tiles)
  storage.machines={}
  for i,name in ipairs(names) do
    local entity=surface.create_entity{name=name,position={((i-1)%4)*9,math.floor((i-1)/4)*9},force=player.force}
    entity.set_recipe("graphics-craft")
    assert(entity.insert{name="iron-plate",count=1}==1)
    storage.machines[#storage.machines+1]=entity
  end
  player.teleport({13,4});player.zoom=0.8
  storage.start=game.tick
end)
script.on_nth_tick(60,function()
  if not storage.start or game.tick<storage.start+300 then return end
  for _,e in ipairs(storage.machines) do
    assert(e.products_finished==1,e.name.." craft count")
    assert(e.get_output_inventory().get_item_count("iron-stick")==1,e.name.." output")
    storage.assertions=storage.assertions+2
  end
  helpers.write_file("factorio-tests/assembler-graphics.json",helpers.table_to_json{
    case="assembler-graphics",status="pass",assertions=storage.assertions,tick=game.tick,
  },false)
  script.on_nth_tick(60,nil)
end)

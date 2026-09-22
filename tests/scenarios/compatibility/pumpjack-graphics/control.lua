-- given: production graphics and speeds, void power; 10000 resource units per drill
-- place: eight well and extractor definitions in all four directions
-- connect: one pipe at each machine output
-- act/run: produce water for 300 ticks after a real client joins
-- expect: all 32 machines retain direction and produce water; peers agree
local fluid_api=require("__nullius-star__/scenarios/fluid-api")
script.on_init(function() storage.assertions=0 end)
script.on_event(defines.events.on_player_joined_game,function(event)
  local player=game.get_player(event.player_index)
  local surface=player.surface
  surface.request_to_generate_chunks({15,35},3);surface.force_generate_chunk_requests()
  for _,e in pairs(surface.find_entities_filtered{area={{-20,-20},{50,90}}}) do
    if e.type~="character" then e.destroy() end
  end
  local tiles={}
  for x=-20,50 do for y=-20,90 do tiles[#tiles+1]={name="grass-1",position={x,y}} end end
  surface.set_tiles(tiles)
  storage.machines={}
  for i,name in ipairs(names) do
    for j,direction in ipairs({defines.direction.north,defines.direction.east,
                              defines.direction.south,defines.direction.west}) do
      local position={(j-1)*9,(i-1)*10}
      if prototypes.entity[name].type=="mining-drill" then
        assert(surface.create_entity{name="graphics-resource",position=position,amount=10000})
      end
      local entity=assert(surface.create_entity{name=name,position=position,direction=direction,force=player.force})
      if entity.type=="assembling-machine" then
        entity.set_recipe("graphics-water")
        assert(entity.get_recipe() and entity.get_recipe().name=="graphics-water",name.." recipe")
        assert(fluid_api.count(entity)==1,name.." output port count: "..fluid_api.count(entity))
      end
      local collector
      do
        local offsets=entity.type=="assembling-machine" and {{1,-2},{2,-1},{-1,2},{-2,1}}
          or {{1.5,-2.5},{2.5,-1.5},{-1.5,2.5},{-2.5,1.5}}
        local offset=offsets[j]
        collector=assert(surface.create_entity{name="pipe",force=player.force,
          position={position[1]+offset[1],position[2]+offset[2]}})
      end
      assert(entity.direction==direction,name.." direction")
      storage.assertions=storage.assertions+1
      storage.machines[#storage.machines+1]={entity=entity,collector=collector}
    end
  end
  player.teleport({13,35});player.zoom=0.3
  storage.start=game.tick
end)
script.on_nth_tick(60,function()
  if not storage.start or game.tick<storage.start+300 then return end
  for _,row in ipairs(storage.machines) do
    local entity=row.entity
    local status_name
    for name,value in pairs(defines.entity_status) do
      if value==entity.status then status_name=name;break end
    end
    local fluid=fluid_api.get(entity,1)
    local contents=row.collector and fluid_api.segment_contents(row.collector,1) or {}
    local amount=(contents.water or 0)+(fluid and fluid.name=="water" and fluid.amount or 0)
    assert(amount>0,entity.name.." water output; status="..
      status_name.."; fluids="..helpers.table_to_json(entity.get_fluid_contents())..
      (entity.type=="assembling-machine" and ("; crafts="..entity.products_finished..
        "; progress="..entity.crafting_progress.."; recipe="..helpers.table_to_json(entity.get_recipe().products)) or ""))
    storage.assertions=storage.assertions+1
  end
  helpers.write_file("factorio-tests/pumpjack-graphics.json",helpers.table_to_json{
    case="pumpjack-graphics",status="pass",assertions=storage.assertions,tick=game.tick,
  },false)
  script.on_nth_tick(60,nil)
end)

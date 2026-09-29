-- given: unlocked overcharged/thermal modes, every nonterminal variant, ordinary
-- upgrade items, ten construction robots per cell and unlimited debug electricity.
-- place/connect: separate Nauvis robot cells; set compatible recipes without inputs.
-- act: default upgrade planner, then explicit reverse mappings with returned items.
-- run: real robot jobs for 1800 ticks per direction.
-- expect: every tier preserves its mode, recipe and direction, using ordinary items.
local function check(ok,message) storage.assertions=storage.assertions+1;assert(ok,message) end
local function recipe(name)
  if name:find('-overcharged$',1) then return 'nullius-mechanical-pack' end
  if name:find('crusher',1,true) then return 'nullius-crushed-limestone' end
  if name:find('foundry',1,true) then return 'nullius-iron-plate' end
  if name:find('nanofabricator',1,true) then return 'nullius-monocrystalline-silicon' end
  if name:find('large-furnace',1,true) then return 'nullius-boxed-hard-glass' end
  return 'nullius-aluminum-ingot'
end
local function mark(row,planner,target)
  storage.surface.upgrade_area{area={{row.x-6,row.y-6},{row.x+6,row.y+6}},force='player',item=planner}
  local marked=row.entity.get_upgrade_target()
  check(marked and marked.name==target,'planner target for '..row.entity.name..': '..(marked and marked.name or 'nil')..', expected '..target)
end
script.on_nth_tick(1,function()
  if game.tick==0 then return end
  script.on_nth_tick(1,nil)
  if storage.surface then storage.observations.reload_tick=game.tick;return end
  storage.assertions=0;storage.rows={};storage.observations={overcharged=0,thermal=0}
  local surface=game.surfaces.nauvis;storage.surface=surface
  local force=game.forces.player
  for _,name in ipairs({'nullius-overcharged-assembly-2','nullius-overcharged-assembly-3',
      'nullius-pneumatic-technology','nullius-thermal-engineering-2','nullius-thermal-engineering-3'}) do
    force.technologies[name].researched=true
  end
  local sources={}
  for name,prototype in pairs(prototypes.entity) do
    if prototype.next_upgrade and (name:find('-overcharged$') or name:find('-thermal$')) then sources[#sources+1]=name end
  end
  table.sort(sources)
  storage.planners=game.create_inventory(#sources+1)
  storage.planners[1].set_stack{name='upgrade-planner'}
  for index,name in ipairs(sources) do
    local x=((index-1)%4)*80;local y=math.floor((index-1)/4)*80
    surface.request_to_generate_chunks({x,y},2);surface.force_generate_chunk_requests()
    for _,e in pairs(surface.find_entities_filtered{area={{x-20,y-20},{x+35,y+35}}}) do e.destroy() end
    local tiles={};for dx=-20,35 do for dy=-20,35 do tiles[#tiles+1]={name='landfill',position={x+dx,y+dy}} end end
    surface.set_tiles(tiles,true)
    local source=prototypes.entity[name];local target=source.next_upgrade
    local source_item=source.items_to_place_this[1].name
    local target_item=target.items_to_place_this[1].name
    force.recipes[source_item].enabled=true;force.recipes[target_item].enabled=true
    local function place(n,dx,dy,raised)
      return assert(surface.create_entity{name=n,position={x+dx,y+dy},force=force,raise_built=raised})
    end
    local entity=place(name,0,0,true)
    local selected=recipe(name);force.recipes[selected].enabled=true;entity.set_recipe(selected)
    check(entity.get_recipe() and entity.get_recipe().name==selected,'source recipe rejected '..name)
    local port=place('roboport',14,0,false);port.insert{name='construction-robot',count=10}
    local chest=place('storage-chest',14,5,false);chest.insert{name=target_item,count=1}
    local grid=place('factorio-test-planner-grid',16,8,false)
    grid.power_production=1000000000;grid.electric_buffer_size=1000000000
    place('substation',10,8,false)
    local row={x=x,y=y,entity=entity,source=name,target=target.name,source_item=source_item,
      target_item=target_item,chest=chest,recipe=selected,direction=entity.direction}
    storage.rows[#storage.rows+1]=row
    local family=name:find('-overcharged$') and 'overcharged' or 'thermal'
    storage.observations[family]=storage.observations[family]+1
    mark(row,storage.planners[1],row.target)
  end
  check(storage.observations.overcharged==5,'overcharged tier coverage changed')
  check(storage.observations.thermal==10,'thermal tier coverage changed')
end)
script.on_nth_tick(1800,function()
  if game.tick==0 then return end
  for index,row in ipairs(storage.rows) do
    local expected=game.tick==1800 and row.target or row.source
    local entity=storage.surface.find_entity(expected,{row.x,row.y})
    check(entity~=nil,'robot replacement missing '..expected)
    check(not row.entity.valid,'old variant survived upgrade')
    check(entity.get_recipe() and entity.get_recipe().name==row.recipe,'upgrade lost recipe '..expected)
    check(entity.direction==row.direction,'upgrade changed direction '..expected)
    check(entity.prototype.items_to_place_this[1].name==(game.tick==1800 and row.target_item or row.source_item),'variant item changed')
    row.entity=entity
    if game.tick==1800 then
      local planner=storage.planners[index+1];planner.set_stack{name='upgrade-planner'}
      planner.set_mapper(1,'from',{type='entity',name=row.target})
      planner.set_mapper(1,'to',{type='entity',name=row.source})
      mark(row,planner,row.source)
    end
  end
  if game.tick==3600 then
    helpers.write_file('factorio-tests/variant-robot-upgrades.json',helpers.table_to_json{
      schema=1,case='variant-robot-upgrades',status='pass',failure_count=0,assertions=storage.assertions,
      tick=game.tick,factorio_version=script.active_mods.base,observations=storage.observations},false)
    script.on_nth_tick(1800,nil)
  end
end)

-- given: three coil tiers, ten construction robots, one stocked storage chest,
-- unlimited debug electricity, and one declared ingredient batch for each new recipe.
-- place/connect: Fulgora sand coils, island roboport and assemblers; no ambient strikes.
-- act: default upgrade planner 1->2->3, custom downgrade 3->1, fast replace and mine.
-- run: native construction jobs and recipes; check spacing after each replacement.
-- expect: research unlocks, full sink demand, no boxed variants, exactly four spacing fields.
local names=require('__nullius-star__/shared/grounding-coils')
local input=require('__nullius-star__/scenarios/inventory-api').crafting_input
local function check(ok,msg) storage.assertions=storage.assertions+1;assert(ok,msg) end
local function place(name,x,y,raised)
  return assert(storage.surface.create_entity{name=name,position={x,y},force='player',raise_built=raised})
end
local function fields(x,y)
  return storage.surface.count_entities_filtered{name={'nullius-grounding-collision-horizontal','nullius-grounding-collision-vertical'},
    area={{x-32,y-32},{x+32,y+32}}}
end
local function spacing(tier)
  check(fields(0,0)==4,'duplicate or missing fields after upgrade '..tier)
  for _,name in ipairs(names) do
    check(not storage.surface.can_place_entity{name=name,position={16,0},force='player'},'mixed tier spacing')
    check(storage.surface.can_place_entity{name=name,position={32,0},force='player'},'spacing boundary')
    check(not storage.surface.can_place_entity{name=name,position={50,0},force='player'},'island placement')
  end
end
local function upgrade(target)
  storage.surface.upgrade_area{area={{-2,-2},{2,2}},force='player',item=storage.inventory[1]}
  local coil=storage.surface.find_entity(names[storage.tier],{0,0})
  local marked=coil.get_upgrade_target()
  check(marked and marked.name==names[target],'planner target mismatch')
end
script.on_nth_tick(1,function()
  if game.tick==0 then return end
  script.on_nth_tick(1,nil)
  if storage.surface then storage.observations.reload_tick=game.tick;return end
  storage.assertions=0;storage.tier=1;storage.observations={}
  local s=game.planets['nullius-fulgora'].create_surface();storage.surface=s
  s.request_to_generate_chunks({150,0},7);s.force_generate_chunk_requests()
  for _,e in pairs(s.find_entities()) do e.destroy() end
  local tiles={}
  for x=-40,350 do for y=-40,40 do
    tiles[#tiles+1]={name=(x>=6 and x<24 or x>=40) and 'fulgoran-rock' or 'nullius-fulgora-sediment',position={x,y}}
  end end
  s.set_tiles(tiles,true)
  for tier,name in ipairs(names) do
    check(not prototypes.item['nullius-box-'..name:sub(9)],'boxed item exists')
    for _,prefix in ipairs({'nullius-box-','nullius-unbox-','nullius-boxed-'}) do
      check(not prototypes.recipe[prefix..name:sub(9)],'boxed recipe exists')
    end
    if tier>1 then
      check(not game.forces.player.recipes[name].enabled,'recipe unlocked before research')
      game.forces.player.technologies['nullius-grounding-coils-'..tier].researched=true
      check(game.forces.player.recipes[name].enabled,'research failed to unlock recipe')
    end
  end
  place(names[1],0,0,true);spacing(1)
  local port=place('roboport',10,0,false);port.insert{name='construction-robot',count=10}
  storage.chest=place('storage-chest',14,0,false)
  for tier=2,3 do storage.chest.insert{name=names[tier],count=1} end
  local grid=place('factorio-test-planner-grid',16,4,false)
  grid.power_production=1000000000;grid.electric_buffer_size=1000000000
  storage.pole=place('substation',10,6,false)
  storage.inventory=game.create_inventory(1);storage.inventory[1].set_stack{name='upgrade-planner'}
  storage.assemblers={}
  for tier=2,3 do
    local x=100*tier
    local machine=place(tier==2 and 'nullius-medium-assembler-2' or 'nullius-large-assembler-2',x,0,false)
    check(machine.set_recipe(names[tier])~=false,'recipe executor rejected')
    local ingredients={{names[tier-1],1},{'nullius-aluminum-wire',tier==2 and 80 or 160},
      {'nullius-steel-plate',tier==2 and 40 or 80},{tier==2 and 'nullius-glass' or 'nullius-insulation',tier==2 and 20 or 40}}
    for _,stack in ipairs(ingredients) do
      check(machine.get_inventory(input).insert{name=stack[1],count=stack[2]}==stack[2],'recipe stock did not fit')
    end
    local source=place('factorio-test-planner-grid',x+8,0,false)
    source.power_production=1000000000;source.electric_buffer_size=1000000000
    place('substation',x+4,6,false)
    storage.assemblers[#storage.assemblers+1]=machine
  end
  upgrade(2)
end)
script.on_nth_tick(30,function()
  if game.tick==0 then return end
  if game.tick==1800 or game.tick==3600 then
    local tier=game.tick==1800 and 2 or 3
    local coil=storage.surface.find_entity(names[tier],{0,0})
    check(coil~=nil,'robot upgrade incomplete: '..tier)
    spacing(tier);storage.tier=tier
    local flow=storage.pole.electric_network.parent_network.flow_last_tick
    check(flow.tertiary_demand*60>=400e6*4^(tier-1)-1,'coil demand limited by buffer')
    for _,machine in ipairs(storage.assemblers) do check(machine.products_finished==1,'recipe not crafted') end
    if tier==2 then upgrade(3) else
      storage.inventory[1].set_mapper(1,'from',{type='entity',name=names[3]})
      storage.inventory[1].set_mapper(1,'to',{type='entity',name=names[1]})
      upgrade(1)
    end
  elseif game.tick==5400 then
    check(storage.surface.find_entity(names[1],{0,0})~=nil,'robot downgrade incomplete')
    spacing(1)
    check(storage.surface.can_fast_replace{name=names[3],position={0,0},force='player'},'fast replace unavailable')
    local coil=assert(storage.surface.create_entity{name=names[3],position={0,0},force='player',fast_replace=true,spill=false,raise_built=true})
    storage.replacement=coil
  elseif game.tick==5430 then
    spacing(3)
    local inv=game.create_inventory(2)
    check(storage.replacement.mine{inventory=inv,raise_destroyed=true},'mining upgraded coil')
    check(inv.get_item_count(names[3])==1,'mining returned wrong tier')
  elseif game.tick==5460 then
    check(fields(0,0)==0,'orphan spacing fields')
    check(storage.surface.can_place_entity{name=names[2],position={0,0},force='player'},'space not released')
    helpers.write_file('factorio-tests/fulgora-coil-upgrades.json',helpers.table_to_json{
      schema=1,case='fulgora-coil-upgrades',status='pass',failure_count=0,assertions=storage.assertions,
      tick=game.tick,factorio_version=script.active_mods.base,observations=storage.observations},false)
    script.on_nth_tick(30,nil)
  end
end)

-- given: fixed planet terrain and RNG seeds; optional grass, water, walls, worms,
--        ore, or fumaroles declared in the experiment contract; no drone source
-- place/connect: native terrain and collision entities; no factory inputs
-- act: run exact and interpolated production effect bodies against identical worlds
-- run: count climate queries separately from three uninstrumented timing samples
-- expect: instrumentation preserves forests; report semantic differences explicitly
require('__nullius-star__/scripts/landfill')
require('__nullius-star__/scripts/drone')
local contract=require('contract')
local factories={baseline=require('baseline'),upstream=require('upstream')}
local assertions=0
local function check(ok,message)
  assertions=assertions+1
  assert(ok,message)
end
local function snapshot(surface)
  local trees={}
  for _,tree in pairs(surface.find_entities_filtered{type='tree'}) do
    trees[#trees+1]={name=tree.name,x=tree.position.x,y=tree.position.y}
  end
  table.sort(trees,function(a,b)
    if a.x~=b.x then return a.x<b.x end
    if a.y~=b.y then return a.y<b.y end
    return a.name<b.name
  end)
  return trees
end
local function same(a,b)
  if #a~=#b then return false end
  for i,t in ipairs(a) do
    if t.name~=b[i].name or t.x~=b[i].x or t.y~=b[i].y then return false end
  end
  return true
end
local function key(t) return string.format('%.8f,%.8f',t.x,t.y) end
local function difference(a,b)
  local before,after={},{}
  for _,t in ipairs(a) do before[key(t)]=t.name end
  for _,t in ipairs(b) do after[key(t)]=t.name end
  local changed_species,removed,added=0,0,0
  for p,name in pairs(before) do
    if not after[p] then removed=removed+1
    elseif after[p]~=name then changed_species=changed_species+1 end
  end
  for p in pairs(after) do if not before[p] then added=added+1 end end
  return {changed=not same(a,b),changed_species=changed_species,removed_positions=removed,added_positions=added}
end
local function fixture(case,index)
  local planet=game.planets[case.planet]
  local native=planet.create_surface()
  local settings=native.map_gen_settings
  settings.seed=contract.map_seed
  local source=game.create_surface('arboriculture-source-'..index,settings)
  local target=game.create_surface('arboriculture-target-'..index,settings)
  for name in pairs(prototypes.surface_property) do
    source.set_property(name,native.get_property(name))
    target.set_property(name,native.get_property(name))
  end
  local x,y=case.center[1],case.center[2]
  source.request_to_generate_chunks({x,y},4);source.force_generate_chunk_requests()
  local area={{x-128,y-128},{x+128,y+128}}
  if case.tile then
    for _,entity in pairs(source.find_entities_filtered{area=area}) do entity.destroy() end
    source.destroy_decoratives{area=area}
    local tiles={}
    for tx=x-128,x+127 do for ty=y-128,y+127 do
      tiles[#tiles+1]={name=case.tile,position={tx,ty}}
    end end
    source.set_tiles(tiles,true)
  end
  if case.obstacles then
    for i=1,8 do check(source.create_entity{name='small-worm-turret',position={x+i*5-20,y+40},force='enemy'}~=nil,'worm placement') end
    for i=1,20 do check(source.create_entity{name='stone-wall',position={x+i*2-20,y},force='player'}~=nil,'wall placement') end
    for tx=-3,3 do for ty=-3,3 do
      check(source.create_entity{name='iron-ore',position={x+tx,y+ty+15},amount=1000}~=nil,'ore placement')
    end end
  end
  for i=1,(case.fumaroles or 0) do
    check(source.create_entity{name='nullius-fumarole',position={x+(i%5)*10-20,y+math.floor(i/5)*10-20},amount=100000}~=nil,'fumarole placement')
  end
  local function reset()
    source.clone_area{source_area=area,destination_area=area,destination_surface=target,
      clone_tiles=true,clone_entities=true,clone_decoratives=true,
      clear_destination_entities=true,clear_destination_decoratives=true,expand_map=true}
  end
  return source,target,reset
end
script.on_nth_tick(1,function()
  if game.tick==0 then return end
  script.on_nth_tick(1,nil)
  local report={schema=1,factorio_version=script.active_mods.base,rows={}}
  local streams={}
  for _,seed in ipairs(contract.random_seeds) do
    local rng=game.create_random_generator(seed)
    local prefix={rng(),rng(),rng(),rng()}
    local signature=helpers.table_to_json(prefix)
    check(not streams[signature], 'experiment seeds share a random stream')
    streams[signature]=true
  end
  for index,case in ipairs(contract.cases) do
    local source,target,reset=fixture(case,index)
    local event={surface_index=target.index,target_position={x=case.center[1],y=case.center[2]}}
    for _,seed in ipairs(contract.random_seeds) do
      local row={case=case.name,seed=seed}
      for _,variant in ipairs({'baseline','upstream'}) do
        reset()
        local metrics={queries=0,sampled_positions=0,random_calls=0}
        local proxy=setmetatable({calculate_tile_properties=function(names,positions)
          metrics.queries=metrics.queries+1
          metrics.sampled_positions=metrics.sampled_positions+#positions
          return target.calculate_tile_properties(names,positions)
        end},{__index=function(_,name) return target[name] end})
        local rng=game.create_random_generator(seed)
        local run=factories[variant](proxy,function() metrics.random_calls=metrics.random_calls+1;return rng() end)
        run(event)
        metrics.trees=snapshot(target)
        row[variant]=metrics
      end
      row.difference=difference(row.baseline.trees,row.upstream.trees)
      report.rows[#report.rows+1]=row
      for repetition=1,contract.repetitions do
        local order=repetition%2==0 and {'upstream','baseline'} or {'baseline','upstream'}
        for _,variant in ipairs(order) do
          reset()
          local run=factories[variant](target,game.create_random_generator(seed))
          local profiler=helpers.create_profiler()
          run(event)
          profiler.stop()
          log({'','ARB_TIME ',#report.rows,' ',variant,' ',repetition,' ',profiler})
          check(same(snapshot(target),row[variant].trees),case.name..' '..variant..' instrumentation changed output')
        end
      end
    end
    game.delete_surface(source)
    game.delete_surface(target)
  end
  report.assertions=assertions
  helpers.write_file('arboriculture.json',helpers.table_to_json(report),false)
end)

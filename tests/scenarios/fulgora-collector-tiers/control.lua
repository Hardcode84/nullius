-- given: ten pole tiers, native 1 GJ and test 1 MJ lightning, no ambient storms, 800 MW debug loads.
-- place/connect: isolated production poles, with one native load per network.
-- act: strike outside and inside collection reach; upgrade and downgrade charged poles.
-- run: three seconds of native discharge.
-- expect: tier-specific capture/output, two-second buffers, charge retained on replacement.
local config=require('__nullius-star__/shared/fulgora-collectors')
local cases={
  {'small-electric-pole',1,10}, {'medium-electric-pole',2,10},
  {'nullius-power-pole-3',3,10}, {'nullius-power-pole-4',4,10},
  {'big-electric-pole',1,30}, {'nullius-pylon-2',2,30}, {'nullius-pylon-3',3,30},
  {'substation',1,20}, {'nullius-substation-2',2,20}, {'nullius-substation-3',3,20},
}
local function check(ok,message) storage.assertions=storage.assertions+1;assert(ok,message) end
local function near(a,b,message) check(math.abs(a-b)<0.001,message..': '..a..' != '..b) end
local function helper(pole)
  local list=pole.surface.find_entities_filtered{name=config.names,position=pole.position,radius=0.1}
  check(#list==1,'collector count for '..pole.name)
  return list[1]
end
local function strike(row,offset)
  storage.surface.execute_lightning{name='nullius-fulgora-lightning',position={row.x+offset,0}}
end
script.on_nth_tick(1,function()
  local tick=game.tick
  if tick==0 then return end
  if tick==1 then
    storage.assertions=0;storage.rows={}
    local s=game.planets['nullius-fulgora'].create_surface();storage.surface=s
    for index,case in ipairs(cases) do
      local x=(index-1)*100
      s.request_to_generate_chunks({x,0},2);s.force_generate_chunk_requests()
      for _,entity in pairs(s.find_entities_filtered{area={{x-40,-40},{x+40,40}}}) do entity.destroy() end
      local tiles={};for dx=-40,40 do for y=-40,40 do tiles[#tiles+1]={name='fulgoran-rock',position={x+dx,y}} end end
      s.set_tiles(tiles,true)
      local pole=assert(s.create_entity{name=case[1],position={x,0},force='player',raise_built=true})
      local collector=helper(pole)
      local source=collector.prototype.electric_energy_source_prototype
      near(source.buffer_capacity,case[2]*200e6,'buffer '..case[1])
      near(source.get_output_flow_limit()*60,case[2]*100e6,'output '..case[1])
      near(source.buffer_capacity/source.get_output_flow_limit(),120,'discharge ticks')
      local row={pole=pole,collector=collector,x=x,tier=case[2],reach=case[3]}
      storage.rows[#storage.rows+1]=row
      strike(row,row.reach+2)
    end
  elseif tick==10 then
    for _,row in ipairs(storage.rows) do
      near(row.collector.energy,0,'captured outside reach '..row.pole.name)
      strike(row,row.reach-1)
    end
  elseif tick==20 then
    for _,row in ipairs(storage.rows) do
      near(row.collector.energy,row.tier*200e6,'native capture '..row.pole.name)
      row.load=assert(storage.surface.create_entity{name='factorio-test-power-dump-800',
        position={row.x+1,1},force='player'})
    end
  elseif tick==60 then
    for _,row in ipairs(storage.rows) do
      local flow=row.pole.electric_network.parent_network.flow_last_tick
      near(flow.primary_output*60,row.tier*100e6,'native output '..row.pole.name)
    end
  elseif tick==180 then
    for _,row in ipairs(storage.rows) do
      near(row.collector.energy,0,'buffer not exhausted '..row.pole.name)
      check(storage.surface.count_entities_filtered{name='nullius-fulgora-overload-sink',position=row.pole.position,radius=1}==0,'loaded network tripped')
      row.load.destroy()
    end
    for _,row in ipairs(storage.rows) do
      storage.surface.execute_lightning{name='factorio-test-lightning',position=row.pole.position}
    end
  elseif tick==190 then
    for _,row in ipairs(storage.rows) do
      near(row.collector.energy,row.tier*200000,'conversion without capacity clipping '..row.pole.name)
    end
    strike(storage.rows[1],0);strike(storage.rows[2],0)
  elseif tick==200 then
    for index,name in ipairs({'medium-electric-pole','small-electric-pole'}) do
      local row=storage.rows[index]
      local energy=row.collector.energy
      near(energy,index*200e6,'replacement initial energy')
      row.pole=assert(storage.surface.create_entity{name=name,position={row.x,0},force='player',
        fast_replace=true,spill=false,raise_built=true})
      check(not row.collector.valid,'old collector survived replacement')
      row.collector=helper(row.pole)
      near(row.collector.energy,math.min(energy,(3-index)*200e6),'replacement charge')
    end
  elseif tick==201 then
    for _,row in ipairs(storage.rows) do check(helper(row.pole)==row.collector,'destroy event replaced new collector') end
    helpers.write_file('factorio-tests/fulgora-collector-tiers.json',helpers.table_to_json{
      schema=1,case='fulgora-collector-tiers',status='pass',failure_count=0,assertions=storage.assertions,
      tick=tick,factorio_version=script.active_mods.base},false)
    script.on_nth_tick(1,nil)
  end
end)

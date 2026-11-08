-- given: one batch of each recording set; finite almost-expired media for spoilage.
-- place/connect: production correlators on ground and platform, declared electric grids.
-- act/run: correlate all seven sets and wait through the supplied spoil remainder.
-- expect: native pack yields, every blank returned, fixed lifetime and cargo weight.
local CASE='astronomy-correlation'
local spec=require('__nullius-star__/shared/astronomy')
local function check(ok,msg) storage.assertions=storage.assertions+1;assert(ok,msg) end
script.on_init(function()
 storage.assertions=0;storage.rows={}
 local force=game.forces.player;force.technologies['nullius-astronomy'].researched=true
 local ground=game.surfaces.nauvis
 ground.request_to_generate_chunks({0,0},4);ground.force_generate_chunk_requests()
 for _,e in pairs(ground.find_entities_filtered{area={{-10,-10},{150,20}}}) do e.destroy() end
 local tiles={};for x=-10,150 do for y=-10,20 do tiles[#tiles+1]={name='grass-1',position={x,y}} end end
 ground.set_tiles(tiles)
 local platform=assert(force.create_space_platform{name=CASE,planet='nauvis',starter_pack='space-platform-starter-pack'})
 platform.apply_starter_pack(true)
 local tiles={};for x=-10,150 do for y=12,32 do tiles[#tiles+1]={name='space-platform-foundation',position={x,y}} end end
 platform.surface.set_tiles(tiles)
 for i,set in ipairs(spec.sets()) do
  local surface=#set==1 and ground or platform.surface
  local x=(i-1)*20;local y=#set==1 and 0 or 20
  local e=assert(surface.create_entity{name='nullius-correlator',position={x,y},force=force})
  local name='nullius-correlate-'..table.concat(set,'-')
  check(force.recipes[name].enabled,'all correlations visible at Astronomy')
  e.set_recipe(name)
  local count=#set==1 and 20 or 10
  for _,planet in ipairs(set) do check(e.insert{name=spec.recording(planet),count=count}==count,'finite recordings') end
  local grid=assert(surface.create_entity{name='factorio-test-planner-grid',position={x+7,y},force=force})
  grid.power_production=10000000;grid.electric_buffer_size=10000000
  assert(surface.create_entity{name='substation',position={x+4,y+4},force=force})
  storage.rows[#storage.rows+1]={entity=e,packs=#set==1 and 1 or 10*#set*(#set-1)/2,blanks=count*#set}
  check(prototypes.recipe[name].maximum_productivity==0,'no correlation productivity')
 end
 local inventory=game.create_inventory(3);storage.spoiling=inventory
 for i,planet in ipairs(spec.planets) do
  local name=spec.recording(planet);local p=prototypes.item[name]
  check(p.get_spoil_ticks()==spec.spoil_ticks,'prototype lifetime')
  check(p.weight==1000 and p.stack_size==50,'recording cargo')
  inventory[i].set_stack{name=name,count=1};inventory[i].spoil_percent=1-300/p.get_spoil_ticks()
 end
 for _,name in ipairs{'nullius-satellite','nullius-probe','nullius-align-concordance-satellite'} do
  check(#prototypes.item[name].rocket_launch_products==0,'removed launch science '..name)
 end
end)
script.on_nth_tick(660,function()
 if game.tick==0 then return end
 for _,row in ipairs(storage.rows) do
  check(row.entity.products_finished==1,'one correlation craft')
  local out=row.entity.get_output_inventory()
  check(out.get_item_count('nullius-astronomy-pack')==row.packs,'native science yield')
  check(out.get_item_count('nullius-blank-recording-module')==row.blanks,'all blanks returned')
 end
 check(storage.spoiling.get_item_count('nullius-blank-recording-module')==3,'all recordings spoil to blanks')
 storage.spoiling.destroy()
 helpers.write_file('factorio-tests/'..CASE..'.json',helpers.table_to_json{schema=1,case=CASE,status='pass',tick=game.tick,
  failure_count=0,assertions=storage.assertions,factorio_version=script.active_mods.base},false)
 script.on_nth_tick(660,nil)
end)

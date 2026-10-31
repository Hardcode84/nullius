-- given: declared rails, labs, resource deposits, debug power, and a native upgrade planner.
-- place/connect: each lab wired to its own pole; stock on separate rails.
-- act/run: select research and read its cost after 59 ticks.
-- expect: circuit output, blueprint wires, correct upgrade targets and resource restrictions.
local CASE = "upstream-prototype-ports"
local function check(ok,msg) storage.assertions=storage.assertions+1; assert(ok,msg) end
local function expanded(entries)
  local out={}
  for _,entry in pairs(entries) do
    check(entry.amount and (not entry.probability or entry.probability==1),"exact recipe amount")
    local unbox=entry.name:match("^nullius%-box%-(.+)$")
    local recipe=unbox and prototypes.recipe["nullius-unbox-"..unbox]
    if recipe then
      check(#recipe.ingredients==1 and #recipe.products==1,"one unboxing input and output")
      local product=recipe.products[1]
      out[product.name]=(out[product.name] or 0)+entry.amount*product.amount/recipe.ingredients[1].amount
    else out[entry.name]=(out[entry.name] or 0)+entry.amount end
  end
  return out
end
local function parity(base,bulk)
  local a,b=prototypes.recipe[base],prototypes.recipe[bulk]
  check(a and b,base.." pair exists")
  check(b.energy==a.energy*5,bulk.." duration")
  for _,field in ipairs{"ingredients","products"} do
    local x,y=expanded(a[field]),expanded(b[field])
    for name,n in pairs(x) do check(y[name]==n*5,bulk.." "..field.." "..name) end
    for name in pairs(y) do check(x[name]~=nil,bulk.." unexpected "..name) end
  end
end
script.on_nth_tick(1,function()
  script.on_nth_tick(1,nil)
  storage.assertions=0
  local s=game.surfaces.nauvis
  s.request_to_generate_chunks({0,0},3);s.force_generate_chunk_requests()
  for _,e in pairs(s.find_entities_filtered{area={{-64,-64},{64,64}}}) do e.destroy() end
  local tiles={}
  for x=-64,64 do for y=-64,64 do tiles[#tiles+1]={name="landfill",position={x,y}} end end
  s.set_tiles(tiles,true)
  for _,pair in ipairs{
    {"nullius-chemical-pack","nullius-boxed-chemical-pack"},
    {"nullius-thermite","nullius-boxed-thermite"},
    {"nullius-motor-2","nullius-boxed-motor-2"},
    {"nullius-heat-pipe-2","nullius-boxed-heat-pipe-2"},
    {"nullius-motor-2-vulcanus","nullius-boxed-motor-2-vulcanus"},
    {"nullius-heat-pipe-2-vulcanus","nullius-boxed-heat-pipe-2-vulcanus"},
    {"nullius-copper-heat-pipe","nullius-boxed-copper-heat-pipe"},
  } do parity(pair[1],pair[2]) end

  for i,name in ipairs{"nullius-fumarole","crude-oil","nullius-hydrocarbon-vent"} do
    local pos={-40+i*16,-35}
    local resource=assert(s.create_entity{name=name,position=pos,amount=300000})
    for tier=1,3 do
      check(s.can_place_entity{name="nullius-geothermal-build-"..tier,position=pos,force="player",build_check_type=defines.build_check_type.manual}==(i==1),
        name.." geothermal tier "..tier)
    end
    for tier=1,2 do
      check(s.can_place_entity{name="nullius-extractor-"..tier,position=pos,force="player",build_check_type=defines.build_check_type.manual},name.." extractor "..tier)
    end
    if i==1 then
      s.create_entity{name="nullius-geothermal-build-1",position=pos,force="player",raise_built=true}
      local reactor=s.find_entity("nullius-geothermal-reactor-1",pos)
      check(reactor~=nil,"build event creates geothermal reactor")
      reactor.destroy()
    end
    resource.destroy()
  end
  local inv=game.create_inventory(1);inv[1].set_stack{name="upgrade-planner"}
  for y=-9,11,2 do assert(s.create_entity{name="straight-rail",position={1,y},force="player"}) end
  for family,count in pairs{locomotive=3,["cargo-wagon"]=3,["fluid-wagon"]=3,["drone-carrier"]=2} do
    for tier=1,count do
      local name="nullius-"..family.."-"..tier
      local e=assert(s.create_entity{name=name,position={1,1},force="player"})
      s.upgrade_area{area={{-4,-5},{5,7}},force="player",item=inv[1]}
      local target=e.get_upgrade_target()
      check(tier==count and target==nil or tier<count and target and target.name=="nullius-"..family.."-"..(tier+1),name.." upgrade")
      e.destroy()
    end
  end
  local resource=assert(s.create_entity{name="nullius-fumarole",position={20,0},amount=300000})
  local extractor=assert(s.create_entity{name="nullius-extractor-1",position={20,0},force="player"})
  s.upgrade_area{area={{16,-4},{24,4}},force="player",item=inv[1]}
  check(extractor.get_upgrade_target().name=="nullius-extractor-2","extractor upgrade retained")
  extractor.destroy();resource.destroy();inv.destroy()

  storage.labs={}
  local tech=game.forces.player.technologies["nullius-experimental-chemistry"]
  game.forces.player.research_all_technologies()
  tech.researched=false
  check(game.forces.player.add_research(tech.name),"research selected")
  for i,name in ipairs{"nullius-lab-1","nullius-lab-2","nullius-lab-3","nullius-biology-lab"} do
    local x=-40+i*16
    local lab=assert(s.create_entity{name=name,position={x,30},force="player"})
    local pole=assert(s.create_entity{name="substation",position={x+4,30},force="player"})
    local a=lab.get_wire_connector(defines.wire_connector_id.circuit_red,true)
    local b=pole.get_wire_connector(defines.wire_connector_id.circuit_red,true)
    check(a and b and a.connect_to(b,false,defines.wire_origin.player),name.." circuit connection")
    lab.get_or_create_control_behavior().read_research_cost=true
    local bp=game.create_inventory(1);bp[1].set_stack{name="blueprint"}
    bp[1].create_blueprint{surface=s,force="player",area={{x-3,26},{x+6,34}}}
    local ghosts=bp[1].build_blueprint{surface=s,force="player",position={x,48},skip_fog_of_war=true}
    check(#ghosts==2,name.." blueprint entities")
    local rebuilt={}
    for _,ghost in ipairs(ghosts) do
      local _,entity=ghost.revive()
      check(entity~=nil,name.." blueprint revival")
      rebuilt[entity.type]=entity
    end
    local copied=rebuilt.lab.get_wire_connector(defines.wire_connector_id.circuit_red,false)
    local copied_pole=rebuilt["electric-pole"].get_wire_connector(defines.wire_connector_id.circuit_red,false)
    check(copied and copied_pole and copied.is_connected_to(copied_pole,defines.wire_origin.player),name.." restored blueprint wire")
    check(rebuilt.lab.get_control_behavior().read_research_cost,name.." blueprint behavior")
    rebuilt.lab.destroy();rebuilt["electric-pole"].destroy()
    bp.destroy()
    local power=assert(s.create_entity{name="factorio-test-planner-grid",position={x+4,33},force="player"})
    power.power_production=10000000
    power.electric_buffer_size=10000000
    power.energy=10000000
    power.power_usage=0
    check(lab.is_connected_to_electric_network(),name.." electric connection")
    storage.labs[#storage.labs+1]=lab
  end
end)
script.on_nth_tick(60,function()
  if game.tick==0 then return end
  script.on_nth_tick(60,nil)
  for _,lab in ipairs(storage.labs) do
    local network=lab.get_circuit_network(defines.wire_connector_id.circuit_red)
    check(network and network.signals and #network.signals>0,lab.name.." research cost output "..helpers.table_to_json{energy=lab.energy,research=game.forces.player.current_research and game.forces.player.current_research.name,signals=network and network.signals})
    for _,ingredient in pairs(game.forces.player.current_research.research_unit_ingredients) do
      check(network.get_signal{type="item",name=ingredient.name}==ingredient.amount,lab.name.." cost "..ingredient.name)
    end
  end
  helpers.write_file("factorio-tests/"..CASE..".json",helpers.table_to_json{
    schema=1,case=CASE,status="pass",assertions=storage.assertions,failure_count=0,
    tick=game.tick,factorio_version=script.active_mods.base},false)
end)

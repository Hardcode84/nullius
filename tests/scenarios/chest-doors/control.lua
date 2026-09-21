-- given: eight stone and four native logistic robots per isolated network;
--        each test roboport starts with 50 MJ and receives no further power
-- place: all 17 chests; pair each logistic chest with a vanilla source or sink
-- connect: a red wire from each subject chest to an empty constant combinator
-- act: request eight stone, or let an active provider dispatch them to storage
-- run: 1800 ticks
-- expect: exact capacity/mode, eight delivered items, empty donors, circuit counts
local cases = require("fixture")
local RED = defines.wire_connector_id.circuit_red
local function check(ok,message)
  storage.assertions=storage.assertions+1
  assert(ok,message)
end
local function request(chest)
  local sections=chest.get_logistic_sections()
  local section=sections.get_section(1) or sections.add_section()
  section.set_slot(1,{value={type="item",name="stone",quality="normal"},min=8,max=8})
end
script.on_init(function()
  storage.assertions=0
  storage.rows={}
  local surface=game.create_surface("chest-door-test",{width=256,height=256,autoplace_controls={}})
  surface.request_to_generate_chunks({0,0},5)
  surface.force_generate_chunk_requests()
  for _,entity in pairs(surface.find_entities()) do entity.destroy() end
  local tiles={}
  for x=-116,116 do for y=-90,110 do table.insert(tiles,{name="grass-1",position={x,y}}) end end
  surface.set_tiles(tiles)
  for i,case in ipairs(cases) do
    local x,y=((i-1)%5)*48-96, math.floor((i-1)/5)*48-72
    local function place(name,dx,dy)
      local entity=surface.create_entity{name=name,position={x+dx,y+dy},force="player"}
      check(entity ~= nil,name .. " placed")
      return entity
    end
    local chest=place(case.name,-6,6)
    check(#chest.get_inventory(defines.inventory.chest)==case.size,case.name .. " capacity")
    check(chest.prototype.logistic_mode==case.mode,case.name .. " logistic mode")
    local upgrade=chest.prototype.next_upgrade
    check((upgrade and upgrade.name)==case.upgrade,case.name .. " upgrade target")
    local trash=chest.get_inventory(defines.inventory.logistic_container_trash)
    check((trash and #trash or 0)==(case.trash or 0),case.name .. " trash capacity")
    local wire_sink=place("constant-combinator",-6,10)
    local connector=chest.get_wire_connector(RED,true)
    check(connector ~= nil,case.name .. " connector")
    check(connector.connect_to(wire_sink.get_wire_connector(RED,true)),case.name .. " red wire")
    local row={name=case.name,chest=chest,wire_sink=wire_sink}
    if case.mode then
      local port=place("factorio-test-chest-port",0,0)
      port.energy=50000000
      check(port.get_inventory(defines.inventory.roboport_robot).insert{name="logistic-robot",count=4}==4,
        case.name .. " robot stock")
      if case.mode=="passive-provider" then
        row.source=chest;row.destination=place("requester-chest",6,6)
        request(row.destination)
      elseif case.mode=="active-provider" then
        row.source=chest;row.destination=place("storage-chest",6,6)
      elseif case.mode=="storage" then
        row.source=place("active-provider-chest",6,6);row.destination=chest
      else
        row.source=place("passive-provider-chest",6,6);row.destination=chest
        request(chest)
      end
      check(row.source.insert{name="stone",count=8}==8,case.name .. " declared item stock")
      row.port=port
    else
      check(chest.insert{name="stone",count=8}==8,case.name .. " ordinary stock")
    end
    table.insert(storage.rows,row)
  end
end)
script.on_nth_tick(1800,function(event)
  if event.tick==0 then return end
  script.on_nth_tick(1800,nil)
  local networks={}
  for _,row in ipairs(storage.rows) do
    if row.port then
      local network=row.port.logistic_cell.logistic_network
      check(not networks[network.network_id],row.name .. " isolated network")
      networks[network.network_id]=true
      check(row.destination.get_item_count("stone")==8,row.name .. " delivered eight stone")
      check(row.source.get_item_count("stone")==0,row.name .. " emptied donor")
      check(row.port.energy>0,row.name .. " powered port")
    end
    local actual=row.chest.get_item_count("stone")
    check(row.wire_sink.get_signal({type="item",name="stone",quality="normal"},RED)==actual,
      row.name .. " circuit inventory")
  end
  helpers.write_file("factorio-tests/chest-doors.json",helpers.table_to_json({
    schema=1,case="chest-doors",status="pass",factorio_version=script.active_mods.base,
    tick=game.tick,assertions=storage.assertions,chests=#storage.rows,logistic_chests=15,
    failure_count=0,failures={},
  }),false)
end)

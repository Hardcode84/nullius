-- given: real recipe-port layouts, void power, and one unit per stored fluid
-- place: one native assembler per layout, direction, and flip axis
-- connect: pipes at the calculated port coordinates after each flip
-- act: flip; supply 100 units per input pipe and one unit per output port
-- run: 10 ticks
-- expect: flips preserve fluids; all 600 connections transfer the correct fluid
local fluid = require("__nullius-star__/scenarios/fluid-api")
local modern = script.active_mods.base:match("^2%.1%.") ~= nil
script.on_init(function()
  game.surfaces[1].request_to_generate_chunks({150,150},8)
  game.surfaces[1].force_generate_chunk_requests()
  local count, flips = 0, 0
  storage.flow_checks = {}
  for _, contract in ipairs(prototypes.mod_data["mirroring-contracts"].data.machines) do
    local entity = assert(game.surfaces[1].create_entity{
      name=contract.name, position={0,0}, force="player"})
    entity.set_recipe(contract.name)
    assert(entity.get_recipe().name == contract.name, contract.name)
    if modern then assert(entity.prototype.use_mirroring, contract.name) end
    for _, direction in ipairs({defines.direction.north, defines.direction.east,
                                defines.direction.south, defines.direction.west}) do
      entity.direction = direction
      for index, name in ipairs(contract.fluids) do
        fluid.set(entity, index, {name=name, amount=1})
      end
      entity.mirroring = true
      local mirrored = entity.mirroring
      assert(mirrored, contract.name .. " cannot mirror")
      flips=flips+1
      if modern then
        for _, horizontal in ipairs({true, false}) do
          local before_direction, before_mirror = entity.direction, entity.mirroring
          local flipped = entity.flip{horizontal=horizontal}
          assert(flipped, contract.name .. " cannot flip")
          assert(entity.direction ~= before_direction or entity.mirroring ~= before_mirror,
            contract.name .. " flip did not change orientation")
          entity.flip{horizontal=horizontal}
          assert(entity.direction == before_direction and entity.mirroring == before_mirror,
            contract.name .. " double flip changed orientation")
        end
      end
      for index, name in ipairs(contract.fluids) do
        local actual = assert(fluid.get(entity,index), contract.name .. " lost fluid")
        assert(actual.name == name and actual.amount == 1, contract.name .. " fluid changed " .. index .. " " .. helpers.table_to_json(actual))
      end
      entity.mirroring = false
      assert(not entity.mirroring, contract.name)
    end
    count=count+1
    entity.destroy()
  end
  assert(flips > 0, "missing mirroring coverage")
  storage.result = {status="pass", machines=count, mirrored_orientations=flips}
  -- Place pipes at the independently transformed recipe-port coordinates.
  local case = 0
  local offsets = {[0]={0,-1}, [4]={1,0}, [8]={0,1}, [12]={-1,0}}
  for _, contract in ipairs(prototypes.mod_data["mirroring-contracts"].data.machines) do
    for _, direction in ipairs({0,4,8,12}) do
      for _, horizontal in ipairs({true,false}) do
        case=case+1
        local entity=assert(game.surfaces[1].create_entity{
          name=contract.name, position={(case%16)*20,math.floor(case/16)*20}, direction=direction, force="player"})
        entity.set_recipe(contract.name)
        if modern then
          assert(entity.flip{horizontal=horizontal}, contract.name)
        else
          entity.mirroring=true
          if not horizontal then entity.direction=(direction+8)%16 end
        end
        for index, box in ipairs(contract.boxes) do
          for _, connection in ipairs(box.pipe_connections) do
            local position=connection.position
            local offset=assert(offsets[connection.direction])
            local x=(position.x or position[1])+offset[1]
            local y=(position.y or position[2])+offset[2]
            if entity.mirroring then x=-x end
            for _=1,entity.direction/4 do x,y=-y,x end
            local pipe=assert(game.surfaces[1].create_entity{name="pipe",
              position={entity.position.x+x,entity.position.y+y}, force="player"})
            if not modern then
              local c=entity.fluidbox.get_pipe_connections(index)[1]
              assert(c.target and c.target.owner == pipe, contract.name .. " missing pipe connection " .. index)
            end
            local output=box.production_type == "output"
            local source=output and entity or pipe
            fluid.set(source, output and index or 1,
              {name=contract.fluids[index], amount=output and 1 or 100})
            storage.flow_checks[#storage.flow_checks+1]={
              target=output and pipe or entity, index=output and 1 or index,
              name=contract.fluids[index], label=contract.name .. ":" .. index .. ":" .. direction}
          end
        end
      end
    end
  end
end)

script.on_nth_tick(10, function(event)
  if event.tick < 10 then return end
  for _, check in ipairs(storage.flow_checks) do
    local actual=assert(fluid.get(check.target,check.index), check.label .. " disconnected pipe")
    assert(actual.name == check.name and actual.amount > 0, check.label .. " wrong pipe fluid")
  end
  storage.result.pipe_checks=#storage.flow_checks
  helpers.write_file("mirroring.json", helpers.table_to_json(storage.result))
  script.on_nth_tick(10,nil)
end)

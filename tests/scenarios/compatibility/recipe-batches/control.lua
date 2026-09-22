-- given: one input batch per new recipe, with exact temperatures and void power
-- place: separate native assemblers, finite fluid buffers, and pumps
-- connect: one feed per fluid ingredient
-- act: select each recipe on a surface within its temperature bounds
-- run: at most 3600 ticks; inspect outputs as soon as each craft completes
-- expect: one craft, exact deterministic products, and bounded random returns
local contracts = require("__nullius-star__/recipe-test-contracts")
local fluid_api = require("__nullius-star__/scenarios/fluid-api")
local modern = require("__nullius-star__/factorio-version").is_2_1
local function check(ok, message)
  storage.assertions = storage.assertions + 1
  assert(ok, message)
end
script.on_init(function()
  storage.assertions = 0
  storage.rows = {}
  local names = {}
  for name in pairs(contracts) do names[#names+1] = name end
  table.sort(names)
  local surface = game.create_surface("processing", {width=512,height=512,autoplace_controls={}})
  surface.request_to_generate_chunks({0,0},8)
  surface.force_generate_chunk_requests()
  for _, entity in pairs(surface.find_entities()) do entity.destroy() end
  surface.set_property("nullius-ambient-temperature", 200)
  for i, name in ipairs(names) do
    local contract = contracts[name]
    local recipe = prototypes.recipe[name]
    local categories = modern and recipe.categories or {recipe.category}
    local expected = contract.categories or {contract.category or "crafting"}
    check(#categories == #expected and categories[1] == expected[1], name .. " native category")
    game.forces.player.recipes[name].enabled = true
    local position = {x=((i-1)%10)*24-120,y=math.floor((i-1)/10)*24-120}
    local machine = surface.create_entity{name="test-"..name,position=position,force="player"}
    machine.set_recipe(name)
    check(machine.get_recipe() and machine.get_recipe().name == name, name .. " selection")
    local row = {machine=machine,name=name,feeds={}}
    for _, part in ipairs(contract.ingredients) do
      if part.type == "item" then
        check(machine.insert{name=part.name,count=part.amount} == part.amount,name.." item input "..part.name)
      else
        local index
        for slot=1,fluid_api.count(machine) do
          local filter = fluid_api.filter(machine,slot)
          if filter and filter.name == part.name and fluid_api.prototype(machine,slot).production_type == "input" then index=slot end
        end
        check(index ~= nil, name .. " input port " .. part.name)
        local x = position.x + 2*(part.fluidbox_index or index)-7
        local pump = surface.create_entity{name="test-recipe-pump",position={x,position.y-7.5},direction=defines.direction.south,force="player"}
        local buffer = surface.create_entity{name="test-buffer-"..name.."-"..part.name,position={x,position.y-9},force="player"}
        local temperature = part.temperature or part.minimum_temperature or prototypes.fluid[part.name].default_temperature
        fluid_api.set(buffer,1,{name=part.name,amount=part.amount,temperature=temperature})
        check(buffer.get_fluid_count(part.name)==part.amount,name.." finite fluid stock")
        row.feeds[#row.feeds+1]={pump=pump,buffer=buffer,name=part.name}
      end
    end
    storage.rows[#storage.rows+1]=row
  end
  storage.total=#storage.rows
end)
script.on_nth_tick(10,function(event)
  for i=#storage.rows,1,-1 do
    local row=storage.rows[i]
    local machine=row.machine
    if machine.products_finished > 0 then
      check(machine.products_finished==1,row.name.." one craft")
      local bounds={}
      for _, part in ipairs(contracts[row.name].results) do
        local key=part.type..":"..part.name
        local bound=bounds[key] or {min=0,max=0,type=part.type,name=part.name,temperature=part.temperature}
        local probability=part.probability or part.independent_probability or 1
        bound.min=bound.min+(probability==1 and (part.amount or part.amount_min) or 0)
        bound.max=bound.max+(part.amount or part.amount_max)
        bounds[key]=bound
      end
      for _, bound in pairs(bounds) do
        local amount=bound.type=="item" and machine.get_output_inventory().get_item_count(bound.name) or machine.get_fluid_count(bound.name)
        check(amount>=bound.min and amount<=bound.max,row.name.." output "..bound.name..": "..amount)
        if bound.temperature then
          local found=false
          for slot=1,fluid_api.count(machine) do
            local fluid=fluid_api.get(machine,slot)
            if fluid and fluid.name==bound.name then
              found=true
              check(math.abs(fluid.temperature-bound.temperature)<0.001,row.name.." output temperature")
            end
          end
          check(found,row.name.." output fluid")
        end
      end
      for _, part in ipairs(contracts[row.name].ingredients) do
        if part.type=="item" then
          check(machine.get_item_count(part.name)==machine.get_output_inventory().get_item_count(part.name),row.name.." consumed "..part.name)
        end
      end
      for _, feed in ipairs(row.feeds) do
        local remaining=machine.get_fluid_count(feed.name)+feed.pump.get_fluid_count(feed.name)+feed.buffer.get_fluid_count(feed.name)
        local returned=bounds["fluid:"..feed.name]
        local low=returned and returned.min or 0
        local high=returned and returned.max or 0
        check(remaining>=low-0.00001 and remaining<=high+0.00001,row.name.." fluid balance "..feed.name..": "..remaining)
      end
      machine.destroy()
      table.remove(storage.rows,i)
    end
  end
  if #storage.rows==0 then
    helpers.write_file("factorio-tests/recipe-batches.json",helpers.table_to_json({status="pass",recipes=storage.total,assertions=storage.assertions,tick=event.tick}),false)
    script.on_nth_tick(10,nil)
  elseif event.tick>=3600 then
    local missing={}
    for _, row in ipairs(storage.rows) do
      local details={machine=row.machine.get_fluid_contents(),feeds={}}
      for _,feed in ipairs(row.feeds) do details.feeds[#details.feeds+1]={pump=feed.pump.get_fluid_contents(),buffer=feed.buffer.get_fluid_contents()} end
      missing[#missing+1]=row.name.." status "..row.machine.status.." "..helpers.table_to_json(details)
    end
    error("Unfinished recipes: "..table.concat(missing,", "))
  end
end)

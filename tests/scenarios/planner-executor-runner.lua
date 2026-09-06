return function(CASE, fixture)
local failures = {}
local transferred = {}
for _, name in ipairs(fixture.transfers or {}) do transferred[name] = true end
local assertions = 0
local function check(ok, message)
  assertions = assertions + 1
  if not ok then failures[#failures + 1] = message end
  return ok
end
local function finish()
  script.on_nth_tick(30, nil)
  local result = {schema=1, case=CASE, status=#failures == 0 and "pass" or "fail",
    factorio_version=script.active_mods.base, tick=game.tick, assertions=assertions,
    failure_count=#failures, failures=failures,
    observations={executors=#fixture.executors, completed=storage.completed,
      transfers=storage.transfers,
      fixture="Declared cycles per selected recipe; declared intermediates, fuel and scripted heat"}}
  helpers.write_file("factorio-tests/" .. CASE .. ".json", helpers.table_to_json(result), false)
  if #failures > 0 then error(helpers.table_to_json(result)) end
end
local function feed(row)
  local machine = row.machine
  if row.spec.heat then machine.temperature = 500 end
  for _, input in ipairs(row.pending) do
    if input.amount > 0 then
      if input.type == "fluid" then
        local current = machine.fluidbox[input.index]
        local before = current and current.amount or 0
        local inserted = math.min(input.amount, machine.fluidbox.get_capacity(input.index) - before)
        machine.fluidbox[input.index] = {name=input.name, amount=before+inserted,
          temperature=prototypes.fluid[input.name].default_temperature}
        input.amount = input.amount - inserted
      else
        local count = input.amount
        -- Deliver fresh declared stock in batches. Do not preload several
        -- spoilage windows of blooms into a slow bulk casting station.
        if input.batch then
          local inventory = machine.get_inventory(defines.inventory.assembling_machine_input)
          count = math.min(count, math.max(0, input.batch - inventory.get_item_count(input.name)))
        end
        if transferred[input.name] then count = math.min(count, storage.transfers[input.name] or 0) end
        local inserted = count > 0 and machine.insert{name=input.name, count=count} or 0
        input.amount = input.amount - inserted
        if transferred[input.name] then storage.transfers[input.name] = (storage.transfers[input.name] or 0) - inserted end
      end
    end
  end
end
local function drain(row)
  for index=1,#row.machine.fluidbox do
    local proto = row.machine.fluidbox.get_prototype(index)
    local fluid = row.machine.fluidbox[index]
    local filter = row.machine.fluidbox.get_filter(index)
    local output_name = false
    for _, output in ipairs(row.spec.outputs) do if fluid and output.name == fluid.name then output_name = true end end
    if fluid and filter and output_name and proto.production_type ~= "input" then
      row.produced[fluid.name] = (row.produced[fluid.name] or 0) + fluid.amount
      row.machine.fluidbox[index] = nil
    end
  end
  local inventory = row.machine.get_output_inventory()
  if inventory then
    for _, output in ipairs(row.spec.outputs) do
      if output.type ~= "fluid" then
        local count = inventory.remove{name=output.name, count=2147483647}
        row.produced[output.name] = (row.produced[output.name] or 0) + count
        if transferred[output.name] then
          storage.transfers[output.name] = (storage.transfers[output.name] or 0) + count
        end
      end
    end
  end
end
local function input_box(machine, name, fuel)
  for index=1,#machine.fluidbox do
    local filter = machine.fluidbox.get_filter(index)
    local proto = machine.fluidbox.get_prototype(index)
    if fuel and not filter then return index end
    if not fuel and ((filter and filter.name == name and proto.production_type ~= "output") or
        (not filter and proto.production_type == "input")) then
      return index
    end
  end
end
script.on_nth_tick(30, function()
  if not storage.rows then
    local force = game.forces.player
    for _, name in ipairs(fixture.boundary_technologies) do
      check(force.technologies[name] ~= nil, "unknown declared research " .. name)
      for _, pack in pairs(force.technologies[name].research_unit_ingredients) do
        check(pack.name ~= "nullius-physics-pack", "physics-consuming fixture research: " .. name)
      end
      force.technologies[name].researched = true
    end
    local planet = game.planets["nullius-vulcanus"]
    local surface = planet.surface or planet.create_surface()
    surface.request_to_generate_chunks({0,0}, 8)
    surface.force_generate_chunk_requests()
    storage.rows = {}
    storage.transfers = {}
    storage.completed = 0
    for index, spec in ipairs(fixture.executors) do
      local x, y = (index % 12) * 20 - 120, math.floor(index / 12) * 20 - 100
      local tiles = {}
      for dx=-6,6 do for dy=-6,6 do
        tiles[#tiles+1] = {name="volcanic-soil-dark", position={x+dx,y+dy}}
      end end
      surface.set_tiles(tiles, true, false, false, false)
      for _, obstruction in ipairs(surface.find_entities_filtered{area={{x-7,y-7},{x+7,y+7}}}) do
        obstruction.destroy()
      end
      local machine = surface.create_entity{name=spec.machine, position={x,y}, force=force}
      if not check(machine ~= nil, "cannot place " .. spec.machine) then finish() return end
      if machine.type ~= "furnace" then
        check(machine.set_recipe(spec.recipe), spec.machine .. " cannot select " .. spec.recipe)
      end
      local row = {machine=machine, spec=spec, pending={}, produced={}, start=game.tick,
        finished=machine.products_finished}
      for _, input in ipairs(spec.ingredients) do
        local pending = {type=input.type or "item", name=input.name,
          amount=input.amount * spec.cycles}
        if pending.type == "fluid" then
          pending.index = input_box(machine, input.name, false)
          if not check(pending.index ~= nil, spec.recipe .. " has no input box for " .. input.name) then
            finish() return
          end
        elseif prototypes.item[input.name].get_spoil_ticks() > 0 and not transferred[input.name] then
          pending.batch = input.amount
        end
        row.pending[#row.pending+1] = pending
      end
      if spec.fuel_per_cycle > 0 then
        local index = input_box(machine, fixture.fuel, true)
        if not check(index ~= nil, spec.recipe .. " has no fuel box") then finish() return end
        row.pending[#row.pending+1] = {type="fluid", name=fixture.fuel, index=index,
          amount=spec.fuel_per_cycle * (spec.cycles + 1)}
      end
      storage.rows[#storage.rows+1] = row
      feed(row)
    end
  end
  for _, row in ipairs(storage.rows) do
    if not row.done then
      drain(row)
      feed(row)
      local expected = {}
      for _, output in ipairs(row.spec.outputs) do
        if (output.probability or 1) == 1 then
          local quantity = output.amount or output.amount_min
          local bonus_cycles = math.floor(row.spec.cycles * row.spec.productivity + 0.000001)
          local bonus = math.max(0, quantity - (output.ignored_by_productivity or 0)) * bonus_cycles
          expected[output.name] = (expected[output.name] or 0) + quantity * row.spec.cycles + bonus
        end
      end
      local ready = row.machine.products_finished >= row.finished + row.spec.cycles
      for name, quantity in pairs(expected) do
        if (row.produced[name] or 0) + 0.001 < quantity then ready = false end
      end
      if ready then
        check(true, row.spec.recipe .. " produced its guaranteed output")
        row.done = true
        row.machine.active = false
        storage.completed = storage.completed + 1
      elseif game.tick >= fixture.deadline then
        check(false, row.spec.machine .. ": " .. row.spec.recipe .. " completed " ..
          (row.machine.products_finished-row.finished) .. "/" .. row.spec.cycles ..
          " cycles; status=" .. tostring(row.machine.status) .. " produced=" .. helpers.table_to_json(row.produced) ..
          " expected=" .. helpers.table_to_json(expected))
      end
    end
  end
  if #failures > 0 or storage.completed == #storage.rows or game.tick >= fixture.deadline then finish() end
end)

end

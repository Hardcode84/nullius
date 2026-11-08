local crafting_input = require("__nullius-star__/scenarios/inventory-api").crafting_input
-- given: each plant has 180 powder, one canister, two explosives, and 50000 fuel gas.
-- place: two tier-1 pneumatic chemical plants on Vulcanus.
-- connect: one CO2 tank per plant through a pipe at tick 90.
-- act: research Aluminum-CO2 Propellant and select ordinary and boxed recipes.
-- run: one batch per plant, with 1500 or 7500 compressed CO2.
-- expect: three fuel items or boxes, consumed solids, and no productivity.
local CASE = "vulcanus-co2-fuel"
local function check(ok, message)
  storage.assertions = storage.assertions + 1
  assert(ok, message)
end
script.on_nth_tick(30, function()
  if not storage.rows then
    storage.assertions = 0
    storage.rows = {}
    local force = game.create_force("co2-fuel-test")
    local tech = force.technologies["nullius-aluminum-co2-propellant"]
    check(not force.recipes["nullius-aluminum-co2-rocket-fuel"].enabled, "ordinary starts locked")
    check(not force.recipes["nullius-boxed-aluminum-co2-rocket-fuel"].enabled, "boxed starts locked")
    tech.researched = true
    local planet = game.planets["nullius-vulcanus"]
    local surface = planet.surface or planet.create_surface()
    surface.request_to_generate_chunks({0,0}, 2)
    surface.force_generate_chunk_requests()
    for i, boxed in ipairs{false, true} do
      local x = i * 20
      for _, entity in pairs(surface.find_entities_filtered{area={{x-6,-6},{x+6,6}}}) do entity.destroy() end
      local tiles = {}
      for dx=-6,6 do for dy=-6,6 do tiles[#tiles+1]={name="volcanic-soil-dark", position={x+dx,dy}} end end
      surface.set_tiles(tiles, true, false, false, false)
      local recipe = "nullius-"..(boxed and "boxed-" or "").."aluminum-co2-rocket-fuel"
      check(force.recipes[recipe].enabled, "research unlocks "..recipe)
      local machine = assert(surface.create_entity{name="nullius-chemical-plant-1-pneumatic", position={x,0}, force=force})
      check(machine.set_recipe(recipe) ~= nil, "recipe selection")
      local prefix = boxed and "nullius-box-" or "nullius-"
      for _, item in ipairs{{prefix.."aluminum-powder",180}, {prefix.."canister",1},
          {boxed and "nullius-box-explosive" or "cliff-explosives",2}} do
        check(machine.insert{name=item[1],count=item[2]} == item[2], "finite solids "..item[1])
      end
      local tank = assert(surface.create_entity{name="nullius-small-tank-1",position={x-1.5,-3.5},force=force})
      local gas = boxed and 7500 or 1500
      check(tank.insert_fluid{name="nullius-compressed-carbon-dioxide",amount=gas} == gas, "finite CO2 supply")
      check(prototypes.recipe[recipe].maximum_productivity == 0, "productivity cap")
      storage.rows[#storage.rows+1] = {machine=machine, tank=tank, x=x,
        fuel=50000, product=boxed and "nullius-box-rocket-fuel" or "rocket-fuel"}
    end
  end
  local complete = true
  for _, row in ipairs(storage.rows) do
    if row.fuel > 0 then
      row.fuel = row.fuel - row.machine.insert_fluid{name="nullius-compressed-volcanic-gas",amount=row.fuel}
    end
    if game.tick < 90 then
      check(row.machine.products_finished == 0, "no craft before CO2 connection")
    elseif game.tick == 90 then
      assert(row.machine.surface.create_entity{name="pipe",position={row.x-1,-2},force=row.machine.force})
    end
    complete = complete and row.machine.get_output_inventory().get_item_count(row.product) == 3
  end
  if complete or game.tick >= 12300 then
    for _, row in ipairs(storage.rows) do
      check(row.machine.get_output_inventory().get_item_count(row.product) == 3, "one batch "..row.product.." status="..row.machine.status.." progress="..row.machine.crafting_progress.." fuel="..row.fuel)
      check(row.machine.get_inventory(crafting_input).is_empty(), "solids consumed")
      check(row.tank.get_fluid_count("nullius-compressed-carbon-dioxide") < 0.01, "CO2 consumed")
      check(row.machine.productivity_bonus == 0, "no productivity")
      check(row.fuel < 50000, "gas fuel consumed")
    end
    helpers.write_file("factorio-tests/"..CASE..".json",helpers.table_to_json{
      schema=1,case=CASE,status="pass",tick=game.tick,assertions=storage.assertions,failure_count=0},false)
    script.on_nth_tick(30,nil)
  end
end)

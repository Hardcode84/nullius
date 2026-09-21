-- given: five batches of each declared fluid and 42 void-powered executors
-- place: one executor per recipe, eight tiles apart on an empty surface
-- connect: one finite fluid buffer and a void-powered pump to each input
-- act: select each recipe and insert its five input batches
-- run: 2000 ticks
-- expect: five crafts each, all fluid consumed, and no output items
local cases = require("__nullius-star__/scenarios/void-products/fixture")
local fluid_api = require("__nullius-star__/scenarios/fluid-api")
local probability = require("__nullius-star__/factorio-version").is_2_1 and "independent_probability" or "probability"
local assertions = 0
local function check(ok, message)
  assertions = assertions + 1
  assert(ok, message)
end
script.on_nth_tick(1, function()
  script.on_nth_tick(1, nil)
  local surface = game.create_surface("void-products-test", {width=128,height=96,autoplace_controls={}})
  surface.request_to_generate_chunks({0,0},3)
  surface.force_generate_chunk_requests()
  for _, entity in pairs(surface.find_entities()) do entity.destroy() end
  storage.rows = {}
  for i, case in ipairs(cases) do
    local recipe = prototypes.recipe[case.name]
    check(recipe.energy == case.seconds, case.name .. " craft time")
    check(#recipe.ingredients == 1 and recipe.ingredients[1].name == case.fluid
      and recipe.ingredients[1].amount == case.amount, case.name .. " input")
    check(#recipe.products == 1 and recipe.products[1].name == case.product
      and recipe.products[1].amount == 1 and recipe.products[1][probability] == 0,
      case.name .. " zero output probability")
    local machine = surface.create_entity{name="factorio-test-void-products",
      position={((i-1)%8)*8-32, math.floor((i-1)/8)*8-24}, force="player"}
    check(machine ~= nil, case.name .. " placed")
    game.forces.player.recipes[case.name].enabled = true
    machine.set_recipe(case.name)
    check(machine.get_recipe().name == case.name, case.name .. " selected")
    local pump = surface.create_entity{name="factorio-test-void-pump",
      position={machine.position.x,machine.position.y-2.5}, direction=defines.direction.south, force="player"}
    check(pump ~= nil, case.name .. " pump placed")
    local buffer = surface.create_entity{name="factorio-test-void-buffer",
      position={machine.position.x, machine.position.y-4}, force="player"}
    check(buffer ~= nil, case.name .. " buffer placed")
    fluid_api.set(buffer, 1, {name=case.fluid, amount=5*case.amount,
      temperature=prototypes.fluid[case.fluid].default_temperature})
    check(fluid_api.get(buffer,1).amount == 5*case.amount, case.name .. " input stock")
    storage.rows[i] = {machine=machine,buffer=buffer,pump=pump}
  end
  storage.assertions = assertions
end)
script.on_nth_tick(2000, function(event)
  if event.tick == 0 then return end
  script.on_nth_tick(2000, nil)
  assertions = storage.assertions
  for i, case in ipairs(cases) do
    local machine = storage.rows[i].machine
    check(machine.products_finished == 5, case.name .. " five crafts: " .. machine.products_finished .. " " .. helpers.table_to_json({
      input=fluid_api.get(machine,1),buffer=fluid_api.get(storage.rows[i].buffer,1),
      pump=fluid_api.get(storage.rows[i].pump,1),progress=machine.crafting_progress,status=machine.status}))
    check(fluid_api.get(machine,1) == nil, case.name .. " all input consumed")
    check(fluid_api.get(storage.rows[i].buffer,1) == nil, case.name .. " buffer empty")
    for index=1,fluid_api.count(storage.rows[i].pump) do
      check(fluid_api.get(storage.rows[i].pump,index) == nil, case.name .. " pump empty")
    end
    check(machine.get_output_inventory().is_empty(), case.name .. " no output items")
  end
  helpers.write_file("factorio-tests/void-products.json", helpers.table_to_json({
    schema=1,case="void-products",status="pass",factorio_version=script.active_mods.base,
    tick=game.tick,assertions=assertions,recipes=#cases,crafts=5*#cases,failure_count=0,failures={}
  }),false)
end)

-- given: one batch per recipe and void-powered executors at crafting speed 60
-- place: 38 independent executors on an empty surface
-- connect: a finite fluid buffer and pump to each fluid input
-- act: select each recipe and insert its declared ingredients
-- run: 600 ticks
-- expect: exact recipe contracts and one complete batch from each executor
local cases = require("__nullius-star__/scenarios/turbine-recipes/fixture")
local fluid_api = require("__nullius-star__/scenarios/fluid-api")
local modern = require("__nullius-star__/factorio-version").is_2_1
local assertions = 0
local function check(ok, message)
  assertions = assertions + 1
  assert(ok, message)
end
local function check_parts(actual, expected, label)
  check(#actual == #expected, label .. " count")
  local amounts = {}
  for _, part in ipairs(actual) do amounts[part.type .. ":" .. part.name] = part.amount end
  for _, part in ipairs(expected) do
    check(amounts[part.type .. ":" .. part.name] == part.amount, label .. " " .. part.name)
  end
end
script.on_nth_tick(1, function()
  script.on_nth_tick(1, nil)
  local surface = game.create_surface("turbine-recipes-test", {width=128,height=96,autoplace_controls={}})
  surface.request_to_generate_chunks({0,0},3)
  surface.force_generate_chunk_requests()
  for _, entity in pairs(surface.find_entities()) do entity.destroy() end
  storage.rows = {}
  for i, case in ipairs(cases) do
    local recipe = prototypes.recipe[case.name]
    local categories = modern and recipe.categories or {recipe.category}
    check(#categories == 1 and categories[1] == case.category, case.name .. " category")
    check(math.abs(recipe.energy - case.seconds) < 0.000001, case.name .. " duration")
    check_parts(recipe.ingredients, case.ingredients, case.name .. " ingredients")
    check_parts(recipe.products, case.products, case.name .. " products")
    local machine = surface.create_entity{name="factorio-test-turbine-recipe",
      position={((i-1)%8)*10-40,math.floor((i-1)/8)*10-20},force="player"}
    check(machine ~= nil, case.name .. " placed")
    game.forces.player.recipes[case.name].enabled = true
    machine.set_recipe(case.name)
    check(machine.get_recipe().name == case.name, case.name .. " selected")
    local row = {machine=machine}
    for _, part in ipairs(case.ingredients) do
      if part.type == "item" then
        check(machine.insert{name=part.name,count=part.amount} == part.amount, case.name .. " input stock")
      else
        row.pump = surface.create_entity{name="factorio-test-void-pump",
          position={machine.position.x,machine.position.y-2.5},direction=defines.direction.south,force="player"}
        row.buffer = surface.create_entity{name="factorio-test-void-buffer",
          position={machine.position.x,machine.position.y-4},force="player"}
        check(row.pump ~= nil and row.buffer ~= nil, case.name .. " fluid supply placed")
        fluid_api.set(row.buffer,1,{name=part.name,amount=part.amount,
          temperature=prototypes.fluid[part.name].default_temperature})
      end
    end
    storage.rows[i] = row
  end
  storage.assertions = assertions
end)
script.on_nth_tick(600, function(event)
  if event.tick == 0 then return end
  script.on_nth_tick(600,nil)
  assertions = storage.assertions
  for i, case in ipairs(cases) do
    local row = storage.rows[i]
    local machine = row.machine
    check(machine.products_finished == 1, case.name .. " one craft: " .. machine.products_finished)
    for _, part in ipairs(case.products) do
      local amount = part.type == "item" and machine.get_output_inventory().get_item_count(part.name)
        or machine.get_fluid_count(part.name)
      check(math.abs(amount-part.amount) < 0.000001, case.name .. " output " .. part.name .. ": " .. amount)
    end
    for _, part in ipairs(case.ingredients) do
      if part.type == "fluid" then
        check(machine.get_fluid_count(part.name) == 0, case.name .. " input consumed")
        check(fluid_api.get(row.buffer,1) == nil, case.name .. " buffer empty")
        for index=1,fluid_api.count(row.pump) do
          check(fluid_api.get(row.pump,index) == nil, case.name .. " pump empty")
        end
      else
        check(machine.get_item_count(part.name) == 0, case.name .. " input consumed " .. part.name)
      end
    end
  end
  helpers.write_file("factorio-tests/turbine-recipes.json",helpers.table_to_json({
    schema=1,case="turbine-recipes",status="pass",factorio_version=script.active_mods.base,
    tick=game.tick,assertions=assertions,recipes=#cases,crafts=#cases,failure_count=0,failures={}
  }),false)
end)

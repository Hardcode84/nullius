-- given: two batches of blooms, crucibles, and filled barrels; a void-powered
-- executor at crafting speed 10 with 100% productivity
-- place: one executor on an empty surface at 100 degrees ambient temperature
-- connect: none
-- act: select industrial metallurgic science and insert both batches
-- run: 200 ticks
-- expect: 20 science packs; two to four barrels; no remaining input
local probability = require("__nullius-star__/factorio-version").is_2_1 and "independent_probability" or "probability"
local inputs = { ["nullius-molten-iron-bloom"]=2, ["nullius-molten-aluminum-bloom"]=2,
  ["nullius-crucible"]=1, ["nullius-chlorine-barrel"]=1, ["nullius-sulfur-dioxide-barrel"]=1 }
local assertions = 0
local function check(ok, message)
  assertions = assertions + 1
  assert(ok, message)
end
script.on_nth_tick(1, function()
  script.on_nth_tick(1,nil)
  local name = "nullius-metallurgic-pack-efficient"
  local recipe = prototypes.recipe[name]
  check(recipe.energy == 15, "15 second recipe")
  check(#recipe.ingredients == 5, "five ingredients")
  for _, ingredient in pairs(recipe.ingredients) do
    check(inputs[ingredient.name] == ingredient.amount, "unchanged ingredient " .. ingredient.name)
  end
  check(#recipe.products == 3, "three separate product entries")
  check(recipe.products[1].name == "nullius-metallurgic-pack" and recipe.products[1].amount == 5,
    "five science packs")
  for i=2,3 do
    local product = recipe.products[i]
    check(product.name == "barrel" and product.amount == 1, "one barrel per entry")
    check(product[probability] == (i==2 and 1 or 0.9), "barrel probability")
    check(product.ignored_by_productivity == 1, "barrels excluded from productivity")
  end
  check(prototypes.item["nullius-box-metallurgic-pack"] == nil, "metallurgic science has no boxed item")
  local surface = game.create_surface("metallurgic-products-test", {width=32,height=32,autoplace_controls={}})
  surface.set_property("nullius-ambient-temperature",100)
  surface.request_to_generate_chunks({0,0},1)
  surface.force_generate_chunk_requests()
  for _, entity in pairs(surface.find_entities()) do entity.destroy() end
  local machine = surface.create_entity{name="factorio-test-metallurgic-products",position={0,0},force="player"}
  check(machine ~= nil, "executor placed")
  game.forces.player.recipes[name].enabled = true
  machine.set_recipe(name)
  for item, amount in pairs(inputs) do
    check(machine.insert{name=item,count=2*amount} == 2*amount, "inserted " .. item)
  end
  storage.machine = machine
  storage.assertions = assertions
end)
script.on_nth_tick(200,function(event)
  if event.tick == 0 then return end
  script.on_nth_tick(200,nil)
  assertions = storage.assertions
  local machine = storage.machine
  local output = machine.get_output_inventory()
  check(output.get_item_count("nullius-metallurgic-pack") == 20, "productivity doubles science output")
  local barrels = output.get_item_count("barrel")
  check(barrels >= 2 and barrels <= 4, "productivity does not duplicate barrels")
  check(machine.get_recipe() ~= nil and machine.is_crafting() == false, "both batches complete")
  for item in pairs(inputs) do check(machine.get_item_count(item) == 0, "consumed " .. item) end
  helpers.write_file("factorio-tests/metallurgic-products.json",helpers.table_to_json({
    schema=1,case="metallurgic-products",status="pass",factorio_version=script.active_mods.base,
    tick=game.tick,assertions=assertions,failure_count=0,failures={},science=20,barrels=barrels
  }),false)
end)

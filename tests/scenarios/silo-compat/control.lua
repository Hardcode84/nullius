-- given: one production rocket recipe batch, one satellite, and electric power
-- place/connect: production silo on a powered grid, with a cargo landing pad
-- act: craft the rocket and request a launch when ready
-- run: up to 30000 ticks; check every 60 ticks
-- expect: exact ingredient consumption, one launch, and satellite science return
local function expect(ok, message)
  storage.assertions = storage.assertions + 1
  assert(ok, message)
end

script.on_init(function()
  storage.assertions = 0
  local surface = game.surfaces[1]
  surface.request_to_generate_chunks({0, 0}, 2)
  surface.force_generate_chunk_requests()
  for _, entity in pairs(surface.find_entities_filtered{area={{-16,-16},{16,16}}}) do entity.destroy() end
  local tiles = {}
  for x=-16,16 do for y=-16,16 do tiles[#tiles+1]={name="grass-1",position={x,y}} end end
  surface.set_tiles(tiles)
  local force = game.forces.player
  force.recipes["nullius-rocket"].enabled = true
  storage.pad = surface.create_entity{name="cargo-landing-pad",position={-10,0},force=force}
  storage.silo = surface.create_entity{name="nullius-silo", position={0,0},force=force}
  local power = surface.create_entity{name="electric-energy-interface",position={8,0},force=force}
  power.power_production = 100000000
  power.electric_buffer_size = 100000000
  surface.create_entity{name="substation",position={6,3},force=force}
  local silo = storage.silo
  expect(silo ~= nil, "silo placed")
  expect(silo.get_recipe().name == "nullius-rocket", "production fixed recipe")
  local recipe = prototypes.recipe["nullius-rocket"]
  expect(recipe.energy == 400, "400-second recipe")
  for _, ingredient in pairs(recipe.ingredients) do
    expect(silo.insert{name=ingredient.name,count=ingredient.amount} == ingredient.amount, "feed " .. ingredient.name)
  end
end)

script.on_nth_tick(60, function()
  local silo = storage.silo
  if not storage.requested and silo.rocket_silo_status == defines.rocket_silo_status.rocket_ready then
    expect(silo.products_finished == 1, "one rocket crafted")
    for _, ingredient in pairs(prototypes.recipe["nullius-rocket"].ingredients) do
      expect(silo.get_item_count(ingredient.name) == 0, "consumed " .. ingredient.name)
    end
    expect(silo.get_inventory(defines.inventory.rocket_silo_rocket).insert{name="nullius-satellite",count=1} == 1, "satellite inserted")
    silo.send_to_orbit_automatically = true
    storage.requested = true
  end
  local output = storage.pad.get_inventory(defines.inventory.cargo_landing_pad_main)
  if storage.launched and output.get_item_count("nullius-box-astronomy-pack") == 100 then
    expect(storage.launched == 1, "one launch event")
    expect(silo.products_finished == 1, "no extra rocket crafted")
    helpers.write_file("factorio-tests/silo-compat.json", helpers.table_to_json{
      schema=1, case="silo-compat", failure_count=0, failures={},
      factorio_version=script.active_mods.base, status="pass", assertions=storage.assertions, tick=game.tick,
    }, false)
    script.on_nth_tick(60, nil)
  else
    assert(game.tick < 29940, "silo launch/science deadline; status=" .. silo.rocket_silo_status .. " progress=" .. silo.crafting_progress .. " products=" .. silo.products_finished .. " requested=" .. tostring(storage.requested) .. " energy=" .. silo.energy)
  end
end)

script.on_event(defines.events.on_rocket_launched, function(event)
  expect(event.rocket_silo == storage.silo, "launch from tested silo")
  storage.launched = (storage.launched or 0) + 1
end)

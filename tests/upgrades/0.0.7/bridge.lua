-- Alkali Processing, causticization and gravel leaching were renamed from their
-- volcanic names after this release.
local function assert_alkali(force)
  assert(force.technologies["nullius-alkali-processing"].researched, "lost Volcanic Alkali Processing research")
  for _, name in ipairs({"nullius-causticization", "nullius-gravel-leaching"}) do
    assert(force.recipes[name].enabled, "researched Alkali Processing lost " .. name)
  end
end

local function assert_control()
  local control = game.forces["alkali-control"]
  assert(not control.technologies["nullius-alkali-processing"].researched, "migration researched Alkali Processing")
  assert(not control.recipes["nullius-causticization"].enabled, "unresearched force has causticization")
end

remote.add_interface("release-upgrade", {
  seed = function()
    local force = game.forces.player
    force.technologies["nullius-volcanic-alkali-processing"].researched = true
    local surface = game.surfaces.nauvis
    surface.request_to_generate_chunks({64, 64}, 1)
    surface.force_generate_chunk_requests()
    for _, entity in pairs(surface.find_entities_filtered{area = {{56, 56}, {72, 72}}}) do entity.destroy() end
    local tiles = {}
    for x = 56, 72 do for y = 56, 72 do tiles[#tiles + 1] = {name = "concrete", position = {x, y}} end end
    surface.set_tiles(tiles)
    local plant = assert(surface.create_entity{name = "nullius-hydro-plant-1", position = {64, 64}, force = "player"})
    plant.set_recipe("nullius-volcanic-causticization")
    local leacher = assert(surface.create_entity{name = "nullius-chemical-plant-1", position = {60, 68}, force = "player"})
    leacher.set_recipe("nullius-volcanic-saline")
    storage.alkali_machines = {{entity = plant, recipe = "nullius-causticization"},
      {entity = leacher, recipe = "nullius-gravel-leaching"}}
    game.create_force("alkali-control")
  end,
  verify = function()
    assert(script.active_mods["nullius-star"] == candidate_version, "candidate was not loaded")
    local force = game.forces.player
    assert_alkali(force)
    for _, seeded in ipairs(storage.alkali_machines) do
      assert(seeded.entity.valid, "lost the machine set to " .. seeded.recipe)
      local recipe = seeded.entity.get_recipe()
      assert(recipe and recipe.name == seeded.recipe, seeded.entity.name .. " lost its recipe " .. seeded.recipe)
    end
    assert_control()
    force.reset_technology_effects()
    assert_alkali(force)
    assert_control()
    helpers.write_file("upgrade-result.json", helpers.table_to_json{status = "pass", alkali_research = true,
      machine_recipe = true, control_force = true}, false)
  end,
})

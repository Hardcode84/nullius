local CASE = "overcharged-assemblers"
local specs = require("__nullius-star__/shared/overcharged-assemblers")
local productivity = require("__nullius-star__/thermal-machine-config").productivity
local input_inventory = require("__nullius-star__/scenarios/inventory-api").crafting_input
local function check(ok, message)
  storage.assertions = storage.assertions + 1
  assert(ok, message)
end
local function near(actual, expected, message)
  check(math.abs(actual - expected) < 0.0001,
    message .. ": " .. tostring(actual) .. " expected " .. tostring(expected))
end
local function toggle(machine)
  local surface, position = machine.surface, machine.position
  local expected = machine.name:find("-overcharged$") and
    machine.name:gsub("-overcharged$", "") or machine.name .. "-overcharged"
  check(remote.call("nullius-test-transitions", "execute", machine), "transition missing")
  return assert(surface.find_entity(expected, position), "replacement missing " .. expected)
end
local function input(machine, name, count)
  check(machine.get_inventory(input_inventory).insert{name=name, count=count} == count,
    "fixture input " .. name)
end
local function place(surface, name, x, y)
  return assert(surface.create_entity{name=name, position={x,y}, force=game.forces.player})
end
local function power(surface, x, y)
  -- Given: an independent, unlimited electric source and connected substation.
  local grid = place(surface, "factorio-test-planner-grid", x + 5, y + 5)
  grid.power_production = 10000000000
  grid.electric_buffer_size = 10000000000
  place(surface, "substation", x + 5, y)
end
local function mechanical(surface, name, x, y, count)
  local machine = place(surface, name, x, y)
  machine.set_recipe("nullius-mechanical-pack")
  check(machine.get_recipe().name == "nullius-mechanical-pack", "science recipe selection")
  input(machine, "nullius-motor-1", count)
  input(machine, "nullius-iron-gear", count * 3)
  power(surface, x, y)
  return machine
end

script.on_nth_tick(1, function()
  script.on_nth_tick(1, nil)
  storage.assertions = 0
  storage.rows = {}
  local surface = game.surfaces.nauvis
  surface.request_to_generate_chunks({0,0}, 5)
  surface.force_generate_chunk_requests()
  for _, entity in ipairs(surface.find_entities_filtered{area={{-20,-20},{145,70}}}) do
    if entity.type ~= "character" then entity.destroy() end
  end
  local tiles = {}
  for x=-20,145 do for y=-20,70 do
    tiles[#tiles+1] = {name="landfill",position={x,y}}
  end end
  surface.set_tiles(tiles)
  local force = game.forces.player
  force.recipes["nullius-mechanical-pack"].enabled = true
  force.technologies["nullius-overcharged-assembly-2"].researched=true
  force.technologies["nullius-overcharged-assembly-3"].researched=true
  for _,spec in ipairs(specs) do force.recipes[spec.base].enabled=true end
  force.recipes["nullius-box-iron-plate"].enabled = true
  force.recipes["nullius-unbox-iron-plate"].enabled = true
  force.recipes["nullius-heat-pipe-1"].enabled = true
  check(prototypes.recipe["nullius-mechanical-pack"].allowed_effects.productivity,
    "science recipe must permit productivity")
  check(prototypes.recipe["nullius-box-iron-plate"].maximum_productivity == 0,
    "boxing recipe must reject productivity")
  check(prototypes.recipe["nullius-unbox-iron-plate"].maximum_productivity == 0,
    "unboxing recipe must reject productivity")
  for index, spec in ipairs(specs) do
    local base = prototypes.entity[spec.base]
    local name = spec.base .. "-overcharged"
    local variant = assert(prototypes.entity[name])
    near(variant.get_crafting_speed(), base.get_crafting_speed(), name .. " speed")
    near(variant.get_max_energy_usage(), base.get_max_energy_usage() * 10^spec.tier,
      name .. " power multiplier")
    near(variant.electric_energy_source_prototype.drain,
      base.electric_energy_source_prototype.drain * 10^spec.tier, name .. " drain")
    check(variant.electric_energy_source_prototype.usage_priority == "tertiary", name .. " priority")
    near(variant.effect_receiver.base_effect.productivity, productivity[spec.tier], name .. " productivity")
    check(variant.module_inventory_size == base.module_inventory_size, name .. " modules")
    for category in pairs(base.crafting_categories) do
      check(variant.crafting_categories[category], name .. " lost category " .. category)
    end
    for category in pairs(variant.crafting_categories) do
      check(base.crafting_categories[category] or category == "nullius-electromagnetism-1",
        name .. " gained category " .. category)
    end
    check(variant.items_to_place_this[1].name == spec.base, name .. " build item")
    check(variant.mineable_properties.products[1].name == spec.base, name .. " mining item")
    local expected_upgrade = base.next_upgrade and base.next_upgrade.name .. "-overcharged"
    check((variant.next_upgrade and variant.next_upgrade.name) == expected_upgrade,
      name .. " upgrade changed mode")
    local x = (index-1)*18
    local machine = mechanical(surface, spec.base, x, 0, 10)
    machine = toggle(machine)
    check(machine.get_recipe().name == "nullius-mechanical-pack", name .. " lost recipe")
    check(machine.get_inventory(input_inventory).get_item_count("nullius-motor-1") == 10,
      name .. " lost input")
    storage.rows[#storage.rows+1] = {machine=machine, tier=spec.tier}
  end

  -- Given: 100 iron plates for five real boxing crafts; productivity is disabled.
  local excluded = place(surface, "nullius-small-assembler-3-overcharged", 0, 25)
  excluded.set_recipe("nullius-box-iron-plate")
  input(excluded, "nullius-iron-plate", 100)
  power(surface, 0, 25)
  storage.excluded = excluded
  local unpack = place(surface, "nullius-small-assembler-3-overcharged", 0, 45)
  unpack.set_recipe("nullius-unbox-iron-plate")
  input(unpack, "nullius-box-iron-plate", 20)
  power(surface, 0, 45)
  storage.unpack = unpack

  -- Given: one ordinary craft. Switch halfway, then finish at the higher power.
  storage.switching = mechanical(surface, "nullius-small-assembler-1", 25, 25, 1)
  storage.reverse = mechanical(surface, "nullius-small-assembler-1-overcharged", 45, 25, 1)

  -- Act: toggle a stopped machine with modules, fluid, circuits and stored energy.
  local machine = place(surface, "nullius-medium-assembler-2", 70, 25)
  machine.set_recipe("nullius-heat-pipe-1")
  machine.disabled_by_script = true
  input(machine, "nullius-pipe-2", 2)
  input(machine, "nullius-aluminum-sheet", 2)
  check(machine.insert_fluid{name="nullius-water",amount=200} == 200, "fluid fixture")
  check(machine.get_module_inventory().insert{name="nullius-efficiency-module-1",count=1} == 1,
    "module fixture")
  machine.energy = machine.electric_buffer_size
  machine.health = machine.health / 2
  local health, energy = machine.health, machine.energy
  local pole = place(surface, "small-electric-pole", 75, 25)
  machine.get_wire_connector(defines.wire_connector_id.circuit_red, true).connect_to(
    pole.get_wire_connector(defines.wire_connector_id.circuit_red, true))
  machine = toggle(machine)
  near(machine.energy, energy, "switch created energy")
  near(machine.health, health, "switch changed health")
  check(machine.disabled_by_script, "switch enabled stopped machine")
  check(machine.get_module_inventory().get_item_count("nullius-efficiency-module-1") == 1,
    "switch lost module")
  near(machine.get_fluid_count("nullius-water"), 200, "switch lost fluid")
  check(machine.get_wire_connector(defines.wire_connector_id.circuit_red, false).connection_count == 1,
    "switch lost circuit wire")
  machine.energy = machine.electric_buffer_size
  machine = toggle(machine)
  near(machine.energy, machine.electric_buffer_size, "energy not clamped on return")
  near(machine.get_fluid_count("nullius-water"), 200, "return lost fluid")

  -- Expect: blueprints retain the variant and use the ordinary construction item.
  local inventory = game.create_inventory(1)
  inventory[1].set_stack{name="blueprint"}
  local blueprint = inventory[1]
  blueprint.create_blueprint{surface=surface,force=force,area={{-2,-2},{2,2}}}
  local entities = blueprint.get_blueprint_entities()
  check(#entities == 1 and entities[1].name == specs[1].base .. "-overcharged",
    "blueprint lost overcharged mode")
  inventory.destroy()
  local ghost = assert(surface.create_entity{name="entity-ghost",
    inner_name="nullius-small-assembler-1",position={90,25},force=force})
  ghost.set_recipe("nullius-mechanical-pack")
  ghost.tags = {overcharged_test = "preserve"}
  local ghost_pole = place(surface, "small-electric-pole", 94, 25)
  ghost.get_wire_connector(defines.wire_connector_id.circuit_red, true).connect_to(
    ghost_pole.get_wire_connector(defines.wire_connector_id.circuit_red, true))
  check(remote.call("nullius-test-transitions", "execute", ghost), "ghost toggle failed")
  local ghosts = surface.find_entities_filtered{position={90,25},type="entity-ghost"}
  check(#ghosts == 1 and ghosts[1].ghost_name == "nullius-small-assembler-1-overcharged",
    "ghost lost overcharged mode")
  check(ghosts[1].get_recipe().name == "nullius-mechanical-pack", "ghost lost recipe")
  check(ghosts[1].tags.overcharged_test == "preserve", "ghost lost tags")
  check(ghosts[1].get_wire_connector(defines.wire_connector_id.circuit_red, false).connection_count == 1,
    "ghost lost circuit wire")
end)

script.on_nth_tick(901, function()
  if game.tick == 0 then return end
  script.on_nth_tick(901, nil)
  for _, key in ipairs{"switching", "reverse"} do
    local machine = storage[key]
    local progress, bonus = machine.crafting_progress, machine.bonus_progress
    check(progress > 0.4 and progress < 0.6,
      key .. " not halfway through craft: " .. progress .. " status " .. machine.status)
    storage[key] = toggle(machine)
    near(storage[key].crafting_progress, progress, "switch lost paid work")
    near(storage[key].bonus_progress, bonus, "switch changed paid productivity")
    storage[key .. "_progress"] = progress
    storage[key .. "_bonus"] = bonus
  end
end)

script.on_nth_tick(19000, function()
  if game.tick == 0 then return end
  script.on_nth_tick(19000, nil)
  for _, row in ipairs(storage.rows) do
    local machine = row.machine
    check(machine.get_inventory(input_inventory).is_empty(), machine.name .. " left craft inputs")
    check(machine.products_finished == machine.get_output_inventory().get_item_count("nullius-mechanical-pack"),
      machine.name .. " production counter disagrees with output")
    near(machine.get_output_inventory().get_item_count("nullius-mechanical-pack") + machine.bonus_progress,
      10 * (1 + productivity[row.tier]), machine.name .. " incorrect yield")
  end
  check(storage.excluded.products_finished == 5, "excluded recipe craft count")
  check(storage.excluded.get_output_inventory().get_item_count("nullius-box-iron-plate") == 20,
    "ineligible recipe gained productivity")
  near(storage.excluded.bonus_progress, 0, "ineligible recipe accrued productivity")
  check(storage.unpack.get_output_inventory().get_item_count("nullius-iron-plate") == 100,
    "unboxing multiplied iron plates")
  check(storage.unpack.get_inventory(input_inventory).is_empty(), "unboxing retained input")
  for _, key in ipairs{"switching", "reverse"} do
    local machine = storage[key]
    local expected = storage[key .. "_bonus"]
    if key == "switching" then
      expected = expected + (1 - storage[key .. "_progress"]) * productivity[1]
    end
    check(machine.get_output_inventory().get_item_count("nullius-mechanical-pack") == 1,
      key .. " craft duplicated or lost")
    near(machine.bonus_progress, expected, key .. " earned unpaid productivity")
  end
  helpers.write_file("factorio-tests/" .. CASE .. ".json", helpers.table_to_json{
    schema=1,case=CASE,status="pass",failure_count=0,assertions=storage.assertions,
    tick=game.tick,factorio_version=script.active_mods.base}, false)
end)

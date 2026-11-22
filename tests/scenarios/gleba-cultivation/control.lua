-- given: probe research and its ordinary equipment. No imported materials or energy.
-- place: one probe android and its machines on the generated landing terrain.
-- connect: move the actual harvested items and machine products between inventories.
-- act: isolate culture by hand, propagate it, run both assays and build the biology lab.
-- run: until eight biochemistry units finish in a goop-fired lab.
-- expect: renewable mining, local fuel, a domesticated strain, and a usable biology lab.
local research = require("__nullius-star__/scripts/research")
local prefix = "nullius-"
local function check(value, message)
  storage.checks = storage.checks + 1
  assert(value, message)
end

local function take(source, target, item, count)
  local name = prefix .. item
  local stack = source.find_item_stack(name)
  check(stack and stack.count >= count, "missing " .. count .. " " .. name)
  local moved = {name = name, count = count, quality = stack.quality}
  if stack.spoil_tick > 0 then moved.spoil_percent = stack.spoil_percent end
  check(target.insert(moved) == count, "destination rejected " .. name)
  stack.count = stack.count - count
end

local function place(item, stock, pos)
  local surface, force = storage.body.surface, storage.body.force
  local name = prefix .. item
  check(stock.remove{name = name, count = 1} == 1, "missing equipment " .. name)
  local position = assert(surface.find_non_colliding_position(name, pos, 25, 1, true))
  local entity = assert(surface.create_entity{name = name, force = force, position = position})
  position = entity.position
  check(remote.call("nullius-test-transitions", "execute", entity), "mode switch failed " .. name)
  return assert(surface.find_entity(name .. "-nutrient", position), "missing nutrient " .. name)
end

local function batch(machine, recipe, count)
  local e, stock = storage.machines[machine], storage.body.get_main_inventory()
  local id = prefix .. recipe
  check(e.force.recipes[id].enabled, "locked recipe " .. id)
  e.set_recipe(id)
  check(e.get_recipe() and e.get_recipe().name == id, "machine rejected " .. id)
  for _, ingredient in pairs(e.get_recipe().ingredients) do
    take(stock, e.get_inventory(defines.inventory.crafter_input), ingredient.name:sub(9), count * ingredient.amount)
  end
  return {entity = e, initial = e.products_finished, count = count, recipe = id}
end

local function collect(inventory)
  local stock = storage.body.get_main_inventory()
  for _, item in pairs(inventory.get_contents()) do
    take(inventory, stock, item.name:sub(9), item.count)
  end
end

local function start_mining(name)
  local body = storage.body
  local resource = assert(body.surface.find_entities_filtered{name = prefix .. name, position = {0, 0}, radius = 40, limit = 1}[1])
  storage.resource, storage.richness = resource, resource.amount
  body.teleport(assert(body.surface.find_non_colliding_position("character", resource.position, 4, 0.5)))
  body.selected = resource
  body.mining_state = {mining = true, position = resource.position}
end

local operations = {
  {"crusher", "gleba-rock-crushing", 3},
  {"cell", "wild-culture-propagation", 2},
  {"cell", "gleba-rock-leaching", 1},
  {"cell", "gleba-biochemistry", 2},
  {"cell", "wild-culture-propagation", 4},
  {"cell", "gleba-rock-leaching", 2},
  {"cell", "gleba-biochemistry", 6},
}

local lab_materials = {
  {"furnace", "gleba-glass", 2},
  {"furnace", "gleba-iron-reduction", 5},
  {"foundry", "iron-plate", 4},
  {"foundry", "iron-rod", 1},
}

local function finish(job)
  if job.entity.products_finished < job.initial + job.count then return false end
  collect(job.entity.get_output_inventory())
  return true
end

local function make_lab_materials()
  if storage.material_job then
    if not finish(storage.material_job) then return end
    storage.material_job = nil
  end
  local step = lab_materials[storage.material_step]
  if step then
    if step[2] == "gleba-iron-reduction" and storage.fuel_batches < 2 then return end
    storage.material_job = batch(step[1], step[2], step[3])
    storage.material_step = storage.material_step + 1
  else
    check(storage.body.begin_crafting{recipe = "nullius-iron-gear", count = 1} == 1, "local gear handcraft failed")
    check(storage.body.begin_crafting{recipe = "pipe", count = 1} == 1, "local pipe handcraft failed")
    storage.material_step, storage.making_parts = nil, true
  end
end

local function supply_fuel()
  local m, stock = storage.machines, storage.body.get_main_inventory()
  if storage.fuel_batches == 2 then return end
  if storage.fuel_job then
    if m.chemical.get_output_inventory().is_empty() then return end
    collect(m.chemical.get_output_inventory())
    storage.fuel_job = nil
    storage.fuel_batches = storage.fuel_batches + 1
    if storage.fuel_batches == 1 then
      take(stock, m.cell.get_fuel_inventory(), "nutrient-goop", 3)
      for _, machine in ipairs({m.lab, m.furnace, m.foundry, m.miner}) do
        take(stock, machine.get_fuel_inventory(), "nutrient-goop", 1)
      end
    end
  elseif stock.get_item_count("nullius-wild-culture") > 0 and stock.get_item_count("nullius-crushed-gleba-rock") >= 2 then
    for _, machine in pairs(m) do
      local spent = machine.get_burnt_result_inventory()
      if spent.get_item_count("nullius-digestate") > 0 then
        collect(spent)
        storage.fuel_job = batch("chemical", "gleba-chemosynthesis", 1)
        return
      end
    end
  end
end

script.on_nth_tick(15, function(event)
  if event.tick == 0 then return end
  local force = game.forces.player
  if not storage.phase then
    storage.checks = 0
    research.complete_with_prerequisites(force.technologies["nullius-probe-gleba"])
    storage.phase = "land"
    return
  end
  local cultivation = force.technologies["nullius-wild-strain-cultivation"]
  if storage.step then
    supply_fuel()
    if storage.material_step then make_lab_materials() end
    local m = storage.machines
    local packs = m.cell.get_output_inventory()
    local count = packs.get_item_count("nullius-biochemistry-pack")
    if count > 0 then
      take(packs, m.lab.get_inventory(defines.inventory.lab_input), "biochemistry-pack", count)
      if not storage.research_started then
        check(force.add_research(cultivation), "cultivation research refused")
        storage.first_pack_tick = event.tick
        storage.research_started = true
      end
    end
  end
  if storage.phase == "land" then
    local s = game.planets["nullius-gleba"].surface
    storage.body = assert(s.find_entities_filtered{name = "character", force = force}[1])
    local wreck = assert(s.find_entities_filtered{name = "nullius-landing-main", force = force}[1])
    local stock = wreck.get_inventory(defines.inventory.chest)
    storage.wreck = wreck
    storage.machines = {
      crusher = place("crusher-1", stock, {0, 7}), cell = place("flotation-cell-1", stock, {8, 8}),
      chemical = place("chemical-plant-1", stock, {16, 8}), furnace = place("small-furnace-1", stock, {0, 16}),
      foundry = place("foundry-1", stock, {8, 16}), lab = place("lab-1", stock, {16, 16}),
    }
    check(not force.recipes["nullius-domesticate-wild-culture"].enabled, "domestication open at landing")
    check(table_size(cultivation.prerequisites) == 1 and cultivation.prerequisites["nullius-probe-gleba"]
      and cultivation.research_unit_count == 8 and cultivation.research_unit_energy == 1200, "cultivation gate")
    for name, prototype in pairs(prototypes.get_entity_filtered{{filter = "crafting-machine"}}) do
      assert(not prototype.crafting_categories["gleba-hand-sampling"], name .. " can isolate the first culture")
    end
    start_mining("microbial-mat")
    storage.phase = "mine-mats"
  elseif storage.phase == "mine-mats" then
    if not storage.isolating then
      if storage.body.get_item_count("nullius-mat-sample") < 3 then return end
      check(storage.body.begin_crafting{recipe = "nullius-isolate-wild-culture", count = 1} == 1, "manual isolation failed")
      storage.isolating = true
    end
    if storage.body.get_item_count("nullius-mat-sample") < 12 then return end
    check(storage.resource.valid and storage.resource.amount == storage.richness, "mat yield declined")
    start_mining("gleba-rock")
    storage.phase = "mine-rock"
  elseif storage.phase == "mine-rock" then
    if storage.body.get_item_count("nullius-gleba-rock") < 3 then return end
    storage.body.mining_state = {mining = false}
    check(storage.resource.valid and storage.resource.amount == storage.richness, "rock yield declined")
    local wreck_stock = storage.wreck.get_inventory(defines.inventory.chest)
    local miner = place("small-miner-1", wreck_stock, storage.resource.position)
    storage.machines.miner = miner
    check(wreck_stock.remove{name = "iron-chest", count = 1} == 1, "missing output chest")
    storage.mined = assert(miner.surface.create_entity{name = "iron-chest", position = miner.drop_position, force = force})
    storage.phase = "handcraft"
  elseif storage.phase == "handcraft" then
    if storage.body.crafting_queue_size ~= 0 then return end
    local stock = storage.body.get_main_inventory()
    check(stock.get_item_count("nullius-wild-culture") == 2 and stock.get_item_count("nullius-nutrient-goop") == 4,
      "incorrect manual yield")
    for _, key in ipairs({"crusher", "cell", "chemical", "lab"}) do
      take(stock, storage.machines[key].get_fuel_inventory(), "nutrient-goop", 1)
    end
    storage.step, storage.phase, storage.fuel_batches = 1, "factory", 0
  elseif storage.batch then
    if finish(storage.batch) then storage.batch = nil end
  elseif storage.phase == "factory" then
    local step = operations[storage.step]
    if step then
      storage.batch = batch(step[1], step[2], step[3])
      if step[2] == "gleba-biochemistry" and storage.research_started then storage.material_step = 1 end
      storage.step = storage.step + 1
    else
      storage.phase = "research"
    end
  elseif storage.phase == "research" and cultivation.researched then
    storage.researched_tick = event.tick
    storage.batch = batch("cell", "domesticate-wild-culture", 1)
    storage.phase = "assay"
  elseif storage.phase == "assay" then
    storage.batch = batch("cell", "gleba-microbiology", 1)
    storage.phase = "components"
  elseif storage.phase == "components" and storage.making_parts and storage.body.crafting_queue_size == 0 then
    check(storage.body.begin_crafting{recipe = "nullius-biology-lab", count = 1} == 1,
      "local lab handcraft failed enabled=" .. tostring(force.recipes["nullius-biology-lab"].enabled) ..
      " stock=" .. helpers.table_to_json(storage.body.get_main_inventory().get_contents()))
    storage.phase = "biology-lab"
  elseif storage.phase == "biology-lab" and storage.body.crafting_queue_size == 0 then
    local stock = storage.body.get_main_inventory()
    local lab = place("biology-lab", stock, {24, 16})
    take(stock, lab.get_inventory(defines.inventory.lab_input), "microbiology-pack", 1)
    check(lab.get_item_count("nullius-microbiology-pack") == 1, "biology lab rejected local assay")
    check(storage.mined.get_item_count("nullius-gleba-rock") > 0, "nutrient miner produced no rock")
    check(storage.machines.chemical.products_finished >= 2, "no sustained local fuel production")
    local goop = prototypes.item["nullius-nutrient-goop"]
    check(goop.spoil_result.name == "nullius-digestate" and goop.burnt_result.name == goop.spoil_result.name,
      "spent and spoiled goop must leave digestate")
    check(goop.get_spoil_ticks() == 15 * 3600 and prototypes.item["nullius-wild-culture"].get_spoil_ticks() == 10 * 3600,
      "incorrect spoilage windows")
    helpers.write_file("factorio-tests/gleba-cultivation.json", helpers.table_to_json{
      schema = 1, case = "gleba-cultivation", status = "pass", failure_count = 0,
      assertions = storage.checks, first_pack_tick = storage.first_pack_tick, researched_tick = storage.researched_tick, tick = event.tick, factorio_version = script.active_mods.base,
    }, false)
    script.on_nth_tick(15, nil)
    return
  end
end)

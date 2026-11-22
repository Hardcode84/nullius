-- given: probe and Nutrient Technology researched on Nauvis, and the wreck equipment. No imported materials or energy.
-- place: one probe android, the wreck machines, a nutrient miner on ferric rock and its chest.
-- connect: move the actual harvested items and machine products between inventories.
-- act: isolate culture by hand, keep mining mats, and run each machine when its inputs are ready.
-- run: until eight biochemistry units finish in a goop-fired lab and the biology lab is built.
-- expect: renewable mining, fixed and recycled goop, a domesticated strain, and a usable biology lab.
local research = require("__nullius-star__/scripts/research")
local prefix = "nullius-"
local BIOCHEMISTRY_PACKS = 8
local LEACHES, GLASS, REDUCTIONS, PLATES, RODS = 15, 3, 7, 4, 1
local DOMESTICATED = 2
local GOOP_STOCK = 6

local function check(value, message)
  storage.checks = storage.checks + 1
  assert(value, message)
end

local function stock() return storage.body.get_main_inventory() end
local function have(item) return stock().get_item_count(prefix .. item) end

local function take(source, target, item, count)
  local name = prefix .. item
  local stack = source.find_item_stack(name)
  check(stack and stack.count >= count, "missing " .. count .. " " .. name)
  local moved = {name = name, count = count, quality = stack.quality}
  if stack.spoil_tick > 0 then moved.spoil_percent = stack.spoil_percent end
  check(target.insert(moved) == count, "destination rejected " .. name)
  stack.count = stack.count - count
end

local function collect(inventory)
  for _, item in pairs(inventory.get_contents()) do
    take(inventory, stock(), item.name:sub(#prefix + 1), item.count)
  end
end

local function place(item, inventory, pos)
  local surface, force = storage.body.surface, storage.body.force
  local name = prefix .. item
  check(inventory.remove{name = name, count = 1} == 1, "missing equipment " .. name)
  local position = assert(surface.find_non_colliding_position(name, pos, 25, 1, true))
  local entity = assert(surface.create_entity{name = name, force = force, position = position})
  position = entity.position
  check(remote.call("nullius-test-transitions", "execute", entity), "mode switch failed " .. name)
  return assert(surface.find_entity(name .. "-nutrient", position), "missing nutrient " .. name)
end

-- Start count crafts of recipe in an idle machine with ingredients from the stock.
local function start(key, recipe, count)
  local e = storage.machines[key]
  local id = prefix .. recipe
  check(e.force.recipes[id].enabled, "locked recipe " .. id)
  e.set_recipe(id)
  check(e.get_recipe() and e.get_recipe().name == id, "machine rejected " .. id)
  for _, ingredient in pairs(e.get_recipe().ingredients) do
    take(stock(), e.get_inventory(defines.inventory.crafter_input), ingredient.name:sub(#prefix + 1),
      count * ingredient.amount)
  end
  storage.jobs[key] = {initial = e.products_finished, count = count, recipe = recipe}
end

-- Collect a finished job and count it. Returns true when the machine is idle.
local function idle(key)
  local job = storage.jobs[key]
  if not job then return true end
  local e = storage.machines[key]
  if e.products_finished < job.initial + job.count then return false end
  collect(e.get_output_inventory())
  storage.done[job.recipe] = (storage.done[job.recipe] or 0) + job.count
  storage.jobs[key] = nil
  return true
end

local function done(recipe) return storage.done[recipe] or 0 end

local function start_mining(name)
  local body = storage.body
  local resource = assert(body.surface.find_entities_filtered{name = prefix .. name, position = {0, 0}, radius = 40, limit = 1}[1])
  body.teleport(assert(body.surface.find_non_colliding_position("character", resource.position, 4, 0.5)))
  body.selected = resource
  body.mining_state = {mining = true, position = resource.position}
  return resource
end

-- Fuel the rock supply first: the first goop must keep the miner and crusher running.
local FUEL_ORDER = {"miner", "crusher", "chemical", "culture", "assay", "furnace", "foundry", "lab"}

-- Keep every machine fuelled from the stock and return spent fuel to it.
local function refuel()
  for _, key in ipairs(FUEL_ORDER) do
    local machine = storage.machines[key]
    local spent = machine.get_burnt_result_inventory()
    if not spent.is_empty() then collect(spent) end
    if machine.get_fuel_inventory().is_empty() and have("nutrient-goop") > 0 then
      take(stock(), machine.get_fuel_inventory(), "nutrient-goop", 1)
    end
  end
end

local CRUSHED_STOCK = 40

local function run_crusher()
  if not idle("crusher") or have("crushed-gleba-rock") >= CRUSHED_STOCK then return end
  local rock = storage.mined.get_inventory(defines.inventory.chest)
  local count = math.min(rock.get_item_count(prefix .. "gleba-rock"), 4)
  if count == 0 then return end
  take(rock, stock(), "gleba-rock", count)
  start("crusher", "gleba-rock-crushing", count)
end

-- Fixation takes rock only. Recycling needs five digestate per batch.
local function run_chemical()
  if not idle("chemical") or have("nutrient-goop") >= GOOP_STOCK or have("wild-culture") < 2 then return end
  if have("digestate") >= 5 and have("crushed-gleba-rock") >= 1 then
    start("chemical", "gleba-digestate-recycling", 1)
  elseif have("crushed-gleba-rock") >= 4 then
    start("chemical", "gleba-chemosynthesis", 1)
  end
end

-- One culture is always kept back for propagation.
local function run_culture(cultivated)
  if not idle("culture") then return end
  local wild = have("wild-culture")
  if cultivated and done("domesticate-wild-culture") < DOMESTICATED and wild >= 3 then
    start("culture", "domesticate-wild-culture", 1)
  elseif cultivated and done("domesticate-wild-culture") >= DOMESTICATED and done("gleba-microbiology") == 0
      and wild >= 3 and have("glass") >= 1 then
    start("culture", "gleba-microbiology", 1)
  elseif wild < 12 and wild >= 1 and have("mat-sample") >= 2 then
    start("culture", "wild-culture-propagation", 1)
  elseif done("gleba-rock-leaching") < LEACHES and wild >= 2 and have("crushed-gleba-rock") >= 2 then
    start("culture", "gleba-rock-leaching", 1)
  end
end

local function run_assay()
  if not idle("assay") or done("gleba-biochemistry") >= BIOCHEMISTRY_PACKS then return end
  if have("wild-culture") >= 4 and have("leach-residue") >= 3 and have("ferric-concentrate") >= 2 then
    start("assay", "gleba-biochemistry", 1)
  end
end

-- Lab materials use only residue and concentrate beyond the next assay batch.
local function run_furnace()
  if not idle("furnace") then return end
  local assays_left = done("gleba-biochemistry") < BIOCHEMISTRY_PACKS
  local residue = have("leach-residue") - (assays_left and 3 or 0)
  local ferric = have("ferric-concentrate") - (assays_left and 2 or 0)
  if done("gleba-glass") < GLASS and residue >= 2 then
    start("furnace", "gleba-glass", 1)
  elseif done("gleba-iron-reduction") < REDUCTIONS and ferric >= 2 and have("nutrient-goop") >= 2 then
    start("furnace", "gleba-iron-reduction", 1)
  end
end

local function run_foundry()
  if not idle("foundry") or have("iron-ingot") < 4 then return end
  if done("iron-plate") < PLATES then
    start("foundry", "iron-plate", 1)
  elseif done("iron-rod") < RODS then
    start("foundry", "iron-rod", 1)
  end
end

local function run_lab(force, cultivation)
  local packs = have("biochemistry-pack")
  if packs == 0 then return end
  take(stock(), storage.machines.lab.get_inventory(defines.inventory.lab_input), "biochemistry-pack", packs)
  if not storage.first_pack_tick then
    check(force.add_research(cultivation), "cultivation research refused")
    storage.first_pack_tick = game.tick
  end
end

local function make_parts()
  if storage.parts or done("iron-plate") < PLATES or done("iron-rod") < RODS then return end
  check(storage.body.begin_crafting{recipe = "nullius-iron-gear", count = 1} == 1, "local gear handcraft failed")
  check(storage.body.begin_crafting{recipe = "pipe", count = 1} == 1, "local pipe handcraft failed")
  storage.parts = true
end

local function land(force, cultivation)
  local s = game.planets["nullius-gleba"].surface
  storage.body = assert(s.find_entities_filtered{name = "character", force = force}[1])
  local wreck = assert(s.find_entities_filtered{name = "nullius-landing-main", force = force}[1])
  local supplies = wreck.get_inventory(defines.inventory.chest)
  storage.machines = {
    crusher = place("crusher-1", supplies, {0, 7}), culture = place("flotation-cell-1", supplies, {8, 8}),
    assay = place("flotation-cell-1", supplies, {8, 0}), chemical = place("chemical-plant-1", supplies, {16, 8}),
    furnace = place("small-furnace-1", supplies, {0, 16}), foundry = place("foundry-1", supplies, {8, 16}),
    lab = place("lab-1", supplies, {16, 16}),
  }
  storage.supplies = supplies
  check(not force.recipes["nullius-domesticate-wild-culture"].enabled, "domestication open at landing")
  check(table_size(cultivation.prerequisites) == 1 and cultivation.prerequisites["nullius-nutrient-technology"]
    and cultivation.research_unit_count == 8 and cultivation.research_unit_energy == 1200, "cultivation gate")
  for name, prototype in pairs(prototypes.get_entity_filtered{{filter = "crafting-machine"}}) do
    assert(not prototype.crafting_categories["gleba-hand-sampling"], name .. " can isolate the first culture")
  end
  local rock = assert(s.find_entities_filtered{name = "nullius-gleba-rock", position = {0, 0}, radius = 40, limit = 1}[1])
  local miner = place("small-miner-1", supplies, rock.position)
  storage.machines.miner = miner
  check(supplies.remove{name = "iron-chest", count = 1} == 1, "missing output chest")
  storage.mined = assert(s.create_entity{name = "iron-chest", position = miner.drop_position, force = force})
  storage.rock, storage.rock_richness = rock, rock.amount
  storage.mat = start_mining("microbial-mat")
  storage.mat_richness = storage.mat.amount
end

local function build_lab()
  check(storage.body.begin_crafting{recipe = "nullius-biology-lab", count = 1} == 1,
    "local lab handcraft failed stock=" .. helpers.table_to_json(stock().get_contents()))
  storage.phase = "biology-lab"
end

local function finish(event)
  local lab = place("biology-lab", stock(), {24, 16})
  take(stock(), lab.get_inventory(defines.inventory.lab_input), "microbiology-pack", 1)
  check(lab.get_item_count("nullius-microbiology-pack") == 1, "biology lab rejected local assay")
  check(storage.mat.valid and storage.mat.amount == storage.mat_richness, "mat yield declined")
  check(storage.rock.valid and storage.rock.amount == storage.rock_richness, "rock yield declined")
  -- The miner is the only rock source after landing.
  check(done("gleba-rock-crushing") > 0, "nutrient miner produced no rock")
  check(done("gleba-chemosynthesis") > 0, "no goop fixed from rock")
  check(done("gleba-digestate-recycling") > 0, "spent goop was not recycled")
  check(have("digestate") < 5, "digestate accumulated beyond one recycling batch")
  local goop = prototypes.item["nullius-nutrient-goop"]
  check(goop.spoil_result.name == "nullius-digestate" and goop.burnt_result.name == goop.spoil_result.name,
    "spent and spoiled goop must leave digestate")
  check(goop.get_spoil_ticks() == 15 * 3600 and prototypes.item["nullius-wild-culture"].get_spoil_ticks() == 10 * 3600,
    "incorrect spoilage windows")
  helpers.write_file("factorio-tests/gleba-cultivation.json", helpers.table_to_json{
    schema = 1, case = "gleba-cultivation", status = "pass", failure_count = 0,
    assertions = storage.checks, first_pack_tick = storage.first_pack_tick, researched_tick = storage.researched_tick,
    tick = event.tick, factorio_version = script.active_mods.base, completed = storage.done,
  }, false)
  script.on_nth_tick(15, nil)
end

script.on_nth_tick(15, function(event)
  if event.tick == 0 then return end
  local force = game.forces.player
  local cultivation = force.technologies["nullius-wild-strain-cultivation"]
  if not storage.phase then
    storage.checks, storage.jobs, storage.done = 0, {}, {}
    research.complete_with_prerequisites(force.technologies["nullius-nutrient-technology"])
    storage.phase = "land"
    return
  end
  if storage.phase == "land" then
    land(force, cultivation)
    storage.phase = "isolate"
    return
  end
  if storage.phase == "isolate" then
    if not storage.isolating then
      if have("mat-sample") < 3 then return end
      check(storage.body.begin_crafting{recipe = "nullius-isolate-wild-culture", count = 1} == 1, "manual isolation failed")
      storage.isolating = true
    end
    if storage.body.crafting_queue_size ~= 0 then return end
    check(have("wild-culture") == 2 and have("nutrient-goop") == 4, "incorrect manual yield")
    storage.phase = "factory"
  end
  if storage.phase == "factory" then
    refuel()
    run_crusher()
    run_chemical()
    run_culture(cultivation.researched)
    run_assay()
    run_furnace()
    run_foundry()
    run_lab(force, cultivation)
    make_parts()
    if cultivation.researched and not storage.researched_tick then storage.researched_tick = event.tick end
    if storage.researched_tick and done("gleba-microbiology") > 0 and storage.parts
        and storage.body.crafting_queue_size == 0 then
      build_lab()
    end
  elseif storage.phase == "biology-lab" and storage.body.crafting_queue_size == 0 then
    finish(event)
  end
end)

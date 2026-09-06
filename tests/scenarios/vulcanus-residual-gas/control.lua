local CASE = "vulcanus-residual-gas"
local GAS = "nullius-compressed-volcanic-gas"
local failures, assertions = {}, 0
local function check(ok, message)
  assertions = assertions + 1
  if not ok then failures[#failures + 1] = message end
end
local function finish()
  script.on_nth_tick(30, nil)
  local result = {schema=1, case=CASE, status=#failures == 0 and "pass" or "fail",
    factorio_version=script.active_mods.base, tick=game.tick, assertions=assertions,
    failure_count=#failures, failures=failures, observations={argon=storage.argon,
      source_cycles=storage.source.products_finished,
      separation_cycles=storage.consumer.products_finished,
      connection_tick=600, air_supplied=storage.air_supplied}}
  helpers.write_file("factorio-tests/" .. CASE .. ".json", helpers.table_to_json(result), false)
  if #failures > 0 then error(helpers.table_to_json(result)) end
end
local function research(tech, seen)
  if seen[tech.name] then return end
  seen[tech.name] = true
  for _, pack in pairs(tech.research_unit_ingredients) do
    check(pack.name ~= "nullius-physics-pack", "physics-consuming research: " .. tech.name)
  end
  for _, prerequisite in pairs(tech.prerequisites) do research(prerequisite, seen) end
  tech.researched = true
end
local function box(machine, name)
  for i=1,#machine.fluidbox do
    local filter = machine.fluidbox.get_filter(i)
    if filter and filter.name == name then return i end
  end
  error("missing fluid box for " .. name)
end
local function build(surface, name, position)
  local entity = surface.create_entity{name=name, position=position, force=game.forces.player}
  check(entity ~= nil, "failed placement: " .. name)
  return entity
end
script.on_nth_tick(30, function()
  if not storage.source then
    local force = game.forces.player
    check(not force.recipes["nullius-vulcanus-residual-gas"].enabled, "trace separation starts locked")
    research(force.technologies["nullius-air-separation-2"], {})
    research(force.technologies["nullius-pneumatic-technology"], {})
    check(force.recipes["nullius-vulcanus-residual-gas"].enabled, "air separation unlocks local trace gas")
    local planet = game.planets["nullius-vulcanus"]
    local surface = planet.surface or planet.create_surface()
    surface.request_to_generate_chunks({0,0}, 2)
    surface.force_generate_chunk_requests()
    for _, e in pairs(surface.find_entities_filtered{area={{-20,-20},{20,20}}}) do e.destroy() end
    local tiles = {}
    for x=-20,20 do for y=-20,20 do tiles[#tiles+1]={name="volcanic-soil-dark", position={x,y}} end end
    surface.set_tiles(tiles, true, false, false, false)
    storage.surface = surface
    storage.source = build(surface, "nullius-distillery-1-pneumatic", {0,0})
    storage.consumer = build(surface, "nullius-distillery-1-pneumatic", {3,-8})
    check(storage.source.set_recipe("nullius-vulcanus-residual-gas") ~= nil, "source selects trace recipe")
    check(storage.consumer.set_recipe("nullius-residual-separation") ~= nil, "consumer selects argon recipe")
    storage.air_supplied, storage.argon = 0, 0
    storage.fuel_supplied = {0, 0}
  end
  if game.tick == 600 then
    check(storage.consumer.products_finished == 0, "argon cannot run before the pipe connection")
    for y=-5,-3 do build(storage.surface, "pipe", {2,y}) end
  end
  local source, consumer = storage.source, storage.consumer
  for i, machine in ipairs({source, consumer}) do
    storage.fuel_supplied[i] = storage.fuel_supplied[i] + machine.insert_fluid{
      name=GAS, amount=2000-storage.fuel_supplied[i]}
  end
  if storage.air_supplied < 15000 then
    storage.air_supplied = storage.air_supplied + source.insert_fluid{
      name="nullius-air", amount=15000-storage.air_supplied}
  end
  -- Declared sinks remove co-products; residual gas travels only through pipes.
  for _, name in pairs({"nullius-carbon-dioxide", "nullius-sulfur-dioxide"}) do
    source.fluidbox[box(source, name)] = nil
  end
  for _, name in pairs({"nullius-trace-gas", "nullius-water", "nullius-argon"}) do
    local i = box(consumer, name)
    local fluid = consumer.fluidbox[i]
    if fluid and name == "nullius-argon" then storage.argon = storage.argon + fluid.amount end
    consumer.fluidbox[i] = nil
  end
  if storage.argon >= 120-0.001 or game.tick >= 15000 then
    check(storage.argon >= 120-0.001, "connected separation must produce 120 argon")
    check(source.products_finished == 100, "source must consume exactly 100 batches of air")
    check(consumer.products_finished == 6, "consumer must separate six batches of local residual gas")
    check(storage.air_supplied == 15000, "air supply must stay within the fixture")
    check(not game.forces.player.technologies["nullius-air-separation-4"].researched,
      "post-physics air separation must remain locked")
    finish()
  end
end)

-- given: one normal-richness resource and a void-powered native drill per case
-- place: each pair 16 tiles apart on an empty surface
-- connect: none; fluid stays in the drill's output buffer
-- act: mine for 61 ticks with no productivity bonus
-- expect: one guaranteed 10-unit output at its specified/default temperature
local fluid_api = require("__nullius-star__/scenarios/fluid-api")
local cases = {
  {resource="nullius-fumarole", fluid="nullius-volcanic-gas", temperature=200},
  {resource="sulfuric-acid-geyser", fluid="nullius-hydrogen-chloride"},
  {resource="offshore-oil", fluid="nullius-volcanic-gas", temperature=200, optional_mod="cargo-ships"},
}
local assertions = 0
local function check(ok, message)
  assertions = assertions + 1
  assert(ok, message)
end
script.on_nth_tick(1, function()
  script.on_nth_tick(1, nil)
  local surface = game.create_surface("fluid-resource-test", {width=96,height=32,autoplace_controls={}})
  surface.request_to_generate_chunks({0,0},2)
  surface.force_generate_chunk_requests()
  for _, entity in pairs(surface.find_entities()) do entity.destroy() end
  check(game.forces.player.mining_drill_productivity_bonus == 0, "no mining productivity")
  storage.rows = {}
  for i, case in ipairs(cases) do
    local prototype = prototypes.entity[case.resource]
    if prototype then
      local products = prototype.mineable_properties.products
      check(#products == 1, case.resource .. " product count")
      local product = products[1]
      check(product.type == "fluid" and product.name == case.fluid, case.resource .. " fluid identity")
      check((product.amount or product.amount_min) == 10 and
        (product.amount or product.amount_max) == 10, case.resource .. " fixed amount")
      local modern = string.match(script.active_mods.base, "^2%.1%.") ~= nil
      check((modern and product.independent_probability or product.probability) == 1,
        case.resource .. " guaranteed output")
      if modern then
        check(product.shared_probability.min == 0 and product.shared_probability.max == 1,
          case.resource .. " unrestricted shared probability")
      end
      local temperature = case.temperature or prototypes.fluid[case.fluid].default_temperature
      check((product.temperature or prototypes.fluid[case.fluid].default_temperature) == temperature,
        case.resource .. " resolved temperature")
      local position = {x=(i-2)*16,y=0}
      local resource = surface.create_entity{name=case.resource,position=position,
        amount=prototype.normal_resource_amount or 1000}
      check(resource ~= nil, case.resource .. " placed")
      local drill = surface.create_entity{name="factorio-test-fluid-resource-drill",position=position,force="player"}
      check(drill ~= nil, case.resource .. " drill placed")
      table.insert(storage.rows,{drill=drill,fluid=case.fluid,temperature=temperature,resource=case.resource})
    else
      check(case.optional_mod == "cargo-ships" and (not script.active_mods[case.optional_mod]
        or not settings.startup.offshore_oil_enabled.value),
        "missing required resource " .. case.resource)
    end
  end
  storage.setup_assertions = assertions
end)
script.on_nth_tick(61, function(event)
  if event.tick == 0 then return end
  script.on_nth_tick(61, nil)
  assertions = storage.setup_assertions
  for _, row in ipairs(storage.rows) do
    local fluid = fluid_api.get(row.drill,1)
    check(fluid ~= nil and fluid.name == row.fluid, row.resource .. " extracted identity")
    check(math.abs(fluid.amount - 10) < 0.0001, row.resource .. " extracted amount: " .. fluid.amount)
    check(math.abs(fluid.temperature - row.temperature) < 0.0001, row.resource .. " extracted temperature")
  end
  helpers.write_file("factorio-tests/fluid-resource-products.json", helpers.table_to_json({
    schema=1,case="fluid-resource-products",status="pass",factorio_version=script.active_mods.base,
    tick=game.tick,assertions=assertions,resources=#storage.rows,failure_count=0,failures={},
  }), false)
end)

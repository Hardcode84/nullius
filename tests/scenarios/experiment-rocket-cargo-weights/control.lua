-- given: resolved item prototypes; no entities.
-- place: nothing.
-- connect: nothing.
-- act: read each candidate cargo item's engine-computed weight, and each
--   electrolysis machine's power and speed.
-- run: one scheduled read.
-- expect: observations give the rocket lift and the items per launch, because
--   engine-derived weights exist only at runtime.
local CASE = "experiment-rocket-cargo-weights"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local CARGO = {
  "space-platform-foundation", "space-platform-starter-pack", "thruster",
  "cargo-bay", "cargo-landing-pad", "rocket-fuel", "nullius-box-rocket-fuel",
  "nullius-rutile", "nullius-box-rutile",
  "nullius-titanium-ingot", "nullius-box-titanium-ingot",
  "nullius-titanium-plate", "nullius-box-titanium-plate",
  "nullius-titanium-sheet", "nullius-box-titanium-sheet",
  "nullius-aluminum-sheet", "nullius-box-aluminum-sheet",
  "nullius-aluminum-rod", "nullius-box-aluminum-rod",
  "nullius-iron-ingot", "nullius-box-iron-ingot",
  "nullius-steel-beam", "nullius-box-steel-beam",
  "nullius-carbon-composite", "nullius-box-carbon-composite",
  "nullius-insulation", "nullius-box-insulation",
  "nullius-sensor-node-2", "nullius-haste-module-3",
  "nullius-rocket", "nullius-silo", "nullius-satellite", "nullius-probe",
  "nullius-rocket-stage",
  -- Propellant carriers.
  "nullius-canister", "nullius-hydrogen-canister", "nullius-box-hydrogen-canister",
  "processed-fuel", "nullius-box-methanol-canister", "nullius-diesel-canister",
  "barrel", "nullius-hydrogen-barrel", "nullius-compressed-hydrogen-barrel",
  "nullius-oxygen-barrel", "nullius-compressed-oxygen-barrel",
  "nullius-methane-barrel", "nullius-compressed-methane-barrel",
  "nullius-carbon-monoxide-barrel",
  "nullius-ice", "nullius-box-ice", "nullius-water-barrel",
  -- Draft platform component inputs.
  "nullius-steel-plate", "nullius-ceramic-powder", "nullius-heat-pipe-2",
  "nullius-motor-2", "nullius-grid-battery-1", "nullius-processor-1", "radar",
  "nullius-solar-panel-1",
}

script.on_nth_tick(30, function()
  script.on_nth_tick(30, nil)
  local ROCKET_LIFT = prototypes.utility_constants.default_rocket_lift_weight
  local failures = {}
  local observations = {rocket_lift_weight = ROCKET_LIFT, items = {}}
  for _, name in ipairs(CARGO) do
    local item = prototypes.item[name]
    if item then
      observations.items[name] = {
        weight = item.weight,
        stack_size = item.stack_size,
        per_launch = math.floor(ROCKET_LIFT / item.weight),
      }
    else
      failures[#failures + 1] = "unknown item " .. name
    end
  end
  -- A 1 kg item boxed five to a box: the packaging recipe without productivity
  -- support clamps to one stack per launch, the uncapped one takes half the
  -- contents, and coefficient 1 takes the full contents.
  local BOX_WEIGHTS = {
    ["factorio-test-box-clamped"] = ROCKET_LIFT / 50,
    ["factorio-test-box-uncapped"] = 2500,
    ["factorio-test-box-equal"] = 5000,
  }
  observations.box_fixtures = {}
  for name, expected in pairs(BOX_WEIGHTS) do
    local weight = prototypes.item[name].weight
    local recipe = prototypes.recipe[name]
    observations.box_fixtures[name] = {weight = weight, hidden = recipe.hidden,
      allow_decomposition = recipe.allow_decomposition, item_hidden = prototypes.item[name].hidden}
    if math.abs(weight - expected) > 0.001 then
      failures[#failures + 1] = name .. " weight " .. weight .. ", expected " .. expected
    end
  end
  observations.packaging_recipes = {}
  for _, name in ipairs({"nullius-box-titanium-sheet", "nullius-boxed-titanium-sheet"}) do
    local recipe = prototypes.recipe[name]
    observations.packaging_recipes[name] = {hidden = recipe.hidden,
      allow_decomposition = recipe.allow_decomposition, maximum_productivity = recipe.maximum_productivity}
  end
  observations.electrolyzers = {}
  for name, entity in pairs(prototypes.get_entity_filtered{{filter = "crafting-category", crafting_category = "nullius-electrolysis"}}) do
    observations.electrolyzers[name] = {
      energy_usage_watts = entity.get_max_energy_usage() * 60,
      crafting_speed = entity.get_crafting_speed(),
    }
  end
  local silo = prototypes.entity["nullius-silo"]
  observations.silo = {
    launch_to_space_platforms = silo.launch_to_space_platforms,
    can_launch_without_landing_pads = silo.can_launch_without_landing_pads,
    rocket_inventory_size = silo.rocket_entity_prototype.get_inventory_size(defines.inventory.cargo_unit),
  }
  local result = {
    schema = 1,
    case = CASE,
    status = (#failures == 0) and "pass" or "fail",
    factorio_version = script.active_mods.base,
    tick = game.tick,
    assertions = #CARGO + 3,
    failure_count = #failures,
    failures = failures,
    observations = observations,
  }
  helpers.write_file(RESULT, helpers.table_to_json(result), false)
  if #failures > 0 then error(helpers.table_to_json(result)) end
end)

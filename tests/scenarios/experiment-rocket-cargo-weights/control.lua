-- given: resolved item prototypes; no entities.
-- place: nothing.
-- connect: nothing.
-- act: read each candidate cargo item's engine-computed weight.
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
    assertions = #CARGO,
    failure_count = #failures,
    failures = failures,
    observations = observations,
  }
  helpers.write_file(RESULT, helpers.table_to_json(result), false)
  if #failures > 0 then error(helpers.table_to_json(result)) end
end)

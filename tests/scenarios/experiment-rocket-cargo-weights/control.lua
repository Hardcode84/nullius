-- given: resolved item prototypes; no entities.
-- place: nothing.
-- connect: nothing.
-- act: read each candidate cargo item's engine-computed weight, and each
--   electrolysis machine's power and speed.
-- run: one scheduled read.
-- expect: observations give the rocket lift and the items per launch, because
--   resolved weights exist only at runtime; Nullius items follow the declared
--   weight rule, boxes weigh exactly half their contents, no item weighs
--   more than a thousand launches, and non-productivity categories resolve
--   with productivity capped at zero.
local astronomy = require("__nullius-star__/shared/astronomy")
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
  -- Wood chain.
  "nullius-tree", "nullius-tree-seed", "nullius-wood", "nullius-wood-chip", "nullius-box-wood-chip",
}

script.on_nth_tick(30, function()
  script.on_nth_tick(30, nil)
  local ROCKET_LIFT = prototypes.utility_constants.default_rocket_lift_weight
  local failures = {}
  local assertions = #CARGO
  local function check(ok, message)
    assertions = assertions + 1
    if not ok then failures[#failures + 1] = message end
  end
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
  -- Nullius declares weights: item ingredients plus 100 grams per fluid unit,
  -- over expected item products, times the coefficient, at least one gram.
  -- Items weighed through a same-named recipe must match; an item closing a
  -- recipe loop keeps the default weight. Boxes must weigh exactly half their
  -- contents.
  local DEFAULT = prototypes.utility_constants.default_item_weight
  local DECLARED = {["nullius-align-concordance-satellite"] = true,
    ["nullius-satellite"]=true,["nullius-probe"]=true,["nullius-blank-recording-module"]=true,["nullius-box-blank-recording-module"]=true}
  for _,planet in ipairs(astronomy.planets) do
    local name="nullius-"..planet.."-interferometric-recording"
    DECLARED[name]=true
    check(prototypes.item[name].weight==1000 and prototypes.item[name].stack_size==50,"recording cargo "..planet)
  end
  check(prototypes.item["nullius-blank-recording-module"].weight==1000,"blank cargo")
  local blank_box=prototypes.item["nullius-box-blank-recording-module"]
  check(blank_box.weight==5000,"boxed media preserves full contents weight")
  local slots=prototypes.entity["nullius-silo"].get_inventory_size(defines.inventory.rocket_silo_rocket)
  check(math.min(math.floor(ROCKET_LIFT/blank_box.weight),slots*blank_box.stack_size)*5==1000,
    "boxed media cannot increase blanks per launch")
  local function expected_count(product)
    local amount = product.amount or (product.amount_min + product.amount_max) / 2
    return amount * (product.probability or 1) + (product.extra_count_fraction or 0)
  end
  observations.rule_items, observations.loop_defaults = 0, {}
  for name, item in pairs(prototypes.item) do
    local cursor_only = item.flags and item.flags["only-in-cursor"] and item.flags["spawnable"]
    local launched = #item.rocket_launch_products > 0
    if cursor_only then
      check(item.weight == 0, name .. " cursor-only item weighs " .. item.weight)
    elseif launched then
      -- The engine makes an item with launch products fill a rocket.
      check(item.weight == ROCKET_LIFT, name .. " launch item weighs " .. item.weight)
    else
      check(item.weight >= 1 and item.weight <= ROCKET_LIFT * 1000, name .. " weighs " .. item.weight)
    end
    local recipe = prototypes.recipe[name]
    if not cursor_only and not launched and string.sub(name, 1, 8) == "nullius-" and not DECLARED[name] and recipe
        and not recipe.hidden and recipe.allow_decomposition then
      local recipe_weight, products = 0, 0
      for _, ingredient in pairs(recipe.ingredients) do
        recipe_weight = recipe_weight + ingredient.amount *
          (ingredient.type == "fluid" and 100 or prototypes.item[ingredient.name].weight)
      end
      for _, product in pairs(recipe.products) do
        if product.type == "item" then products = products + expected_count(product) end
      end
      local expected = math.max(1, recipe_weight / products * item.ingredient_to_weight_coefficient)
      observations.rule_items = observations.rule_items + 1
      if math.abs(item.weight - expected) > expected * 1e-6 then
        observations.loop_defaults[name] = expected
        check(item.weight == DEFAULT, name .. " weighs " .. item.weight .. ", rule gives " .. expected)
      end
      if string.sub(name, 1, 12) == "nullius-box-" then
        check(math.abs(item.weight - expected) <= expected * 1e-6, name .. " is not half its contents")
      end
    end
  end
  -- Recipes in Nullius non-productivity categories cannot gain productivity.
  for _, name in ipairs({"nullius-water-barrel", "empty-nullius-water-barrel",
      "nullius-water-electrolysis", "nullius-compressed-hydrogen"}) do
    check(prototypes.recipe[name].maximum_productivity == 0, name .. " allows productivity")
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
    rocket_inventory_size = silo.get_inventory_size(defines.inventory.rocket_silo_rocket),
  }
  local result = {
    schema = 1,
    case = CASE,
    status = (#failures == 0) and "pass" or "fail",
    factorio_version = script.active_mods.base,
    tick = game.tick,
    assertions = assertions,
    failure_count = #failures,
    failures = failures,
    observations = observations,
  }
  helpers.write_file(RESULT, helpers.table_to_json(result), false)
  if #failures > 0 then error(helpers.table_to_json(result)) end
end)

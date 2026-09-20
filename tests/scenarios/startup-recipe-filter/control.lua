local filter = require("__nullius-star__/scripts/recipe_filter")
local cases = {
  ["factorio-test-filter-foreign"]=false,
  ["nullius-filter-native"]=true,
  ["factorio-test-filter-order"]=true,
  ["fill-nullius-filter"]=true,
  ["empty-nullius-filter"]=true,
  ["bpsb-filter"]=true,
  ["factorio-test-filter-primary"]=true,
  ["factorio-test-filter-additional"]=true,
  ["factorio-test-filter-multiple"]=false,
}
local assertions = 0
local function check(ok, message)
  assertions = assertions + 1
  assert(ok, message)
end
script.on_nth_tick(1, function()
  script.on_nth_tick(1, nil)
  local force = game.forces.player
  for name, exempt in pairs(cases) do
    local recipe = prototypes.recipe[name]
    check(recipe.hidden == not exempt, name .. " resolved visibility")
    check(recipe.enabled == exempt, name .. " resolved enabled default")
    check(recipe.allow_as_intermediate == exempt, name .. " intermediate selection")
    check(recipe.allow_decomposition == exempt, name .. " decomposition")
    local product = prototypes.item["factorio-test-product-" .. name]
    check(product.hidden == not exempt, name .. " product visibility")
  end
  for _, remaining in ipairs({-1, 0, 1, 2}) do
    storage.nullius_broken_status = remaining >= 0 and {["nullius-broken-filter"]=remaining} or nil
    local broken = force.recipes["nullius-broken-filter"]
    broken.enabled = true
    for name in pairs(cases) do force.recipes[name].enabled = true end
    for pass=1,2 do
      filter.apply(force)
      for name, expected in pairs(cases) do
        check(force.recipes[name].enabled == expected, name .. " exemption at pass " .. pass)
      end
      check(broken.enabled == (remaining > 0), "broken recipe follows remaining work")
      check(filter.broken_disabled(broken.name) == (remaining <= 0), "checkpoint predicate agrees")
    end
    for name in pairs(cases) do force.recipes[name].enabled = false end
    broken.enabled = false
    filter.apply(force)
    for name in pairs(cases) do check(not force.recipes[name].enabled, "filter must not unlock " .. name) end
    check(not broken.enabled, "filter must not unlock broken recipe")
  end
  storage.nullius_broken_status = {}
  check(filter.broken_disabled("nullius-broken-filter"), "missing count disables broken recipe")
  if script.active_mods["factorio-test-support"] then
    -- Full-mod run: exercise startup's on_force_created handler too.
    local created = game.create_force("recipe-filter-integration")
    for name, expected in pairs(cases) do
      -- Initialization filters the resolved defaults; it does not unlock recipes.
      local initial = prototypes.recipe[name].enabled
      check(created.recipes[name].enabled == (initial and expected), name .. " after force creation")
    end
    check(not created.recipes["nullius-broken-filter"].enabled, "new force disables broken recipe")
  end
  local result = {schema=1, case="startup-recipe-filter", status="pass",
    factorio_version=script.active_mods.base, tick=game.tick, assertions=assertions,
    failure_count=0, failures={}}
  helpers.write_file("factorio-tests/startup-recipe-filter.json", helpers.table_to_json(result), false)
end)

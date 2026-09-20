local expected = require("fixture")
local assertions = 0
local function check(ok, message)
  assertions = assertions + 1
  assert(ok, message)
end

script.on_nth_tick(1, function()
  script.on_nth_tick(1, nil)
  local modern = string.match(script.active_mods.base, "^2%.1%.") ~= nil
  for tier, minerals in ipairs(expected) do
    local name = "nullius-asteroid-miner-" .. tier
    local products = prototypes.item[name].rocket_launch_products
    check(#products == 6, name .. " return count")
    local seen = {}
    for _, product in ipairs(products) do
      local mineral = string.match(product.name, "^nullius%-guide%-drone%-(.+)%-1$")
      check(mineral ~= nil and minerals[mineral] ~= nil, name .. " return identity")
      check(not seen[mineral], name .. " duplicate return")
      seen[mineral] = true
      check(product.type == "item" and product.amount == 1, name .. " return amount")
      check(product.amount_min == nil and product.amount_max == nil, name .. " fixed amount")
      local probability = modern and product.independent_probability or product.probability
      check(probability == minerals[mineral], name .. " return probability: " .. mineral)
      if modern then
        check(product.shared_probability.min == 0 and product.shared_probability.max == 1,
          name .. " independent return rolls")
      end
    end
  end
  helpers.write_file("factorio-tests/asteroid-miner-products.json", helpers.table_to_json({
    schema=1, case="asteroid-miner-products", status="pass",
    factorio_version=script.active_mods.base, tick=game.tick, assertions=assertions,
    failure_count=0, failures={},
  }), false)
end)

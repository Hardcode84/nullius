-- given: the rock contracts in fixture.lua and an empty inventory
-- place: one rock at the origin on an empty generated surface
-- connect: none
-- act: mine one copy; destroy a second copy
-- run: 64 samples per rock at the first scheduled tick
-- expect: exact prototype contracts and only the declared item/count ranges
local cases = require("fixture")
local assertions = 0
local function check(ok, message)
  assertions = assertions + 1
  assert(ok, message)
end
local modern = string.match(script.active_mods.base, "^2%.1%.") ~= nil
local function check_products(name, actual, expected, loot)
  check(#actual == #expected, name .. " product count: " .. #actual .. " expected " .. #expected)
  for i, wanted in ipairs(expected) do
    local product = actual[i]
    local item = loot and not modern and product.item or product.name
    local lo = loot and not modern and product.count_min or (product.amount or product.amount_min)
    local hi = loot and not modern and product.count_max or (product.amount or product.amount_max)
    local p = modern and product.independent_probability or product.probability
    check(item == wanted[1], name .. " item " .. i .. ": " .. tostring(item))
    check(lo == wanted[2] and hi == wanted[3], name .. " bounds " .. i .. ": " .. tostring(lo) .. "," .. tostring(hi))
    check(p == wanted[4], name .. " probability " .. i .. ": " .. tostring(p))
    if modern then
      check(product.shared_probability.min == 0 and product.shared_probability.max == 1,
        name .. " independent rolls")
    end
  end
end
local function check_drops(name, stacks, expected)
  local counts, allowed = {}, {}
  for _, stack in pairs(stacks) do counts[stack.name] = (counts[stack.name] or 0) + stack.count end
  for _, product in ipairs(expected) do
    allowed[product[1]] = true
    local count = counts[product[1]] or 0
    check(count >= (product[4] == 1 and product[2] or 0) and count <= product[3], name .. " actual " .. product[1] .. " count " .. count)
  end
  for item in pairs(counts) do check(allowed[item], name .. " unexpected drop " .. item) end
end
script.on_nth_tick(1, function()
  script.on_nth_tick(1, nil)
  local surface = game.create_surface("rock-drop-test", {width=32,height=32, autoplace_controls={}})
  surface.request_to_generate_chunks({0,0},1)
  surface.force_generate_chunk_requests()
  for _, entity in pairs(surface.find_entities()) do entity.destroy() end
  local inventory = game.create_inventory(100)
  local rocks = 0
  local missing = {}
  for name, prototype in pairs(prototypes.get_entity_filtered{{filter="type",type="simple-entity"}}) do
    if string.find(name, "rock", 1, true) and
        (prototype.mineable_properties.minable or #(prototype.loot or {}) > 0) then
      if not cases[name] then table.insert(missing,name) end
    end
  end
  table.sort(missing)
  check(#missing == 0, "Missing rock contracts: " .. table.concat(missing, ", "))
  for name, contract in pairs(cases) do
    local prototype = prototypes.entity[name]
    check(prototype ~= nil, name .. " exists")
    check_products(name .. " mining", prototype.mineable_properties.products, contract.mining, false)
    check_products(name .. " loot", prototype.loot or {}, contract.loot, true)
    for sample=1,64 do
      local entity = surface.create_entity{name=name, position={0,0}, force="neutral"}
      check(entity ~= nil, name .. " placed for mining")
      check(entity.mine{inventory=inventory}, name .. " mined")
      check_drops(name .. " mining", inventory.get_contents(), contract.mining)
      inventory.clear()
      entity = surface.create_entity{name=name, position={0,0}, force="neutral"}
      check(entity.die(), name .. " destroyed")
      local stacks = {}
      for _, item in pairs(surface.find_entities_filtered{type="item-entity"}) do
        table.insert(stacks,{name=item.stack.name,count=item.stack.count})
        item.destroy()
      end
      check_drops(name .. " destruction", stacks, contract.loot)
    end
    rocks = rocks + 1
  end
  inventory.destroy()
  helpers.write_file("factorio-tests/rock-drops.json", helpers.table_to_json({
    schema=1,case="rock-drops",status="pass",factorio_version=script.active_mods.base,
    tick=game.tick,assertions=assertions,rocks=rocks,failure_count=0,failures={},
  }), false)
end)

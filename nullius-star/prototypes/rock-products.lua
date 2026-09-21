local products = {}
local modern = string.match(mods.base, "^2%.1%.") ~= nil
products.probability = modern and "independent_probability" or "probability"

-- Use explicit integer bounds on both engines. The old loot schema samples
-- fractional bounds differently from item products.
function products.loot(name, minimum, maximum, probability)
  minimum, maximum = math.floor(minimum), math.floor(maximum)
  if modern then
    return {type="item", name=name, amount_min=minimum, amount_max=maximum,
      independent_probability=probability or 1}
  end
  return {item=name, count_min=minimum, count_max=maximum, probability=probability or 1}
end

products.crystal = {
  mining = {
    {type="item", name="nullius-silica", amount=16},
    {type="item", name="nullius-alumina", amount=8},
  },
  loot = {
    products.loot("nullius-silica", 4, 12),
    products.loot("nullius-alumina", 2, 6),
  },
}
return products

local probability = require("prototypes.rock-products").probability
local results = {
  ["huge-volcanic-rock"] = {
    {type="item", name="stone", amount_min=10, amount_max=25},
    {type="item", name="nullius-graphite", amount_min=3, amount_max=8},
    {type="item", name="nullius-rutile", amount_min=1, amount_max=3},
  },
  ["big-volcanic-rock"] = {
    {type="item", name="stone", amount_min=5, amount_max=15},
    {type="item", name="nullius-graphite", amount_min=2, amount_max=5},
    {type="item", name="nullius-rutile", amount_min=0, amount_max=2, [probability]=0.5},
  },
}
for name, drops in pairs(results) do
  local rock = data.raw["simple-entity"][name]
  if rock then
    rock.minable.results = drops
    rock.loot = nil
  end
end

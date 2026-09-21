-- Alien Biomes 0.7.4 mining inputs, with base graphics for isolated loading.
local cases = require("__nullius-star__/scenarios/rock-drops/fixture")
local products = require("__nullius-star__/prototypes/rock-products")
local items = {}
for _, contract in pairs(cases) do
  for _, list in pairs(contract) do
    for _, product in ipairs(list) do items[product[1]] = true end
  end
end
for name in pairs(items) do
  if not data.raw.item[name] then
    local item = table.deepcopy(data.raw.item.stone)
    item.name = name
    data:extend({item})
  end
end
for name in pairs(cases) do
  if name ~= "huge-rock" and name ~= "big-rock" and name ~= "big-sand-rock" then
    local rock = table.deepcopy(data.raw["simple-entity"]["huge-rock"])
    rock.name = name
    rock.autoplace = nil
    rock.loot = nil
    if name == "nullius-crystal-rock" then
      rock.minable = {mining_time=8, results=table.deepcopy(products.crystal.mining)}
      rock.loot = table.deepcopy(products.crystal.loot)
    elseif name == "big-fulgora-rock" then
      rock.minable = {mining_time=2, results={{type="item",name="stone",amount_min=19,amount_max=25}}}
    elseif string.match(name, "^huge%-rock%-") then
      rock.minable = {mining_time=1.5, results={
        {type="item",name="stone",amount_min=20,amount_max=40},
        {type="item",name="coal",amount_min=0,amount_max=20},
      }}
    elseif string.match(name, "^big%-rock%-") then
      rock.minable = {mining_time=1, result="stone",count=20}
    elseif string.match(name, "^sand%-big%-rock%-") then
      rock.minable = {mining_time=1, results={{type="item",name="stone",amount_min=10,amount_max=20}}}
    end
    data:extend({rock})
  end
end
-- A non-rock can carry the rock deconstruction flag (Space Age shells do).
local shell = table.deepcopy(data.raw["simple-entity"]["big-rock"])
shell.name = "small-stomper-shell"
shell.minable = {mining_time=1, results={{type="item",name="stone",amount=1}}}
shell.loot = {products.loot("stone",1,1)}
data:extend({shell})
require("__nullius-star__/prototypes/rock")
assert(shell.minable.results[1].name == "stone" and shell.minable.results[1].amount == 1,
  "Rock rewrite must not change shell mining")
local loot = shell.loot[1]
assert((loot.name or loot.item) == "stone" and (loot.amount_min or loot.count_min) == 1,
  "Rock rewrite must not change shell loot")
require("__nullius-star__/prototypes/vulcanus-rocks")

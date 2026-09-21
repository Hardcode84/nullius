-- Item definitions isolate the trigger from the recipe-category port.
for _,name in ipairs({"nullius-lab-1","nullius-red-wire","nullius-broken-sensor-node",
  "nullius-probe","nullius-geology-pack"}) do
  data:extend({{type="item",name=name,stack_size=100,icon="__base__/graphics/icons/lab.png"}})
end
local recipe={type="recipe",name="nullius-geology-pack",enabled=false,
  ingredients={{type="item",name="stone",amount=1}},
  results={{type="item",name="nullius-geology-pack",amount=1}}}
data:extend({recipe})
require("salvage-wreckage")
require("salvage-technologies")

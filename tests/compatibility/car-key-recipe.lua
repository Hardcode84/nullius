-- Stub the external item and Nullius research boundary; use native circuit items.
data:extend({
  {type="recipe-category",name="small-crafting"},
  {type="item-subgroup",name="vehicle",group="other"},
})
local technology=table.deepcopy(data.raw.technology.automation)
technology.name="nullius-broadcasting-1"
technology.effects={}
data:extend({technology})
require("executor")

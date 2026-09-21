data:extend({{type="item-subgroup",name="pumping",group="logistics",order="z"}})
for tier=1,2 do
  local name="nullius-pump-" .. tier
  data:extend({{type="item",name=name,stack_size=50,place_result=name,
    icon="__base__/graphics/icons/pump.png"}})
end
require("pump-prototypes")
-- Match the base-pump upgrade group set by prototypes/override_final.lua.
data.raw.pump.pump.fast_replaceable_group="pump"

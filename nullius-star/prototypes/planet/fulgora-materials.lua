local ice = table.deepcopy(data.raw.item.ice)
ice.name = "nullius-ice"
ice.subgroup = "nullius-water-treatment"
ice.order = "nullius-aa"
ice.stack_size = 200
local hydrocarbons = table.deepcopy(data.raw.fluid["nullius-hydrocarbon-slurry"])
hydrocarbons.name = "nullius-filtered-hydrocarbons"
hydrocarbons.icons = {{icon="__base__/graphics/icons/fluid/heavy-oil.png", icon_size=64}}
hydrocarbons.order = "nullius-ja"
hydrocarbons.base_color = {r=0.30,g=0.16,b=0.05}
hydrocarbons.flow_color = {r=0.60,g=0.35,b=0.12}
data:extend({ice, hydrocarbons})

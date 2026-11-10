local slurry=table.deepcopy(data.raw.fluid['nullius-hydrocarbon-slurry'])
slurry.name='nullius-deep-slurry'
slurry.icons={{icon='__nullius-star__/graphics/icons/fluid/sludge.png',icon_size=64,tint={0.7,0.4,0.25}}}
slurry.base_color={0.22,0.12,0.08}
slurry.flow_color={0.55,0.3,0.16}
slurry.order='nullius-jb'
data:extend({slurry})
for i,name in ipairs({'copper-concentrate','copper-calcine'}) do
  data:extend({{type='item',name='nullius-'..name,
    icons={{icon='__base__/graphics/icons/copper-ore.png',icon_size=64,
      tint=i==1 and {0.65,0.75,0.5} or {0.6,0.35,0.25}}},
    subgroup='copper',order='nullius-c'..i,stack_size=100}})
end

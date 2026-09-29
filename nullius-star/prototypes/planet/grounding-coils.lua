local name='nullius-grounding-coil'
local icon='__space-age__/graphics/icons/lightning-collector.png'
local graphics=require('__space-age__.prototypes.entity.lightning-collector-graphics')
data:extend({
  {type='item',name=name,icon=icon,icon_size=64,subgroup='energy',order='nullius-dg',
    place_result=name,stack_size=50},
  {type='electric-energy-interface',name=name,icon=icon,icon_size=64,
    flags={'placeable-neutral','player-creation'},minable={mining_time=0.5,result=name},
    max_health=300,corpse='lightning-collector-remnants',
    collision_box={{-1.2,-1.2},{1.2,1.2}},selection_box={{-1.5,-1.5},{1.5,1.5}},
    collision_mask={layers={layer_43=true,object=true,player=true,item=true,water_tile=true,
      elevated_rail=true,nullius_grounding_land=true}},
    energy_source={type='electric',buffer_capacity='1MJ',usage_priority='tertiary',
      input_flow_limit='2MW',output_flow_limit='0W',drain='0W',render_no_power_icon=false},
    energy_usage='2MW',energy_production='0W',gui_mode='none',allow_copy_paste=false,
    animations=graphics.picture},
})
for _,boxed in ipairs({false,true}) do
  local recipe={type='recipe',name=boxed and 'nullius-boxed-grounding-coil' or name,
    enabled=false,categories={boxed and 'huge-assembly' or 'small-crafting'},
    energy_required=boxed and 25 or 5,allow_productivity=false,no_productivity=true,
    ingredients={{type='item',name=boxed and 'nullius-box-stone-brick' or 'stone-brick',amount=boxed and 10 or 20},
      {type='item',name=boxed and 'nullius-box-aluminum-wire' or 'nullius-aluminum-wire',amount=20},
      {type='item',name=boxed and 'nullius-box-aluminum-plate' or 'nullius-aluminum-plate',amount=10}},
    results={{type='item',name=boxed and 'nullius-box-grounding-coil' or name,amount=1}}}
  data:extend({recipe})
end

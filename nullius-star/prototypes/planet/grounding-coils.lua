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
    energy_source={type='electric',buffer_capacity='20MJ',usage_priority='tertiary',
      input_flow_limit='400MW',output_flow_limit='0W',drain='0W',render_no_power_icon=false},
    energy_usage='400MW',energy_production='0W',gui_mode='none',allow_copy_paste=false,
    animations=graphics.picture},
})
data:extend({{
  type='recipe',name=name,enabled=false,categories={'small-crafting'},
  energy_required=5,allow_productivity=false,no_productivity=true,
  ingredients={{type='item',name='stone-brick',amount=20},
    {type='item',name='nullius-aluminum-wire',amount=20},
    {type='item',name='nullius-aluminum-plate',amount=10}},
  results={{type='item',name=name,amount=1}},
}})

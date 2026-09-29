local names=require('shared.grounding-coils')
local name=names[1]
local icon='__space-age__/graphics/icons/lightning-collector.png'
local graphics=require('__space-age__.prototypes.entity.lightning-collector-graphics')
data:extend({
  {type='item',name=name,icon=icon,icon_size=64,subgroup='energy',order='nullius-dg',
    place_result=name,stack_size=50},
  {type='electric-energy-interface',name=name,icon=icon,icon_size=64,
    flags={'placeable-neutral','player-creation'},minable={mining_time=0.5,result=name},
    fast_replaceable_group='nullius-grounding-coil',next_upgrade=names[2],
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

local tints={{r=0.5,g=0.75,b=1},{r=0.85,g=0.5,b=1}}
for tier=2,3 do
  local variant=table.deepcopy(data.raw['electric-energy-interface'][name])
  local item=table.deepcopy(data.raw.item[name])
  variant.name=names[tier];item.name=names[tier]
  variant.minable.result=variant.name;item.place_result=variant.name
  variant.next_upgrade=names[tier+1]
  variant.max_health=300*tier
  local mw=400*4^(tier-1)
  variant.energy_source.buffer_capacity=(mw/20)..'MJ'
  variant.energy_source.input_flow_limit=mw..'MW'
  variant.energy_usage=mw..'MW'
  variant.localised_description={'entity-description.'..name}
  variant.animations.layers[1].tint=tints[tier-1]
  local icons={{icon=icon,icon_size=64,tint=tints[tier-1]}}
  variant.icon=nil;variant.icons=icons;item.icon=nil;item.icons=table.deepcopy(icons)
  item.order='nullius-dg-'..tier
  data:extend({variant,item,{
    type='recipe',name=variant.name,enabled=false,
    categories={tier==2 and 'medium-crafting' or 'large-assembly'},
    energy_required=tier==2 and 10 or 20,allow_productivity=false,no_productivity=true,
    ingredients={{type='item',name=names[tier-1],amount=1},
      {type='item',name='nullius-aluminum-wire',amount=tier==2 and 80 or 160},
      {type='item',name='nullius-steel-plate',amount=tier==2 and 40 or 80},
      {type='item',name=tier==2 and 'nullius-glass' or 'nullius-insulation',amount=tier==2 and 20 or 40}},
    results={{type='item',name=variant.name,amount=1}},
  }})
end

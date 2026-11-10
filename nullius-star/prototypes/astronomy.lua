local spec = require("shared.astronomy")
local graphics = require("prototypes.entity.astronomy-graphics")
local launch_research = require("prototypes.planet.launch-research")
local unlocks = {
  {type="unlock-recipe",recipe="nullius-satellite"},
  {type="unlock-recipe",recipe="nullius-box-astronomy-pack"},
  {type="unlock-recipe",recipe="nullius-unbox-astronomy-pack"},
}
local function unlock(name) unlocks[#unlocks + 1] = {type="unlock-recipe",recipe=name} end
local function item(name, icon, place, icon_size)
  data:extend({{type="item",name=name,icon=icon,icon_size=icon_size or 64,subgroup="space",
    order="nullius-radio-"..name,stack_size=50,place_result=place}})
end
local function recipe(name, category, seconds, inputs, outputs)
  data:extend({{type="recipe",name=name,enabled=false,categories={category},
    energy_required=seconds,ingredients=inputs,results=outputs,
    allow_productivity=false,maximum_productivity=0,allow_quality=false}})
end
local function ingredient(name, count) return {type="item",name=name,amount=count} end
local blank = "nullius-blank-recording-module"
item(blank,"__base__/graphics/icons/advanced-circuit.png")
recipe(blank,"medium-crafting",10,{
  ingredient("nullius-processor-1",2),ingredient("nullius-glass",2),ingredient("nullius-ceramic-powder",2),
},{ingredient(blank,1)})
unlock(blank)
require("prototypes.item.boxing")("blank-recording-module","misc","radio")
recipe("nullius-boxed-blank-recording-module","huge-crafting",50,{
  ingredient("nullius-box-processor-1",2),ingredient("nullius-box-glass",2),ingredient("nullius-box-ceramic-powder",2),
},{ingredient("nullius-box-blank-recording-module",1)})
for _, name in ipairs({"nullius-boxed-blank-recording-module","nullius-box-blank-recording-module","nullius-unbox-blank-recording-module"}) do unlock(name) end

data:extend({{type="recipe-category",name="nullius-radio-recording"},
  {type="recipe-category",name="nullius-radio-correlation"},
  {type="collision-layer",name="nullius_dish"},
  {type="surface-property",name="nullius-storm-intensity",default_value=100}})

for i, name in ipairs({spec.dishes[1],spec.dishes[2],"nullius-correlator"}) do
  local dish = i < 3
  local art = graphics[name]
  local icon = art.icon
  item(name,icon,name,128)
  local entity = table.deepcopy(data.raw["assembling-machine"]["assembling-machine-2"])
  entity.name=name;entity.icon=icon;entity.icon_size=128;entity.icons=nil
  entity.graphics_set={animation=art.animation,working_visualisations=art.working_visualisations}
  entity.collision_box={{-2.2,-2.2},{2.2,2.2}}
  entity.selection_box={{-2.5,-2.5},{2.5,2.5}}
  entity.tile_width=5;entity.tile_height=5
  entity.drawing_box_vertical_extension=1.5
  entity.minable={mining_time=0.5,result=name};entity.next_upgrade=nil
  entity.fast_replaceable_group=nil;entity.placeable_by={item=name,count=1}
  entity.crafting_categories={dish and "nullius-radio-recording" or "nullius-radio-correlation"}
  entity.crafting_speed=1;entity.module_slots=0
  entity.allowed_effects=dish and {"speed","consumption"} or {}
  entity.effect_receiver={uses_module_effects=false,uses_beacon_effects=false,
    uses_surface_effects=false,uses_local_effects=dish,
    speed_limits={low=-0.9999,high=1000},consumption_limits={low=-0.9999,high=1000}}
  entity.energy_usage=dish and "500kW" or "1MW"
  entity.energy_source={type="electric",usage_priority="secondary-input",drain="5kW"}
  entity.allow_copy_paste=false
  entity.fluid_boxes=dish and {{production_type="input",filter="nullius-hydrogen",volume=100,
    pipe_picture=require("prototypes.entity.assembler-pipe-pictures")(),pipe_covers=pipecoverspictures(),
    pipe_connections={{flow_direction="input",direction=defines.direction.north,position={-1,-2}}},
    secondary_draw_orders={north=-1,east=1,south=1,west=1}}} or nil
  entity.fluid_boxes_off_when_no_fluid_recipe=false
  if dish then
    entity.collision_mask={layers={item=true,object=true,player=true,water_tile=true,nullius_dish=true}}
  end
  if i==2 then
    entity.energy_source={type="fluid",effectivity=1,burns_fluid=true,scale_fluid_usage=true,
      light_flicker={minimum_intensity=0,maximum_intensity=0},
      fluid_box={volume=1000,filter="nullius-compressed-volcanic-gas",
        pipe_picture=require("prototypes.entity.assembler-pipe-pictures")(),pipe_covers=pipecoverspictures(),
        secondary_draw_orders={north=-1,east=1,south=1,west=1},
        pipe_connections={
          {flow_direction="input-output",direction=defines.direction.west,position={-2,0}},
          {flow_direction="input-output",direction=defines.direction.east,position={2,0}}}}}
  end
  data:extend({entity})
  recipe(name,"large-crafting",30,{
    ingredient("nullius-steel-plate",40),ingredient("nullius-aluminum-plate",40),
    ingredient("nullius-motor-2",10),ingredient("nullius-processor-1",20),
  },{ingredient(name,1)})
  if i~=2 then unlock(name) end
end
for _, direction in ipairs({"horizontal","vertical"}) do
  local field=table.deepcopy(data.raw["simple-entity-with-force"]["nullius-wind-collision-"..direction])
  field.name=spec.field_prefix..direction
  field.localised_name={"entity-name.nullius-radio-dish"}
  field.collision_mask={layers={nullius_dish=true}}
  data:extend({field})
end
for _, planet in ipairs(spec.planets) do
  local name=spec.recording(planet)
  local surface=data.raw.planet[planet=="nauvis" and planet or "nullius-"..planet]
  local magnetic=surface.surface_properties["magnetic-field"] or data.raw["surface-property"]["magnetic-field"].default_value
  local icons={{icon="__base__/graphics/icons/advanced-circuit.png",icon_size=64},
    {icon=surface.icon,icon_size=surface.icon_size,scale=0.25,shift={10,-10}}}
  local recording={type="item",name=name,icons=icons,subgroup="space",order="nullius-radio-"..planet,
    stack_size=50,spoil_ticks=require("shared.reference-transit").spoil_ticks,spoil_result=blank}
  data:extend({recording})
  recipe(name,"nullius-radio-recording",1,{ingredient(blank,1),{type="fluid",name="nullius-hydrogen",amount=1}},
    {ingredient(name,1)})
  data.raw.recipe[name].surface_conditions={{property="magnetic-field",min=magnetic,max=magnetic},{property="pressure",min=1}}
  if planet=="nauvis" then unlock(name) else
    data:extend({{type="technology",name="nullius-"..planet.."-radio-astronomy",
      icons={{icon="__base__/graphics/technology/space-science-pack.png",icon_size=256},
        {icon=surface.icon,icon_size=surface.icon_size,scale=0.5,shift={64,-64}}},
      prerequisites={"nullius-astronomy",planet=="fulgora" and "nullius-primitive-filtration" or "nullius-pneumatic-technology"},
      unit=launch_research(planet=="fulgora" and "nullius-electromagnetic-pack" or "nullius-metallurgic-pack"),
      effects={{type="unlock-recipe",recipe=name}},order="nullius-radio-"..planet}})
    if planet=="vulcanus" then table.insert(data.raw.technology["nullius-vulcanus-radio-astronomy"].effects,
      {type="unlock-recipe",recipe=spec.dishes[2]}) end
  end
end
for k=1,#spec.planets do
  data:extend({{type="item-subgroup",name="nullius-correlation-"..k,group="intermediate-products",order="zz-radio-"..k}})
end
for _, set in ipairs(spec.sets()) do
  local k=#set;local inputs={};local count=k==1 and 20 or 10
  local icons=table.deepcopy(data.raw.tool["nullius-astronomy-pack"].icons)
  for i,planet in ipairs(set) do
    inputs[#inputs+1]=ingredient(spec.recording(planet),count)
    local p=data.raw.planet[planet=="nauvis" and planet or "nullius-"..planet]
    icons[#icons+1]={icon=p.icon,icon_size=p.icon_size,scale=0.2,shift={-12+(i-1)*12,-12}}
  end
  local name="nullius-correlate-"..table.concat(set,"-")
  recipe(name,"nullius-radio-correlation",10,inputs,{
    ingredient("nullius-astronomy-pack",k==1 and 1 or 10*k*(k-1)/2),ingredient(blank,count*k)})
  local r=data.raw.recipe[name];r.icons=icons;r.main_product="nullius-astronomy-pack"
  r.subgroup="nullius-correlation-"..k;r.order=name
  local label={""}
  for i,planet in ipairs(set) do
    if i>1 then label[#label+1]=" + " end
    label[#label+1]={"space-location-name."..(planet=="nauvis" and planet or "nullius-"..planet)}
  end
  r.localised_name={"recipe-name.nullius-correlation",label}
  unlock(name)
end
return unlocks

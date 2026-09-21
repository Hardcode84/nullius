-- External prototypes are explicit native clones. Load the complete production file.
local modern=require("factorio-version").is_2_1
local cases=require("scenarios/optional-override-recipes/fixture")
local dependencies=require("dependencies")
local function clone(kind,name,base)
  local prototype=table.deepcopy(assert(data.raw[kind][base],kind..":"..base))
  prototype.name=name
  prototype.next_upgrade=nil
  data:extend({prototype})
  return prototype
end
for _,group in ipairs({"drones"}) do
  data:extend({{type="item-group",name=group,icon="__base__/graphics/icons/iron-plate.png",icon_size=64}})
end
for _,name in ipairs({"transport-drones","water_transport","concrete","water-intake"}) do
  data:extend({{type="item-subgroup",name=name,group="other"}})
end
data:extend({{type="fuel-category",name="vehicle"},{type="collision-layer",name="layer_43"}})
for _,kind in ipairs({"item","item-with-entity-data"}) do
  for _,name in ipairs(dependencies[kind]) do
    data:extend({{type=kind,name=name,icons={{icon="__base__/graphics/icons/iron-plate.png",icon_size=64}},stack_size=100}})
  end
end
local function item(name)
  for _,kind in ipairs({"item","item-with-entity-data","rail-planner"}) do
    if data.raw[kind][name] then return end
  end
  data:extend({{type="item",name=name,icon="__base__/graphics/icons/iron-plate.png",stack_size=100}})
end
for _,case in ipairs(cases) do
  if not data.raw["recipe-category"][case.category] then data:extend({{type="recipe-category",name=case.category}}) end
  item(case.name)
  for _,part in ipairs(case.ingredients) do
    if part.type=="fluid" then
      if not data.raw.fluid[part.name] then
        local fluid=clone("fluid",part.name,"water")
        fluid.auto_barrel=false
      end
    else item(part.name) end
  end
  local recipe=clone("recipe",case.name,"iron-gear-wheel")
  recipe.enabled=true
  recipe.energy_required=7
  recipe.results={{type="item",name=case.name,amount=1}}
  if modern then recipe.categories={"crafting","advanced-crafting"} else recipe.category="crafting" end
end
for _,kind in ipairs({"assembling-machine","furnace"}) do
  for _,name in ipairs(dependencies[kind]) do
    local base=kind=="furnace" and "electric-furnace" or "assembling-machine-2"
    local entity=clone(kind,name,base)
    entity.fluid_boxes_off_when_no_fluid_recipe=false
    entity.fluid_boxes={
      {volume=100,production_type="input",pipe_connections={{position={0,-1},direction=defines.direction.north,flow_direction="input"}}},
      {volume=500,production_type="output",pipe_connections={{position={0,1},direction=defines.direction.south,flow_direction="output"}}},
    }
  end
end
for kind,base in pairs({car="car",["electric-energy-interface"]="electric-energy-interface",["electric-pole"]="big-electric-pole",generator="steam-engine",locomotive="locomotive",["mining-drill"]="electric-mining-drill",radar="radar",["rail-planner"]="rail",tile="refined-concrete"}) do
  for _,name in ipairs(dependencies[kind]) do clone(kind,name,base) end
end
for _,name in ipairs({"cargo-drone-mooring-constant-combinator-refueler","cargo-drone-mooring-constant-combinator-provider","cargo-drone-mooring-constant-combinator-requester","cargo-drone-depot-constant-combinator"}) do
  clone("constant-combinator",name,"constant-combinator")
end
local shortcut=clone("shortcut","give-waterway","give-blueprint")
shortcut.item_to_spawn="waterway"
for _,name in ipairs({"geology","climatology","mechanical","electrical","chemical","physics","astronomy"}) do
  local pack=clone(modern and "item" or "tool","nullius-"..name.."-pack","automation-science-pack")
  table.insert(data.raw.lab.lab.inputs,pack.name)
end
for _,name in ipairs(dependencies.technology) do
  local tech=clone("technology",name,"automation")
  tech.prerequisites={"automation","electronics"}
  tech.effects={{type="character-inventory-slots-bonus",modifier=0}}
end
require("void-products")
require("executor")

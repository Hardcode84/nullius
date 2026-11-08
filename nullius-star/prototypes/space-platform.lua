-- Cold data-stage path: planetary industry supplies orbital construction.
local components = {
  {name="space-platform-foundation", category="medium-crafting", time=5,
    inputs={{"nullius-aluminum-sheet",4},{"nullius-aluminum-rod",2},{"nullius-insulation",1}}},
  {name="space-platform-starter-pack", category="huge-crafting", time=60,
    inputs={{"space-platform-foundation",20},{"nullius-steel-beam",20},{"radar",1},
      {"nullius-grid-battery-1",4},{"nullius-processor-1",10}}},
  {name="cargo-bay", category="large-crafting", time=10,
    inputs={{"nullius-aluminum-sheet",10},{"nullius-carbon-composite",10},{"nullius-steel-beam",10},{"nullius-insulation",2}}},
  {name="thruster", category="large-crafting", time=10,
    inputs={{"nullius-steel-plate",20},{"nullius-ceramic-powder",20},{"nullius-heat-pipe-2",10},{"nullius-motor-2",5}}},
}
local unlocks = {
  {type="unlock-space-platforms",modifier=true},
  {type="unlock-space-location",space_location="nauvis"},
}
local replaced = {}
for _,spec in ipairs(components) do
  local ingredients={}
  for _,input in ipairs(spec.inputs) do ingredients[#ingredients+1]={type="item",name=input[1],amount=input[2]} end
  data:extend({{type="recipe",name=spec.name,enabled=false,order="nullius-orbital-"..spec.name,
    categories={spec.category},energy_required=spec.time,ingredients=ingredients,
    results={{type="item",name=spec.name,amount=1}},allow_productivity=true,auto_recycle=false}})
  local kind=spec.name=="space-platform-starter-pack" and "space-platform-starter-pack" or "item"
  local item=data.raw[kind][spec.name]
  item.order="nullius-orbital-"..spec.name
  item.subgroup="space"
  item.hidden=false
  item.auto_recycle=false
  unlocks[#unlocks+1]={type="unlock-recipe",recipe=spec.name}
  replaced[spec.name]=true
end
require("prototypes.item.boxing")("space-platform-foundation","misc","orbital-foundation","space-platform-foundation")
for _,name in ipairs{"nullius-box-space-platform-foundation","nullius-unbox-space-platform-foundation"} do
  unlocks[#unlocks+1]={type="unlock-recipe",recipe=name}
end
for _,name in ipairs{"thruster-fuel","thruster-oxidizer"} do
  local fluid=data.raw.fluid[name]
  fluid.order="nullius-orbital-"..name
  fluid.subgroup="canisters"
  fluid.hidden=false
  fluid.auto_barrel=false
end
local recipes={
  {name="nullius-canister-propellant",time=1,
    inputs={{type="item",name="nullius-hydrogen-canister",amount=1}},
    outputs={{type="fluid",name="thruster-fuel",amount=150},{type="fluid",name="thruster-oxidizer",amount=150},
      {type="item",name="nullius-canister",amount=1}}},
  {name="nullius-boxed-canister-propellant",time=5,
    inputs={{type="item",name="nullius-box-hydrogen-canister",amount=1}},
    outputs={{type="fluid",name="thruster-fuel",amount=750},{type="fluid",name="thruster-oxidizer",amount=750},
      {type="item",name="nullius-box-canister",amount=1}}},
  {name="nullius-hydrogen-propellant",time=1,
    inputs={{type="fluid",name="nullius-hydrogen",amount=20}},
    outputs={{type="fluid",name="thruster-fuel",amount=10}}},
  {name="nullius-oxygen-propellant",time=1,
    inputs={{type="fluid",name="nullius-oxygen",amount=10}},
    outputs={{type="fluid",name="thruster-oxidizer",amount=10}}},
}
for _,spec in ipairs(recipes) do
  data:extend({{type="recipe",name=spec.name,localised_name={"recipe-name."..spec.name},
    icon=data.raw.fluid[spec.outputs[1].name].icon,icon_size=64,
    enabled=false,categories={"basic-chemistry"},subgroup="canisters",order="nullius-orbital-"..spec.name,
    energy_required=spec.time,ingredients=spec.inputs,results=spec.outputs,
    allow_productivity=false,maximum_productivity=0,auto_recycle=false}})
  unlocks[#unlocks+1]={type="unlock-recipe",recipe=spec.name}
end
-- Reused recipes belong only to the Nullius research tree.
for name,technology in pairs(data.raw.technology) do
  if name:sub(1,8)~="nullius-" then
    for i=#(technology.effects or {}),1,-1 do
      local effect=technology.effects[i]
      if effect.type=="unlock-space-platforms" or (effect.type=="unlock-recipe" and replaced[effect.recipe]) then table.remove(technology.effects,i) end
    end
  end
end
data:extend({{type="technology",name="nullius-orbital-construction",
  icon="__space-age__/graphics/technology/space-platform.png",icon_size=256,
  prerequisites={"nullius-rocket-science-2"},effects=unlocks,
  unit=table.deepcopy(data.raw.technology["nullius-composites-2"].unit),order="nullius-orbital"}})

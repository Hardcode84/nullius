-- given: production prototypes and Cargo Ships' finite-resource overwrite
-- act: execute the complete optional final pass with each dependency switch
-- expect: enabled hydrothermal vents remain infinite; other modes stay unchanged
local apply = require("optional-final")
for _,mode in ipairs({"enabled", "no-oil", "no-mod"}) do
  local vent=table.deepcopy(data.raw.resource["nullius-fumarole"])
  vent.name="optional-test-vent-"..mode
  vent.infinite=false;vent.infinite_depletion_amount=nil
  local fixture={data={raw={resource={["offshore-oil"]=vent},
    technology={deep_sea_oil_extraction={}}}},
    mods=mode=="no-mod" and {} or {["cargo-ships"]="fixture"},
    settings={startup={offshore_oil_enabled={value=mode~="no-oil"}}}}
  apply(fixture)
  assert(vent.infinite==(mode=="enabled"),mode)
  assert(vent.infinite_depletion_amount==(mode=="enabled" and 10 or nil),mode)
  if mode=="enabled" then
    assert(vent.map_color.r==0.7 and vent.map_color.g==0.5 and vent.map_color.b==0.3)
    assert(fixture.data.raw.technology.deep_sea_oil_extraction.unit.count==200)
  else
    assert(not fixture.data.raw.technology.deep_sea_oil_extraction.unit)
  end
  data:extend({vent})
end

-- given: one result from every native item subtype, and 2.1 testing categories
-- act: run the production recipe visibility passes
-- expect: subtype products stay visible; unrelated recipes stay hidden
local visibility=require("prototypes.recipe-visibility")
for kind in pairs(defines.prototypes.item) do
  local item={name="fixture-product",flags={"temphidden"}}
  local raw={[kind]={[item.name]=item}}
  for _,product in ipairs({{name=item.name,amount=1},{type="item",name=item.name,amount=1}}) do
    item.flags={"temphidden"}
    local recipe={name="fixture-recipe",categories={"crafting","ee-testing-tool"},results={product}}
    visibility.hide(recipe,raw);visibility.restrict(recipe)
    assert(not recipe.hidden and not visibility.unmark(item),kind)
  end
end
local ordinary={name="fixture-unapproved",categories={"crafting"}}
visibility.hide(ordinary,{});visibility.restrict(ordinary)
assert(ordinary.hidden and ordinary.enabled==false and ordinary.allow_as_intermediate==false)

-- given: vanilla and checkpoint labs in normal and YAFC data crawls
-- expect: only YAFC loses milestone inputs; the landing lab is accessible
local yafc=require("optional-yafc")
for _,crawler in ipairs({"normal", "yafc-test"}) do
  local labs={lab={inputs={"automation-science-pack"}},["nullius-hidden-lab"]={inputs={"checkpoint"}}}
  local context={raw={lab=labs,technology=data.raw.technology},data_crawler=crawler}
  yafc{data=context}
  local found=false
  for _,entry in ipairs(context.script_enabled) do
    if entry.type=="entity" and entry.name=="nullius-landing-lab" then found=true end
  end
  assert(found)
  assert(#labs.lab.inputs==(crawler=="normal" and 1 or 0))
  assert(#labs["nullius-hidden-lab"].inputs==(crawler=="normal" and 1 or 0))
end

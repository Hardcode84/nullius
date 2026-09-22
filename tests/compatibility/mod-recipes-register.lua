local fixture=require("fixture-data")
local function icon(p)
  p.icons=nil;p.icon="__base__/graphics/icons/iron-plate.png";p.icon_size=64
end
local function item(name)
  for kind in pairs(defines.prototypes.item) do
    if data.raw[kind] and data.raw[kind][name] then return end
  end
  data:extend({{type="item",name=name,stack_size=100,icon="__base__/graphics/icons/iron-plate.png",icon_size=64}})
end
local function subgroup(name)
  if name and not data.raw["item-subgroup"][name] then
    data:extend({{type="item-subgroup",name=name,group="logistics"}})
  end
end
for _,kind in ipairs({"locomotive","cargo-wagon","fluid-wagon"}) do
  local p=table.deepcopy(data.raw[kind][kind]);p.name="mini-"..kind;p.minable=nil;data:extend({p})
end
local recipes,technologies={},{}
for _,p in pairs(fixture.registered) do
  icon(p)
  if p.type=="item-subgroup" and not data.raw["item-group"][p.group] then
    data:extend({{type="item-group",name=p.group,icon="__base__/graphics/icons/iron-plate.png",icon_size=64}})
  end
  if p.type=="recipe" then
    recipes[p.name]=table.deepcopy(p)
    for _,name in ipairs(p.categories or {p.category or "crafting"}) do
      if not data.raw["recipe-category"][name] then data:extend({{type="recipe-category",name=name}}) end
    end
    subgroup(p.subgroup)
    for _,parts in ipairs({p.ingredients,p.results}) do
      for _,part in ipairs(parts) do
        if part.type=="fluid" then
          assert(part.name=="nullius-lubricant","Undeclared external fluid")
          if not data.raw.fluid[part.name] then
            local fluid=table.deepcopy(data.raw.fluid.lubricant);fluid.name=part.name;fluid.auto_barrel=false;data:extend({fluid})
          end
        else item(part.name) end
      end
    end
  elseif p.type=="technology" then technologies[p.name]=table.deepcopy(p) end
end
-- Native technology validation includes the complete production unlock graph.
-- Text Plates supplies these recipes; this file only registers their unlocks.
for _,material in ipairs({"stone","iron","steel","gold","plastic","glass","concrete","copper","uranium"}) do
  for _,size in ipairs({"small","large"}) do
    local p=table.deepcopy(data.raw.recipe["iron-gear-wheel"])
    p.name="textplate-"..size.."-"..material
    data:extend({p})
  end
end
for _,name in ipairs({"nullius-box-heliostat-mirror","nullius-unbox-heliostat-mirror"}) do
  local p=table.deepcopy(data.raw.recipe["iron-gear-wheel"]);p.name=name;data:extend({p})
end
local required={}
for _,tech in pairs(technologies) do
  for _,name in ipairs(tech.prerequisites or {}) do required[name]=true end
  for _,pack in ipairs(tech.unit.ingredients) do
    local name=pack[1]
    if not data.raw.item[name] and not (data.raw.tool and data.raw.tool[name]) then
      local kind=require("factorio-version").is_2_1 and "item" or "tool"
      local p=table.deepcopy(data.raw[kind]["automation-science-pack"]);p.name=name;data:extend({p})
      table.insert(data.raw.lab.lab.inputs,name)
    end
  end
end
for name in pairs(required) do
  local prefix,level=name:match("^(.*%-)(%d+)$")
  if prefix then for n=1,tonumber(level) do required[prefix..n]=true end end
end
for name in pairs(required) do
  if not technologies[name] and not data.raw.technology[name] then
    local p=table.deepcopy(data.raw.technology.automation);p.name=name;data:extend({p})
  end
end
for _,p in pairs(fixture.registered) do data:extend({p}) end
data:extend({{type="mod-data",name="mod-recipe-contracts",data={recipes=recipes,technologies=technologies,
  traffic_effects=fixture.raw.technology["nullius-traffic-control"].effects}}})

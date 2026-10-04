-- Cold data-stage path: slurry separation and selective mineral recovery.
local modern = require("factorio-version").is_2_1
local probability = modern and "independent_probability" or "probability"
local unlocks = {}
data:extend({{
  type="technology",name="nullius-primitive-filtration",
  icon="__base__/graphics/technology/fluid-handling.png",icon_size=256,
  order="nullius-df-fulgora",prerequisites={"nullius-probe-fulgora","nullius-geology-2"},effects=unlocks,
  unit={count=5,time=15,ingredients={
    {"nullius-geology-pack",1},{"nullius-climatology-pack",1},
    {"nullius-mechanical-pack",1},{"nullius-electrical-pack",1},
  }},
}})
local function add(name, category, seconds, ingredients, results, icon, boxed)
  local title = {"recipe-name.nullius-"..name}
  if boxed then title = {"recipe-name.nullius-boxed",title} end
  local recipe = {
    type="recipe", name="nullius-"..(boxed and "boxed-" or "")..name,
    localised_name=title, icons={{icon=icon,icon_size=64}},
    subgroup="waste-management", order="nullius-fulgora-"..name..(boxed and "-boxed" or ""),
    enabled=false, energy_required=seconds, ingredients=ingredients, results=results,
    allow_productivity=false, no_productivity=true,
  }
  if modern then recipe.categories={category} else recipe.category=category end
  data:extend({recipe})
  unlocks[#unlocks+1]={type="unlock-recipe",recipe=recipe.name}
end
for _,boxed in ipairs({false,true}) do
  local scale = boxed and 5 or 1
  local function item(name, amount)
    return {type="item",name=boxed and "nullius-box-"..name or
      (name=="stone" and "stone" or "nullius-"..name),amount=amount}
  end
  local function fluid(name, amount)
    return {type="fluid",name="nullius-"..name,amount=amount*scale}
  end
  add("hydrocarbon-slurry-filtration","nullius-water-treatment",4*scale,
    {fluid("hydrocarbon-slurry",100)},
    {fluid("filtered-hydrocarbons",50),fluid("sludge",40),
      item("ice",2),item("salt",1)},
    "__nullius-star__/graphics/icons/fluid/sludge.png",boxed)
  local minerals={}
  for _,name in ipairs({"crushed-iron-ore","crushed-bauxite","sand","crushed-limestone","stone","gypsum"}) do
    local result=item(name,3)
    result[probability]=0.25
    minerals[#minerals+1]=result
  end
  add("crude-sludge-filtration","nullius-water-treatment",2*scale,
    {fluid("sludge",50)},minerals,"__nullius-star__/graphics/icons/fluid/sludge.png",boxed)
  data:extend({{
    type="recipe", name="nullius-"..(boxed and "boxed-" or "").."gypsum-recovery",
    localised_name=boxed and {"recipe-name.nullius-boxed",{"recipe-name.nullius-gypsum-recovery"}}
      or {"recipe-name.nullius-gypsum-recovery"},
    icons=table.deepcopy(data.raw.item["nullius-gypsum"].icons),
    subgroup="waste-management", order="nullius-fulgora-gypsum-recovery"..(boxed and "-boxed" or ""),
    enabled=false, categories={"ore-flotation"}, energy_required=20*scale,
    ingredients={fluid("sludge",200),fluid("oxygen",180)},
    results={item("gypsum",8),item("sand",4),fluid("wastewater",150)},
    main_product=boxed and "nullius-box-gypsum" or "nullius-gypsum",
    allow_productivity=false, no_productivity=true,
  }})
  local leaching = {
    type="recipe", name="nullius-"..(boxed and "boxed-" or "").."borate-leaching",
    localised_name=boxed and {"recipe-name.nullius-boxed",{"recipe-name.nullius-borate-leaching"}}
      or {"recipe-name.nullius-borate-leaching"},
    icons=table.deepcopy(data.raw.item["nullius-acid-boric"].icons),
    subgroup="waste-management", order="nullius-fulgora-borate-leaching"..(boxed and "-boxed" or ""),
    enabled=false, categories={"basic-chemistry"}, energy_required=10*scale,
    ingredients={fluid("sludge",100),fluid("acid-sulfuric",20),fluid("water",20)},
    results={item("acid-boric",1),item("gypsum",1),fluid("wastewater",80)},
    main_product=boxed and "nullius-box-acid-boric" or "nullius-acid-boric",
    allow_productivity=false, no_productivity=true,
  }
  data:extend({leaching})
  add("salt-disposal","ore-crushing",scale,
    {item("salt",1)},{item("mineral-dust",1)},
    "__angelssmeltinggraphics__/graphics/icons/powder-tungsten.png",boxed)
  add("ice-melting","distillation",2*scale,
    {item("ice",1)},{fluid("water",20)},
    "__space-age__/graphics/icons/ice.png",boxed)
  -- Reverse the salt/water balance of brine boiling and steam condensation.
  add("salt-dissolution","nullius-water-treatment",scale,
    {item("salt",6),fluid("water",45)},{fluid("brine",65)},
    "__nullius-star__/graphics/icons/salt.png",boxed)
  add("hydrocarbon-cracking","distillation",4*scale,
    {fluid("filtered-hydrocarbons",50)},
    {fluid("methane",60),fluid("benzene",12),item("graphite",2)},
    "__base__/graphics/icons/fluid/heavy-oil.png",boxed)
  add("climatology-pack-fulgora","nullius-water-treatment",60*scale,
    {fluid("air",5000),fluid("hydrocarbon-slurry",100)},
    {item("climatology-pack",1)},
    "__nullius-star__/graphics/icons/fluid/sludge.png",boxed)
  local science = data.raw.recipe["nullius-"..(boxed and "boxed-" or "").."climatology-pack-fulgora"]
  local product = boxed and data.raw.item["nullius-box-climatology-pack"] or data.raw.tool["nullius-climatology-pack"]
  science.subgroup = product.subgroup
  science.icons = table.deepcopy(product.icons)
end

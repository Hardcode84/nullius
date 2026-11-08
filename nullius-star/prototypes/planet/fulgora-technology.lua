for _,process in ipairs({
    {name="slurry-filtration", recipe="hydrocarbon-slurry-filtration", icon="fluid-handling"},
    {name="hydrocarbon-cracking", recipe="hydrocarbon-cracking", icon="oil-processing"},
}) do
  data:extend({{
    type="technology", name="nullius-bulk-"..process.name,
    icon="__base__/graphics/technology/"..process.icon..".png", icon_size=256,
    order="nullius-dg-bulk-"..process.name,
    prerequisites={"nullius-overcharged-assembly-2", "nullius-packaging-3"},
    effects={{type="unlock-recipe", recipe="nullius-boxed-"..process.recipe}},
    unit={count=10, time=45, ingredients={
      {"nullius-electromagnetic-pack",20}, {"nullius-climatology-pack",4},
      {"nullius-electrical-pack",4}, {"nullius-chemical-pack",4},
    }},
  }})
end

for _,bulk in ipairs({false,true}) do
  data:extend({{
    type="technology",name="nullius-"..(bulk and "bulk-" or "").."hydrocarbon-degassing",
    icons=table.deepcopy(data.raw.fluid[bulk and "nullius-compressed-helium" or "nullius-helium"].icons),
    order="nullius-dg-"..(bulk and "bulk-" or "").."hydrocarbon-degassing",
    prerequisites=bulk and {"nullius-hydrocarbon-degassing","nullius-bulk-hydrocarbon-cracking"}
      or {"nullius-air-separation-3","nullius-overcharged-assembly-2"},
    effects={{type="unlock-recipe",recipe="nullius-"..(bulk and "boxed-" or "").."degassing-hydrocarbon-cracking"}},
    unit={count=10,time=45,ingredients={
      {"nullius-electromagnetic-pack",20},{"nullius-climatology-pack",4},
      {"nullius-electrical-pack",4},{"nullius-chemical-pack",4},
    }},
  }})
end

data:extend({{
  type="technology",name="nullius-bulk-ice-and-salt-processing",
  icon="__base__/graphics/technology/fluid-handling.png",icon_size=256,
  order="nullius-dg-bulk-ice-and-salt-processing",
  prerequisites={"nullius-overcharged-assembly-2","nullius-packaging-3","nullius-mass-production-4"},
  effects={
    {type="unlock-recipe",recipe="nullius-boxed-ice-melting"},
    {type="unlock-recipe",recipe="nullius-boxed-salt-dissolution"},
  },
  unit={count=10,time=45,ingredients={
    {"nullius-electromagnetic-pack",20},{"nullius-climatology-pack",4},
    {"nullius-electrical-pack",4},{"nullius-chemical-pack",4},
  }},
}})

local bulk_recovery={}
for _,name in ipairs({"limestone-recovery","stone-recovery","iron-recovery",
    "bauxite-recovery","sand-recovery","gypsum-recovery","borate-leaching","barrel-recycling"}) do
  bulk_recovery[#bulk_recovery+1]={type="unlock-recipe",recipe="nullius-boxed-"..name}
end
data:extend({{
  type="technology",name="nullius-bulk-waste-reclamation",
  icon="__nullius-star__/graphics/icons/fluid/sludge.png",icon_size=64,
  order="nullius-dg-bulk-waste-reclamation",
  prerequisites={"nullius-waste-reclamation","nullius-overcharged-assembly-2","nullius-packaging-4"},
  effects=bulk_recovery,
  unit={count=10,time=45,ingredients={
    {"nullius-electromagnetic-pack",20},{"nullius-climatology-pack",4},
    {"nullius-electrical-pack",4},{"nullius-chemical-pack",4},
  }},
}})

local function overcharged(tier, count, seconds, ingredients, prerequisites)
  local description = {"technology-description.nullius-overcharged-assembly-" .. tier}
  local effects = {{type="nothing",effect_description=description},
    {type="unlock-recipe",recipe=tier==2 and "nullius-electromagnetic-pack-improved" or "nullius-boxed-electromagnetic-pack"}}
  if tier==3 then
    effects[#effects+1]={type="unlock-recipe",recipe="nullius-box-electromagnetic-pack"}
    effects[#effects+1]={type="unlock-recipe",recipe="nullius-unbox-electromagnetic-pack"}
  end
  return {
    type="technology",name="nullius-overcharged-assembly-" .. tier,
    localised_description=description,
    icon="__base__/graphics/technology/automation-" .. tier .. ".png",icon_size=256,
    order="nullius-dg-overcharged-" .. tier,
    effects=effects,
    prerequisites=prerequisites,
    unit={count=count,time=seconds,ingredients=ingredients},
  }
end

data:extend({
  overcharged(2,10,45,{
    {"nullius-electromagnetic-pack",20},
    {"nullius-mechanical-pack",4},{"nullius-electrical-pack",4},
  },{"nullius-primitive-filtration","nullius-automation-2"}),
  overcharged(3,20,60,{
    {"nullius-electromagnetic-pack",40},
    {"nullius-mechanical-pack",8},{"nullius-electrical-pack",8},
    {"nullius-chemical-pack",16},{"nullius-physics-pack",8},
  },{"nullius-overcharged-assembly-2","nullius-automation-3"}),
})

local capacitor_description = {"technology-description.nullius-supercapacitors"}
data:extend({{
  type="technology",name="nullius-supercapacitors",
  icon="__base__/graphics/technology/electric-energy-acumulators.png",icon_size=256,
  localised_description=capacitor_description,
  order="nullius-dg-supercapacitors",
  prerequisites={"nullius-primitive-filtration","nullius-battery-storage-2"},
  effects={{type="nothing",effect_description=capacitor_description}},
  unit={count=10,time=30,ingredients={
    {"nullius-electromagnetic-pack",10},{"nullius-electrical-pack",4},
  }},
}})

for tier=2,3 do
  data:extend({{
    type='technology',name='nullius-grounding-coils-'..tier,
    localised_name={'technology-name.nullius-grounding-coils-'..tier},
    localised_description={'technology-description.nullius-grounding-coils-'..tier},
    icon='__space-age__/graphics/technology/lightning-collector.png',icon_size=256,
    order='nullius-dg-grounding-'..tier,
    prerequisites=tier==2 and {'nullius-overcharged-assembly-2','nullius-steelmaking-1'} or
      {'nullius-grounding-coils-2','nullius-overcharged-assembly-3','nullius-insulation-2'},
    effects={{type='unlock-recipe',recipe='nullius-grounding-coil-'..tier}},
    unit={count=tier==2 and 10 or 20,time=tier==2 and 45 or 60,
      ingredients=tier==2 and {{'nullius-electromagnetic-pack',20},{'nullius-electrical-pack',4}} or
        {{'nullius-electromagnetic-pack',40},{'nullius-electrical-pack',8},
         {'nullius-chemical-pack',16},{'nullius-physics-pack',8}}},
  }})
end

data:extend({
  {
    type="technology", name="nullius-storm-climatology",
    icon="__base__/graphics/technology/chemical-science-pack.png", icon_size=256,
    order="nullius-dg-storm-climatology",
    prerequisites={"nullius-primitive-filtration", "nullius-climatology-2"},
    effects={{type="unlock-recipe", recipe="nullius-climatology-pack-fulgora-2"}},
    unit={count=10, time=30, ingredients={
      {"nullius-electromagnetic-pack",10}, {"nullius-climatology-pack",4},
      {"nullius-electrical-pack",4},
    }},
  },
  {
    type="technology", name="nullius-bulk-storm-climatology",
    icon="__base__/graphics/technology/chemical-science-pack.png", icon_size=256,
    order="nullius-dg-bulk-storm-climatology",
    prerequisites={"nullius-storm-climatology", "nullius-overcharged-assembly-2", "nullius-mass-production-7"},
    effects={{type="unlock-recipe", recipe="nullius-boxed-climatology-pack-fulgora-2"}},
    unit={count=10, time=45, ingredients={
      {"nullius-electromagnetic-pack",20}, {"nullius-climatology-pack",4},
      {"nullius-electrical-pack",4}, {"nullius-chemical-pack",4},
    }},
  },
})

data:extend({{
  type="technology",name="nullius-rp1-fuel",
  icon="__base__/graphics/technology/rocket-fuel.png",icon_size=256,
  order="nullius-dg-rp1",
  prerequisites={"nullius-rocket-science-1","nullius-bulk-polymer-processing"},
  effects={
    {type="unlock-recipe",recipe="nullius-olefin-oligomerization"},
    {type="unlock-recipe",recipe="nullius-rp1-rocket-fuel"},
    {type="unlock-recipe",recipe="nullius-boxed-rp1-rocket-fuel"},
  },
  unit={count=10,time=45,ingredients={
    {"nullius-electromagnetic-pack",20},{"nullius-electrical-pack",4},
    {"nullius-chemical-pack",4},{"nullius-physics-pack",2},
  }},
}})

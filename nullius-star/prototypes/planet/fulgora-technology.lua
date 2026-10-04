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

for _,name in ipairs({"ice-melting", "salt-disposal", "salt-dissolution"}) do
  table.insert(data.raw.technology["nullius-mass-production-4"].effects,
    {type="unlock-recipe",recipe="nullius-boxed-"..name})
end

for _,name in ipairs({"nullius-box-ice", "nullius-unbox-ice"}) do
  table.insert(data.raw.technology["nullius-packaging-3"].effects,
    {type="unlock-recipe",recipe=name})
end

for _,name in ipairs({"nullius-borate-leaching","nullius-boxed-borate-leaching",
    "nullius-gypsum-recovery","nullius-boxed-gypsum-recovery",
    "nullius-boxed-limestone-recovery","nullius-boxed-stone-recovery"}) do
  table.insert(data.raw.technology["nullius-waste-reclamation"].effects,
    {type="unlock-recipe",recipe=name})
end

local function overcharged(tier, count, seconds, ingredients, prerequisites)
  local description = {"technology-description.nullius-overcharged-assembly-" .. tier}
  return {
    type="technology",name="nullius-overcharged-assembly-" .. tier,
    localised_description=description,
    icon="__base__/graphics/technology/automation-" .. tier .. ".png",icon_size=256,
    order="nullius-dg-overcharged-" .. tier,
    effects={{type="nothing",effect_description=description},
      {type="unlock-recipe",recipe=tier==2 and "nullius-electromagnetic-pack-improved" or "nullius-boxed-electromagnetic-pack"}},
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

for _,name in ipairs({"nullius-box-electromagnetic-pack","nullius-unbox-electromagnetic-pack"}) do
  table.insert(data.raw.technology["nullius-overcharged-assembly-3"].effects,
    {type="unlock-recipe",recipe=name})
end

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

table.insert(data.raw.technology['nullius-primitive-filtration'].effects,
  {type='unlock-recipe',recipe='nullius-grounding-coil'})

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

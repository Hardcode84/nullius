local function overcharged(tier, count, seconds, ingredients, prerequisites)
  local description = {"technology-description.nullius-overcharged-assembly-" .. tier}
  return {
    type="technology",name="nullius-overcharged-assembly-" .. tier,
    localised_description=description,
    icon="__base__/graphics/technology/automation-" .. tier .. ".png",icon_size=256,
    order="nullius-dg-overcharged-" .. tier,
    effects={{type="nothing",effect_description=description}},
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

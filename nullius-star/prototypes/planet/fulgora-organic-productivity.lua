local productivity = require("prototypes.recipe-productivity")
for _, spec in ipairs({
  {name="hydrocarbon", prerequisite="nullius-primitive-filtration",
    products={"filtered-hydrocarbons","methane","ethylene","propene","benzene","butadiene","styrene"}},
  {name="polymerization", prerequisite="nullius-organic-chemistry-1",
    products={"plastic","rubber","epoxy","bpa","ech","acrylonitrile"}},
  {name="fiber", prerequisite="nullius-weaving-2",
    products={"acrylic-fiber","carbon-fiber","textile"}},
}) do
  local products={}
  for _, name in ipairs(spec.products) do products[#products+1]="nullius-"..name end
  data:extend({{
    type="technology",name="nullius-"..spec.name.."-productivity-1",
    icon="__base__/graphics/technology/plastics.png",icon_size=256,
    prerequisites={"nullius-overcharged-assembly-2",spec.prerequisite},
    effects=productivity.product_effects(products,0.01),
    unit={count_formula="100*L^2",ingredients={{"nullius-electromagnetic-pack",1}},time=30},
    max_level="infinite",upgrade=true,order="nullius-dg-productivity-"..spec.name,
  }})
end

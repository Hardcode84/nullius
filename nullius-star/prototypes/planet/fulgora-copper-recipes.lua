-- Fulgora deep-drilling copper: deep slurry, its filtration, roasting, and
-- leaching into the existing copper solution. Deep drilling yields a fraction
-- of an ordinary extractor's slurry.
data:extend({{type='recipe-category',name='nullius-deep-drilling'}, {
  type='recipe',name='nullius-deep-drilling',categories={'nullius-deep-drilling'},
  enabled=false,energy_required=5,ingredients={},
  results={{type='fluid',name='nullius-deep-slurry',amount=10}},
  allow_productivity=false,no_productivity=true,
  surface_conditions={{property='magnetic-field',min=99}},
}})
for _,boxed in ipairs({false,true}) do
  local scale=boxed and 5 or 1
  local function item(name,amount)
    return {type='item',name='nullius-'..(boxed and 'box-' or '')..name,amount=amount}
  end
  local function fluid(name,amount)
    return {type='fluid',name='nullius-'..name,amount=amount*scale}
  end
  local function recipe(name,category,ingredients,results,main,productivity)
    data:extend({{type='recipe',name='nullius-'..(boxed and 'boxed-' or '')..name,
      localised_name=boxed and {'recipe-name.nullius-boxed',{'recipe-name.nullius-'..name}}
        or {'recipe-name.nullius-'..name},
      categories={category},enabled=false,energy_required=4*scale,
      ingredients=ingredients,results=results,main_product=main,
      subgroup='copper',order='nullius-deep-'..name,
      allow_productivity=productivity,no_productivity=not productivity,
    }})
  end
  -- As slurry filtration, no productivity: it would multiply a vent's fixed
  -- supply, and infinite hydrocarbon productivity selects every permitted
  -- recipe that outputs filtered hydrocarbons.
  recipe('deep-slurry-filtration','nullius-water-treatment',{fluid('deep-slurry',100)},
    {fluid('filtered-hydrocarbons',50),fluid('sludge',40),item('copper-concentrate',2),item('salt',1)},
    item('copper-concentrate',1).name,false)
  recipe('copper-roasting','basic-chemistry',
    {item('copper-concentrate',2),fluid(boxed and 'compressed-oxygen' or 'oxygen',boxed and 7.5 or 30)},
    {item('copper-calcine',2),fluid('sulfur-dioxide',20)},item('copper-calcine',1).name,true)
  recipe('copper-leaching','ore-flotation',{item('copper-calcine',2),fluid('acid-sulfuric',20)},
    {fluid('copper-solution',40),item('iron-oxide',1),fluid('sludge',10)},'nullius-copper-solution',true)
end

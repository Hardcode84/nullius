local specs = require("shared.fulgora-organics")
local boxed_references = {
  ["nullius-iron-gear"]="nullius-boxed-iron-gear",
  ["nullius-steel-gear"]="nullius-boxed-steel-gear",
  ["nullius-steel-beam"]="nullius-boxed-steel-beam",
  ["nullius-steel-cable"]="nullius-boxed-steel-cable",
  ["copper-cable"]="nullius-boxed-insulated-wire-1",
}
local function gcd(a, b)
  while b ~= 0 do a, b = b, a % b end
  return a
end

data:extend({{
  type="technology", name="nullius-improved-polymer-doping",
  icon="__base__/graphics/technology/plastics.png", icon_size=256,
  prerequisites={"nullius-primitive-filtration","nullius-explosives-1"},
  effects={}, unit={count=10,time=30,ingredients={
    {"nullius-electromagnetic-pack",10},{"nullius-electrical-pack",4},{"nullius-mechanical-pack",4},
  }}, order="nullius-dg-polymer-doping",
}, {
  type="technology", name="nullius-fiber-reinforced-polymers",
  icon="__base__/graphics/technology/plastics.png", icon_size=256,
  prerequisites={"nullius-primitive-filtration","nullius-weaving-2"},
  effects={}, unit={count=10,time=30,ingredients={
    {"nullius-electromagnetic-pack",10},{"nullius-electrical-pack",4},{"nullius-mechanical-pack",4},
  }}, order="nullius-dg-fiber-reinforced-polymers",
}, {
  type="technology", name="nullius-bulk-polymer-processing",
  icon="__base__/graphics/technology/plastics.png", icon_size=256,
  prerequisites={"nullius-mass-production-4","nullius-improved-polymer-doping","nullius-fiber-reinforced-polymers"},
  effects={}, unit={count=10,time=45,ingredients={
    {"nullius-electromagnetic-pack",20},{"nullius-electrical-pack",4},{"nullius-chemical-pack",4},
  }}, order="nullius-dg-bulk-polymer-processing",
}, {
  type="technology", name="nullius-composite-construction",
  icon="__base__/graphics/technology/plastics.png", icon_size=256,
  prerequisites={"nullius-composites-2","nullius-bulk-polymer-processing"},
  effects={}, unit={count=10,time=45,ingredients={
    {"nullius-electromagnetic-pack",20},{"nullius-electrical-pack",4},
    {"nullius-chemical-pack",4},{"nullius-physics-pack",2},
  }}, order="nullius-dg-composite-construction",
}})

for _, spec in ipairs(specs) do
  for _, boxed in ipairs({false,true}) do
    local name = boxed and spec.name:gsub("^nullius%-", "nullius-boxed-") or spec.name
    local ingredients, results = table.deepcopy(spec.ingredients), table.deepcopy(spec.results)
    local divisor = 1
    if boxed then
      for _, entries in ipairs({ingredients,results}) do
        for _, entry in ipairs(entries) do
          entry.amount=entry.amount*5
          if entry.type=="item" and BOXED_ITEM_MAPPING[entry.name] then
            local original=entry.name
            entry.name=assert(BOXED_ITEM_MAPPING[original], "Missing box for "..original)
            entry.amount=entry.amount/(DOUBLE_RATIO_BOX[original] and 10 or 5)
          end
        end
      end
    end
    if boxed then
      divisor = 0
      for _, entries in ipairs({ingredients,results}) do
        for _, entry in ipairs(entries) do divisor = gcd(divisor,entry.amount) end
      end
      for _, entries in ipairs({ingredients,results}) do
        for _, entry in ipairs(entries) do entry.amount=entry.amount/divisor end
      end
    end
    local product=results[1].name
    local category, subgroup = spec.category, nil
    if boxed then
      if spec.results[1].name == "nullius-iron-chloride" then
        category, subgroup = "basic-chemistry", "boxed-iron"
      else
        local reference=assert(data.raw.recipe[assert(boxed_references[spec.results[1].name])])
        category, subgroup = reference.categories[1], reference.subgroup
      end
    end
    data:extend({{
      type="recipe",name=name, enabled=false, categories={category},
      localised_name=boxed and {"recipe-name.nullius-boxed",{"recipe-name."..spec.name}} or {"recipe-name."..spec.name},
      main_product=product,
      subgroup=subgroup, order="nullius-fulgora-"..name,
      energy_required=spec.seconds*(boxed and 5 or 1)/divisor,ingredients=ingredients,results=results,
      allow_productivity=true, auto_recycle=false,
    }})
    table.insert(data.raw.technology[boxed and (spec.boxed_technology or "nullius-bulk-polymer-processing") or spec.technology].effects,
      {type="unlock-recipe",recipe=name})
  end
end

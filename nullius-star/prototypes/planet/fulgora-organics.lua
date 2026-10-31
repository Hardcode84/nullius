local specs = require("shared.fulgora-organics")
local boxed_categories = {
  ["small-crafting"]="medium-assembly", ["large-fluid-assembly"]="huge-fluid-assembly",
  ["machine-casting"]="machine-casting", ["basic-chemistry"]="basic-chemistry",
}

data:extend({{
  type="technology", name="nullius-improved-polymer-doping",
  icon="__base__/graphics/technology/plastics.png", icon_size=256,
  prerequisites={"nullius-primitive-filtration","nullius-explosives-1"},
  effects={}, unit={count=10,time=30,ingredients={
    {"nullius-electromagnetic-pack",10},{"nullius-electrical-pack",4},{"nullius-mechanical-pack",4},
  }}, order="nullius-dg-polymer-doping",
}})

for _, spec in ipairs(specs) do
  for _, boxed in ipairs({false,true}) do
    local name = boxed and spec.name:gsub("^nullius%-", "nullius-boxed-") or spec.name
    local ingredients, results = table.deepcopy(spec.ingredients), table.deepcopy(spec.results)
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
    local product=results[1].name
    local item=data.raw.item[product]
    data:extend({{
      type="recipe",name=name, enabled=false, categories={boxed and assert(boxed_categories[spec.category]) or spec.category},
      localised_name=boxed and {"recipe-name.nullius-boxed",{"recipe-name."..spec.name}} or {"recipe-name."..spec.name},
      icons=table.deepcopy(item.icons), icon=item.icon, icon_size=item.icon_size,
      subgroup=item.subgroup, order="nullius-fulgora-"..name,
      energy_required=spec.seconds*(boxed and 5 or 1),ingredients=ingredients,results=results,
      allow_productivity=true, auto_recycle=false,
      surface_conditions={{property="magnetic-field",min=99,max=99}},
    }})
    table.insert(data.raw.technology[boxed and "nullius-mass-production-4" or spec.technology].effects,
      {type="unlock-recipe",recipe=name})
  end
end

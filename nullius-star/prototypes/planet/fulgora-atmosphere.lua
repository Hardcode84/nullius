-- Cold data-stage path: shared gases, with separation set by the surface.
local fulgora = {{property="magnetic-field", min=99, max=99}}
local function separate(source, name, technology, outputs)
  local recipe = table.deepcopy(assert(data.raw.recipe[source]))
  recipe.name = name
  recipe.localised_name = {"recipe-name."..name}
  recipe.surface_conditions = table.deepcopy(fulgora)
  recipe.results = outputs
  if #outputs == 1 then
    recipe.icons = table.deepcopy(data.raw.fluid[outputs[1].name].icons)
  end
  recipe.main_product = nil
  recipe.allow_productivity = false
  recipe.no_productivity = true
  data:extend({recipe})
  local effects = assert(data.raw.technology[technology]).effects
  effects[#effects+1] = {type="unlock-recipe", recipe=name}
end
local function gas(name, amount)
  return {type="fluid", name="nullius-"..name, amount=amount}
end
for _,compressed in ipairs({false,true}) do
  local prefix = compressed and "pressure-" or ""
  local fluid = compressed and "compressed-" or ""
  local technology = compressed and "nullius-high-pressure-chemistry" or "nullius-primitive-filtration"
  local air = "nullius-"..prefix.."air-separation-fulgora"
  separate(compressed and "nullius-pressure-air-separation" or "nullius-air-separation-2",
    air, technology, {gas(fluid.."nitrogen",80),gas(fluid.."carbon-dioxide",19),gas(fluid.."residual-gas",1)})
  separate("nullius-"..prefix.."residual-separation",
    "nullius-"..prefix.."residual-separation-fulgora", technology, {gas(fluid.."argon",50)})
end

-- Keep enrichment and oxygen/water recovery from bypassing Fulgora's composition.
for _,name in ipairs({
  "nullius-air-separation-1", "nullius-air-separation-2",
  "nullius-pressure-air-separation", "nullius-oxygen-separation",
  "nullius-pressure-oxygen-separation", "nullius-residual-gas",
  "nullius-residual-separation", "nullius-pressure-residual-separation",
}) do
  local recipe = assert(data.raw.recipe[name])
  recipe.surface_conditions = recipe.surface_conditions or {}
  recipe.surface_conditions[#recipe.surface_conditions+1] = {property="magnetic-field", max=98}
end

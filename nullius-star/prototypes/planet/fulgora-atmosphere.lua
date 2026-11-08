-- Cold data-stage path: shared gases, with separation set by the surface.
local fulgora = {{property="magnetic-field", min=99, max=99}}
local function separate(source, name, outputs)
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
end
local function gas(name, amount)
  return {type="fluid", name="nullius-"..name, amount=amount}
end
separate("nullius-air-separation-2", "nullius-air-separation-fulgora",
  {gas("nitrogen",80),gas("carbon-dioxide",19)})

for _,compressed in ipairs({false,true}) do
  local prefix = compressed and "pressure-" or ""
  local fluid = compressed and "compressed-" or ""
  local air = "nullius-"..prefix.."air-separation-fulgora"..(compressed and "" or "-2")
  separate(compressed and "nullius-pressure-air-separation" or "nullius-air-separation-2",
    air, {gas(fluid.."nitrogen",80),gas(fluid.."carbon-dioxide",19),gas(fluid.."residual-gas",1)})
  separate("nullius-"..prefix.."residual-separation",
    "nullius-"..prefix.."residual-separation-fulgora", {gas(fluid.."argon",50)})
end

-- Barrel recipes for Nullius fluids. The base game generates a fill and an empty
-- recipe for each fluid that allows barrels; this pass gives both Nullius
-- categories and ordering. It takes a list of {technology, fluids} pairs, fluids
-- without the "nullius-" prefix: each technology unlocks the barrels of its
-- fluids, and every other Nullius barrel is available from the start.
local modern = require("factorio-version").is_2_1

-- Fuels other than steam fill half a barrel and take twice as long.
local function half_barrel(fluid)
  return fluid.fuel_value ~= nil and fluid.name ~= "nullius-steam"
end

local KINDS = {
  {prefix = "", group = "fill", category = "nullius-barrel"},
  {prefix = "empty-", group = "empty", category = "nullius-unbarrel"},
}

local function configure(recipe, kind, fluid, locked)
  recipe.subgroup = kind.group .. "-" .. fluid.subgroup
  recipe.order = fluid.order
  recipe.hide_from_player_crafting = true
  recipe.hide_from_stats = true
  recipe.enabled = not locked
  if modern then
    recipe.categories = {kind.category}
  else
    recipe.category = kind.category
  end
  recipe.energy_required = half_barrel(fluid) and 0.5 or 0.25
  recipe.requester_paste_multiplier = 5
  if half_barrel(fluid) then
    for _, entry in ipairs(kind.prefix == "" and recipe.ingredients or recipe.results) do
      if entry.type == "fluid" then entry.amount = 25 end
    end
  end
end

return function(unlocks)
  local locked = {}
  for _, unlock in ipairs(unlocks) do
    for _, short in ipairs(unlock[2]) do locked["nullius-" .. short] = true end
  end

  for name, fluid in pairs(data.raw.fluid) do
    local barrel = name .. "-barrel"
    if string.sub(name, 1, 8) == "nullius-" and data.raw.recipe[barrel] then
      local item = data.raw.item[barrel]
      item.subgroup = "fill-" .. fluid.subgroup
      item.order = fluid.order
      item.stack_size = 20
      for _, kind in ipairs(KINDS) do
        configure(assert(data.raw.recipe[kind.prefix .. barrel], "Missing " .. kind.prefix .. barrel),
          kind, fluid, locked[name])
      end
    elseif data.raw.item[barrel] then
      data.raw.item[barrel].subgroup = "hidden"
    end
  end

  for _, unlock in ipairs(unlocks) do
    local technology = assert(data.raw.technology[unlock[1]], "Missing barrel technology " .. unlock[1])
    for _, short in ipairs(unlock[2]) do
      local barrel = "nullius-" .. short .. "-barrel"
      for _, kind in ipairs(KINDS) do
        local recipe = kind.prefix .. barrel
        assert(data.raw.recipe[recipe], unlock[1] .. " unlocks missing barrel recipe " .. recipe)
        table.insert(technology.effects, {type = "unlock-recipe", recipe = recipe})
      end
    end
  end
end

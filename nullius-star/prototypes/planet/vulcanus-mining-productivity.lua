local extraction_recipes = {
  "nullius-lava-iron-separation",
  "nullius-lava-aluminum-separation",
  "nullius-lava-calcite-separation",
  "nullius-lava-silica-extraction",
}

local technology_count = 0
for name, technology in pairs(data.raw.technology) do
  if string.match(name, "^nullius%-mining%-productivity%-%d+$") then
    technology_count = technology_count + 1
    local mining_modifier = nil
    for _, effect in ipairs(technology.effects or {}) do
      if effect.type == "mining-drill-productivity-bonus" then
        assert(mining_modifier == nil,
          name .. " has multiple mining productivity modifiers")
        mining_modifier = effect.modifier
      end
    end
    assert(type(mining_modifier) == "number" and mining_modifier > 0,
      name .. " has no positive mining productivity modifier")

    for _, recipe_name in ipairs(extraction_recipes) do
      local recipe = data.raw.recipe[recipe_name]
      assert(recipe ~= nil, "Missing lava extraction recipe " .. recipe_name)
      assert(recipe.maximum_productivity ~= 0,
        recipe_name .. " disables recipe productivity")
      technology.effects[#technology.effects + 1] = {
        type = "change-recipe-productivity",
        recipe = recipe_name,
        change = mining_modifier,
      }
    end
  end
end

assert(technology_count > 0, "No Nullius mining productivity technologies found")

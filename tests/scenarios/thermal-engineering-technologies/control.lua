local CASE = "thermal-engineering-technologies"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local TECHNOLOGIES = {
  {
    name = "nullius-efficient-metallurgic-science",
    count = 5,
    seconds = 30,
    ingredients = {
      ["nullius-metallurgic-pack"] = 2,
      ["nullius-geology-pack"] = 2,
      ["nullius-mechanical-pack"] = 1,
      ["nullius-electrical-pack"] = 1,
    },
    prerequisites = {
      ["nullius-pneumatic-technology"] = true,
    },
  },
  {
    name = "nullius-hot-metalworking",
    count = 10,
    seconds = 30,
    ingredients = {
      ["nullius-metallurgic-pack"] = 10,
      ["nullius-mechanical-pack"] = 1,
    },
    prerequisites = {
      ["nullius-efficient-metallurgic-science"] = true,
      ["nullius-aluminum-working-1"] = true,
    },
  },
  {
    name = "nullius-vulcanus-refractory-engineering",
    count = 10,
    seconds = 45,
    ingredients = {
      ["nullius-metallurgic-pack"] = 40,
      ["nullius-geology-pack"] = 4,
      ["nullius-chemical-pack"] = 4,
    },
    prerequisites = {
      ["nullius-hot-metalworking"] = true,
      ["nullius-ceramics"] = true,
      ["nullius-thermal-storage-2"] = true,
    },
  },
  {
    name = "nullius-volcanic-titanium-metallurgy",
    count = 10,
    seconds = 60,
    ingredients = {
      ["nullius-metallurgic-pack"] = 80,
      ["nullius-geology-pack"] = 8,
      ["nullius-chemical-pack"] = 8,
    },
    prerequisites = {
      ["nullius-vulcanus-refractory-engineering"] = true,
      ["nullius-titanium-production-2"] = true,
      ["nullius-water-filtration-3"] = true,
      ["nullius-metalworking-2"] = true,
    },
  },
  {
    name = "nullius-thermal-engineering-1",
    count = 5,
    seconds = 30,
    ingredients = {
      ["nullius-metallurgic-pack"] = 40,
      ["nullius-geology-pack"] = 2,
      ["nullius-mechanical-pack"] = 1,
    },
    prerequisites = {
      ["nullius-efficient-metallurgic-science"] = true,
      ["nullius-mineral-processing-1"] = true,
      ["nullius-metallurgy-1"] = true,
      ["nullius-metalworking-1"] = true,
      ["nullius-boiling-1"] = true,
      ["nullius-solar-thermal-power-1"] = true,
    },
  },
  {
    name = "nullius-thermal-engineering-2",
    count = 10,
    seconds = 45,
    ingredients = {
      ["nullius-metallurgic-pack"] = 80,
      ["nullius-geology-pack"] = 8,
      ["nullius-mechanical-pack"] = 4,
      ["nullius-electrical-pack"] = 4,
      ["nullius-chemical-pack"] = 4,
    },
    prerequisites = {
      ["nullius-thermal-engineering-1"] = true,
      ["nullius-mineral-processing-2"] = true,
      ["nullius-metallurgy-2"] = true,
      ["nullius-metalworking-2"] = true,
      ["nullius-thermal-storage-2"] = true,
      ["nullius-solar-thermal-power-2"] = true,
    },
  },
  {
    name = "nullius-thermal-engineering-3",
    count = 20,
    seconds = 60,
    ingredients = {
      ["nullius-metallurgic-pack"] = 160,
      ["nullius-geology-pack"] = 16,
      ["nullius-climatology-pack"] = 8,
      ["nullius-mechanical-pack"] = 8,
      ["nullius-electrical-pack"] = 8,
      ["nullius-chemical-pack"] = 16,
    },
    prerequisites = {
      ["nullius-thermal-engineering-2"] = true,
      ["nullius-mineral-processing-3"] = true,
      ["nullius-metallurgy-3"] = true,
      ["nullius-metalworking-4"] = true,
      ["nullius-thermal-storage-3"] = true,
      ["nullius-nuclear-power-1"] = true,
    },
  },
}

local assertions = 0
local failures = {}
local observations = {}

local function check(condition, message)
  assertions = assertions + 1
  if not condition then failures[#failures + 1] = message end
end

local function finish()
  local result = {
    schema = 1,
    case = CASE,
    status = (#failures == 0) and "pass" or "fail",
    factorio_version = script.active_mods.base,
    tick = game.tick,
    assertions = assertions,
    failure_count = #failures,
    failures = failures,
    observations = observations,
  }
  helpers.write_file(RESULT, helpers.table_to_json(result), false)
  if #failures > 0 then error(helpers.table_to_json(result)) end
end

local function names_to_set(entries)
  local result = {}
  for name in pairs(entries) do result[name] = true end
  return result
end

local function ingredients_to_map(entries)
  local result = {}
  for _, ingredient in pairs(entries) do
    result[ingredient.name] = ingredient.amount
  end
  return result
end

local function product_amount(entries, name)
  for _, product in pairs(entries) do
    if product.name == name then return product.amount end
  end
  return nil
end

local function ignored_productivity(entries, name)
  for _, product in pairs(entries) do
    if product.name == name then
      return product.ignored_by_productivity or 0
    end
  end
  return nil
end

local function unlocked_recipes(technology)
  local result = {}
  for _, effect in pairs(technology.prototype.effects) do
    if effect.type == "unlock-recipe" then result[effect.recipe] = true end
  end
  return result
end

local function check_exact(actual, expected, label)
  for name, value in pairs(expected) do
    check(actual[name] == value,
      label .. " expected " .. tostring(value) .. " for " .. name ..
      ", found " .. tostring(actual[name]))
  end
  for name, value in pairs(actual) do
    check(expected[name] == value,
      label .. " contained unexpected " .. name .. "=" .. tostring(value))
  end
end

script.on_nth_tick(1, function()
  script.on_nth_tick(1, nil)
  local force = game.forces.player

  for _, expected in ipairs(TECHNOLOGIES) do
    local technology = force.technologies[expected.name]
    check(technology ~= nil, "missing technology " .. expected.name)
    if technology then
      local ingredients = ingredients_to_map(
        technology.prototype.research_unit_ingredients)
      local prerequisites = names_to_set(technology.prerequisites)
      observations[expected.name] = {
        count = technology.research_unit_count,
        ticks = technology.research_unit_energy,
        ingredients = ingredients,
        prerequisites = prerequisites,
      }
      check(technology.research_unit_count == expected.count,
        expected.name .. " has unexpected research-unit count")
      check(technology.research_unit_energy == expected.seconds * 60,
        expected.name .. " has unexpected research-unit time")
      check_exact(ingredients, expected.ingredients,
        expected.name .. " ingredients")
      check_exact(prerequisites, expected.prerequisites,
        expected.name .. " prerequisites")
    end
  end

  local titanium_technology = force.technologies[
    "nullius-volcanic-titanium-metallurgy"]
  if titanium_technology then
    check_exact(unlocked_recipes(titanium_technology), {
      ["nullius-titanium-ingot-vulcanus"] = true,
      ["nullius-aluminum-chloride-recovery"] = true,
      ["nullius-hydro-plant-2-vulcanus"] = true,
      ["nullius-foundry-2-vulcanus"] = true,
    }, "volcanic titanium recipe unlocks")
  end

  local reduction = force.recipes["nullius-titanium-ingot-vulcanus"]
  check(reduction ~= nil, "missing Vulcanus titanium reduction recipe")
  if reduction then
    check(reduction.prototype.category == "nullius-high-temp-radiator",
      "Vulcanus titanium reduction has wrong category")
    check(reduction.energy == 8,
      "Vulcanus titanium reduction has wrong duration")
    check_exact(ingredients_to_map(reduction.ingredients), {
      ["nullius-titanium-tetrachloride"] = 15,
      ["nullius-aluminum-ingot"] = 4,
    }, "Vulcanus titanium reduction ingredients")
    check(product_amount(reduction.products, "nullius-titanium-ingot") == 2,
      "Vulcanus titanium reduction has wrong titanium yield")
    check(product_amount(reduction.products, "nullius-aluminum-chloride") == 4,
      "Vulcanus titanium reduction has wrong aluminum chloride yield")
    check(ignored_productivity(
        reduction.products, "nullius-aluminum-chloride") == 4,
      "productivity can duplicate aluminum chloride")
  end

  local recovery = force.recipes["nullius-aluminum-chloride-recovery"]
  check(recovery ~= nil, "missing aluminum chloride recovery recipe")
  if recovery then
    check(recovery.prototype.category == "nullius-high-temp-radiator",
      "aluminum chloride recovery has wrong category")
    check(recovery.energy == 6,
      "aluminum chloride recovery has wrong duration")
    check_exact(ingredients_to_map(recovery.ingredients), {
      ["nullius-aluminum-chloride"] = 4,
      ["nullius-water"] = 30,
    }, "aluminum chloride recovery ingredients")
    check_exact(ingredients_to_map(recovery.products), {
      ["nullius-alumina"] = 1,
      ["nullius-mineral-dust"] = 3,
      ["nullius-hydrogen-chloride"] = 60,
    }, "aluminum chloride recovery products")
  end

  finish()
end)

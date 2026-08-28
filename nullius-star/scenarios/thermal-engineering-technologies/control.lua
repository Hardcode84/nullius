local CASE = "thermal-engineering-technologies"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local TECHNOLOGIES = {
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
      ["nullius-pneumatic-technology"] = true,
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

  finish()
end)

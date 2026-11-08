-- given: resolved prototypes; no entities.
-- place: nothing.
-- connect: nothing.
-- act: read the space-platform surface properties, every planet's gravity and
--   pressure, every placeable Nullius entity's surface conditions, and the
--   thruster fluids.
-- run: one scheduled read.
-- expect: observations list which Nullius buildings a platform accepts, so the
--   vacuum placement rules can be compared with the shipped conditions.
local CASE = "experiment-platform-placement"
local RESULT = "factorio-tests/" .. CASE .. ".json"

local function allowed(conditions, properties)
  for _, condition in pairs(conditions or {}) do
    local value = properties[condition.property]
    if value == nil then value = prototypes.surface_property[condition.property].default_value end
    if value < condition.min or value > condition.max then return false end
  end
  return true
end

script.on_nth_tick(30, function()
  script.on_nth_tick(30, nil)
  local failures = {}
  local assertions=2
  local platform = prototypes.surface["space-platform"].surface_properties
  local observations = {platform = platform, planets = {}, vacuum_allowed = {}, vacuum_blocked = {},
    thruster_fluids = {}}
  observations.defaults = {gravity = prototypes.surface_property.gravity.default_value,
    pressure = prototypes.surface_property.pressure.default_value}
  for name, planet in pairs(prototypes.space_location) do
    local properties = planet.surface_properties or {}
    if planet.type == "planet" then
      observations.planets[name] = {gravity = properties.gravity, pressure = properties.pressure}
    end
  end
  for name, entity in pairs(prototypes.get_entity_filtered{{filter = "buildable"}}) do
    if string.sub(name, 1, 8) == "nullius-" and entity.items_to_place_this then
      local bucket = allowed(entity.surface_conditions, platform)
        and observations.vacuum_allowed or observations.vacuum_blocked
      local list = bucket[entity.type] or {}
      bucket[entity.type] = list
      list[#list + 1] = name
    end
  end
  -- Candidate vacuum rule: environment intakes, fluid-powered machines,
  -- drills and pumps that need ground or water, and named atmosphere users.
  local INTAKE_CATEGORIES = {["air-filtration"] = true, ["water-pumping"] = true, ["seawater-pumping"] = true}
  local GROUND_TYPES = {["mining-drill"] = true, ["offshore-pump"] = true}
  local NAMED = {"nullius-wind-", "nullius-stirling-engine-", "nullius-landing-"}
  observations.vacuum_rule = {}
  for name, entity in pairs(prototypes.get_entity_filtered{{filter = "buildable"}}) do
    if string.sub(name, 1, 8) == "nullius-" and entity.items_to_place_this then
      local reason
      for category in pairs(entity.crafting_categories or {}) do
        if INTAKE_CATEGORIES[category] then reason = "intake " .. category end
      end
      if not reason and entity.fluid_energy_source_prototype then reason = "fluid energy" end
      if not reason and GROUND_TYPES[entity.type] then reason = entity.type end
      if not reason then
        for _, prefix in ipairs(NAMED) do
          if string.sub(name, 1, #prefix) == prefix then reason = prefix end
        end
      end
      if reason then
        assertions=assertions+1
        if allowed(entity.surface_conditions,platform) then failures[#failures+1]="vacuum exclusion missing: "..name end
        local list = observations.vacuum_rule[reason] or {}
        observations.vacuum_rule[reason] = list
        list[#list + 1] = name
      end
    end
  end
  for _, list in pairs(observations.vacuum_rule) do table.sort(list) end
  for _, name in ipairs({"thruster-fuel", "thruster-oxidizer"}) do
    local fluid = prototypes.fluid[name]
    if fluid then
      observations.thruster_fluids[name] = {hidden = fluid.hidden}
      if fluid.hidden then failures[#failures+1]="hidden propellant: "..name end
    else
      failures[#failures + 1] = "missing fluid " .. name
    end
  end
  for _, list in pairs(observations.vacuum_allowed) do table.sort(list) end
  for _, list in pairs(observations.vacuum_blocked) do table.sort(list) end
  helpers.write_file(RESULT, helpers.table_to_json{
    schema = 1, case = CASE, status = (#failures == 0) and "pass" or "fail",
    factorio_version = script.active_mods.base, tick = game.tick,
    assertions = assertions, failure_count = #failures, failures = failures,
    observations = observations}, false)
  if #failures > 0 then error(helpers.table_to_json(failures)) end
end)

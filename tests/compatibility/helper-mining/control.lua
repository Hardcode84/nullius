require("__nullius-star__/scripts/beacon")
require("__nullius-star__/scripts/geothermal")
local heat_api = require("__nullius-star__/scripts/vulcanus_heat")
local vent_api = require("__nullius-star__/scripts/vulcanus_gasvent")
local assertions = 0
local function check(ok, message)
  assertions = assertions + 1
  assert(ok, message)
end
local function protected(entity)
  check(entity and entity.valid, "helper exists")
  check(not entity.minable_flag, "script mining flag is disabled")
  check(not entity.minable, "helper cannot be mined")
  check(not entity.destructible, "helper cannot be damaged")
end
script.on_nth_tick(1, function()
  script.on_nth_tick(1, nil)
  local planet = game.planets["nullius-vulcanus"]
  local surface = planet.surface or planet.create_surface()
  surface.request_to_generate_chunks({0,0}, 2)
  surface.force_generate_chunk_requests()
  for _, entity in pairs(surface.find_entities_filtered{area={{-32,-32},{32,32}}}) do entity.destroy() end
  local function place(name, x)
    local entity = surface.create_entity{name=name, position={x,0}, force="player"}
    check(entity ~= nil, "place " .. name)
    return entity
  end

  local beacon = place("nullius-large-beacon-1", -20)
  build_large_beacon(beacon)
  local fields = storage.nullius_beacons[beacon.unit_number].interference
  check(#fields == 4, "four beacon fields")
  for _, field in ipairs(fields) do protected(field) end
  local unit = beacon.unit_number
  beacon.destroy()
  check(remove_beacon(unit), "beacon cleanup")
  for _, field in ipairs(fields) do check(not field.valid, "beacon field removed") end

  init_geothermal()
  local stirling = place("compat-stirling", -5)
  build_stirling_engine(stirling, 1)
  unit = stirling.unit_number
  local entry = storage.nullius_stirling_buckets[unit % 443][1][unit]
  protected(entry.heat)
  stirling.destroy()
  check(destroyed_stirling_engine(unit), "Stirling cleanup")
  check(not entry.heat.valid and not entry.turbine.valid, "Stirling helpers removed")

  heat_api.init()
  local machine = place("compat-machine-pneumatic", 5)
  heat_api.add_heat_interface(machine)
  unit = machine.unit_number
  local heat = storage.nullius_pneumatic_heat[unit]
  protected(heat)
  machine.destroy()
  check(heat_api.remove_heat_interface(unit), "pneumatic cleanup")
  check(not heat.valid, "pneumatic heat removed")

  vent_api.init()
  local vent = place("compat-vent", 20)
  vent_api.register(vent)
  unit = vent.unit_number
  entry = storage.nullius_gasvents[unit]
  protected(entry.drill)
  check(entry.resource.valid, "vent resource exists")
  vent.destroy()
  check(vent_api.remove(unit), "vent cleanup")
  check(not entry.drill.valid and not entry.resource.valid, "vent helpers removed")

  local result = {schema=1, case="helper-mining", status="pass",
    factorio_version=script.active_mods.base, tick=game.tick, assertions=assertions,
    failure_count=0, failures={}}
  helpers.write_file("factorio-tests/helper-mining.json", helpers.table_to_json(result), false)
end)

-- Antiproton collectors run only while their platform is stopped at Fulgora.
-- Recipes cannot see a platform's orbit, so the state is derived from the
-- platform's location on the cold paths that change it: building a collector,
-- a platform state change, and a configuration change.
local antiproton = {}
local COLLECTOR = "nullius-antiproton-collector"
local FULGORA = "nullius-fulgora"
local STATUS = {diode = defines.entity_status_diode.red, label = {"nullius-antiproton.outside-fulgora"}}

-- A platform in transit has no space location.
local function at_fulgora(surface)
  local platform = surface.platform
  local location = platform and platform.space_location
  return location ~= nil and location.name == FULGORA
end

local function apply(entity, active)
  if entity.disabled_by_script == active then
    entity.disabled_by_script = not active
    entity.custom_status = not active and STATUS or nil
  end
end

local function refresh(surface)
  local active = at_fulgora(surface)
  for _, entity in pairs(surface.find_entities_filtered{name = COLLECTOR}) do apply(entity, active) end
end

function antiproton.built(entity)
  if entity.name == COLLECTOR then apply(entity, at_fulgora(entity.surface)) end
end

function antiproton.platform_changed(event)
  local surface = event.platform.surface
  if surface then refresh(surface) end
end

function antiproton.rebuild()
  for _, surface in pairs(game.surfaces) do refresh(surface) end
end

return antiproton

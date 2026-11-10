-- Antiproton collectors run only while their platform is stopped at Fulgora.
-- Recipes cannot see a platform's orbit, so the state is derived from the
-- platform's location on the cold paths that change it: building a collector,
-- a platform state change, and a configuration change.
local antiproton = {}
local COLLECTOR = "nullius-antiproton-collector"
local FULGORA = "nullius-fulgora"
local STATUS = {diode = defines.entity_status_diode.red, label = {"nullius-antiproton.outside-fulgora"}}
antiproton.ANNIHILATION = "nullius-antimatter-annihilation"
local SITE = "nullius-annihilation-site"
-- An alert lasts while its site exists.
local SITE_TICKS = 5 * 60 * 60
local ALERT_ICON = {type = "item", name = "nullius-antimatter"}
local ALERT = {"nullius-antiproton.containment-failed"}

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
  storage.nullius_annihilation_sites = storage.nullius_annihilation_sites or {}
  for _, surface in pairs(game.surfaces) do refresh(surface) end
end

-- A spoiled filled trap raises one trigger per trap. A spoiling stack fires
-- all of them on one tile in one tick; they become one detonation and alert.
function antiproton.annihilation(event)
  local position = event.source_position or event.target_position
  local key = event.surface_index .. ":" .. math.floor(position.x) .. ":" .. math.floor(position.y)
  local merged = storage.nullius_annihilation
  if not merged or merged.tick ~= event.tick then
    merged = {tick = event.tick, keys = {}}
    storage.nullius_annihilation = merged
  end
  if merged.keys[key] then return end
  merged.keys[key] = true
  local surface = game.surfaces[event.surface_index]
  local holder = event.source_entity
  local force = holder and holder.valid and holder.force or nil
  -- Items on the ground and other unowned holders alert everyone.
  if force and (force.name == "neutral" or force.name == "enemy") then force = nil end
  local site = assert(surface.create_entity{name = SITE, position = position, force = force or "neutral"})
  site.destructible = false
  storage.nullius_annihilation_sites[site.unit_number] = {entity = site, expires = event.tick + SITE_TICKS}
  for _, player in pairs(game.players) do
    if not force or player.force.index == force.index then player.add_custom_alert(site, ALERT_ICON, ALERT, true) end
  end
  surface.create_entity{name = "atomic-rocket", position = position, target = position, speed = 1, force = "neutral"}
end

-- Called every 60 ticks; idle without sites.
function antiproton.expire_sites()
  local sites = storage.nullius_annihilation_sites
  if not next(sites) then return end
  for unit, row in pairs(sites) do
    if game.tick >= row.expires then
      for _, player in pairs(game.players) do player.remove_alert{entity = row.entity, type = defines.alert_type.custom} end
      row.entity.destroy()
      sites[unit] = nil
    end
  end
end

return antiproton

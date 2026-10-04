-- Cold data-stage path. A dedicated tile layer leaves placement on water and
-- other planets unchanged; the engine enforces the sand rules without events.
local masks = require("collision-mask-util")
local buildable = require("prototypes.visible-build-items")()
-- Groundwater extraction is unavailable in Fulgora's electromagnetic environment.
for _,entity in pairs(data.raw["assembling-machine"]) do
  for _,category in pairs(entity.crafting_categories or {}) do
    if category=="water-pumping" then
      entity.surface_conditions=entity.surface_conditions or {}
      table.insert(entity.surface_conditions,{property="magnetic-field",max=98})
      break
    end
  end
end
local coils={}
for _,name in ipairs(require('shared.grounding-coils')) do coils[name]=true end
local allowed = {
  -- Androids have build items, but must not inherit building restrictions.
  character=true,
  -- Rolling stock stays on rails. Ground rails enforce the sand restriction.
  locomotive=true, ["cargo-wagon"]=true, ["fluid-wagon"]=true,
  ["artillery-wagon"]=true, ["infinity-cargo-wagon"]=true,
  ["electric-pole"]=true, pipe=true, ["pipe-to-ground"]=true, pump=true,
  ["rail-support"]=true,
}
for kind in pairs(require("collision-mask-defaults")) do
  for name, entity in pairs(data.raw[kind] or {}) do
    local mask = masks.get_mask(entity)
    local extractor = kind=="mining-drill" and
      (name:find("nullius-extractor-",1,true)==1 or name=="pumpjack")
    local elevated = kind:find("elevated-",1,true)==1
    if kind~="tile" and not allowed[kind] and not extractor and not elevated and
        name~="nullius-hydrocarbon-vent" and not coils[name] and
        (mask.layers.water_tile or mask.layers.ground_tile or buildable[name]~=nil) then
      entity.collision_mask = table.deepcopy(mask)
      entity.collision_mask.layers.nullius_fulgora_sand = true
    end
  end
end
for kind in pairs(defines.prototypes.item) do
  for _,item in pairs(data.raw[kind] or {}) do
    if item.place_as_tile then
      local placement = item.place_as_tile
      placement.condition = table.deepcopy(placement.condition)
      placement.condition.layers.nullius_fulgora_sand = not placement.invert or nil
    end
  end
end

data:extend({{type='collision-layer',name='nullius_grounding_land'}})
for name,tile in pairs(data.raw.tile) do
  if not name:find('nullius-fulgora-sediment',1,true) then
    tile.collision_mask=table.deepcopy(tile.collision_mask)
    tile.collision_mask.layers.nullius_grounding_land=true
  end
end
for _,direction in ipairs({'horizontal','vertical'}) do
  local field=table.deepcopy(data.raw['simple-entity-with-force']['nullius-wind-collision-'..direction])
  field.name='nullius-grounding-collision-'..direction
  field.localised_name={'entity-name.nullius-grounding-coil'}
  data:extend({field})
end

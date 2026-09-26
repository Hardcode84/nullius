-- Cold data-stage path. A dedicated tile layer leaves placement on water and
-- other planets unchanged; the engine enforces the sand rules without events.
local masks = require("collision-mask-util")
local buildable = require("prototypes.visible-build-items")()
local allowed = {
  -- Androids have build items, but must not inherit building restrictions.
  character=true,
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
        name~="nullius-hydrocarbon-vent" and
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

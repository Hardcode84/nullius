local cases = require("__nullius-star__/scenarios/chest-doors/fixture")
for _, case in ipairs(cases) do
  data:extend({{type="item",name=case.name,stack_size=50,place_result=case.name,
    icons={{icon="__base__/graphics/icons/steel-chest.png",icon_size=64}}}})
end
require("__nullius-star__/prototypes/entity/chest")
local modern = string.match(mods.base,"^2%.1%.") ~= nil
local base = data.raw["logistic-container"]["storage-chest"]
local reference = modern and base.robot_door or base
for _, case in ipairs(cases) do
  local chest = data.raw[case.mode and "logistic-container" or "container"][case.name]
  assert(chest.inventory_size == case.size, case.name .. " capacity")
  assert(chest.logistic_mode == case.mode, case.name .. " mode")
  if case.mode then
    local door = modern and chest.robot_door or chest
    assert(door and door.animation and door.animation.layers, case.name .. " animation")
    assert(door.opened_duration == reference.opened_duration, case.name .. " duration")
    assert(door.animation_sound == reference.animation_sound, case.name .. " sound")
    assert(#door.animation.layers == (case.frames==16 and 5 or 2),case.name .. " layers")
    for _, layer in ipairs(door.animation.layers) do
      assert((layer.frame_count or 1)*(layer.repeat_count or 1)==case.frames,case.name .. " frames")
      assert(layer.filename and layer.width > 0 and layer.height > 0,case.name .. " sprite")
    end
    if modern then
      assert(not chest.animation and not chest.animation_sound and not chest.opened_duration,
        case.name .. " removed fields")
    end
  end
end

local surface = game.planets["nullius-gleba"].surface
if not surface then return end

local map = surface.map_gen_settings
local names = {"nullius-gleba-rock", "nullius-microbial-mat"}
map.autoplace_settings.entity = surface.planet.prototype.map_gen_settings.autoplace_settings.entity
surface.map_gen_settings = map
surface.set_property("nullius-hydrogen-sulfide", 1)
surface.regenerate_entity(names)

local starter = require("__nullius-star__/shared/gleba-starter")
for index, landings in pairs(storage.nullius_probe_landings or {}) do
  if landings["nullius-gleba"] then
    local force = game.forces[index]
    local wreck = surface.find_entities_filtered{name = "nullius-landing-main", force = force,
      position = {0, 0}, radius = 64, limit = 1}[1]
    local pos = wreck and wreck.position or force.get_spawn_position(surface)
    for _, stack in ipairs(starter) do
      local count = stack[2] - (wreck and wreck.insert{name = stack[1], count = stack[2]} or 0)
      if count > 0 then
        surface.spill_item_stack{position = pos, stack = {name = stack[1], count = count}, force = force,
          enable_looted = true, use_start_position_on_failure = true}
      end
    end
  end
end

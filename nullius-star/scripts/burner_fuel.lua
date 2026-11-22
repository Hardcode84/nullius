-- Leaving a goop-burning mode spills its remaining fuel and spent fuel.
local burner_fuel = {}

function burner_fuel.release(entity)
  if entity.type == "entity-ghost" then return end
  for _, inventory in ipairs({entity.get_fuel_inventory(), entity.get_burnt_result_inventory()}) do
    for i = 1, #inventory do
      local stack = inventory[i]
      if stack.valid_for_read then
        entity.surface.spill_item_stack{position = entity.position, stack = stack, force = entity.force,
          enable_looted = true, use_start_position_on_failure = true}
        stack.clear()
      end
    end
  end
end

return burner_fuel

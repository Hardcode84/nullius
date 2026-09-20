-- Test executor access to native fluid storage in Factorio 2.0 and 2.1.
local api = {}
if string.match(script.active_mods.base, "^2%.1%.") then
  function api.count(entity) return entity.fluids_count end
  function api.get(entity, index) return entity.get_fluid(index) end
  function api.set(entity, index, fluid)
    if fluid then entity.set_fluid(index, fluid) else entity.clear_fluid(index) end
  end
  function api.capacity(entity, index) return entity.get_fluid_capacity(index) end
  function api.filter(entity, index)
    local filter = entity.get_fluid_filter(index)
    if not filter then return nil end
    local fluid = filter.fluid
    return {name=type(fluid) == "string" and fluid or (fluid and fluid.name),
      minimum_temperature=filter.minimum_temperature,
      maximum_temperature=filter.maximum_temperature}
  end
  function api.prototype(entity, index)
    local prototype = entity.get_fluid_box_prototype(index)
    -- Merged recipe ports have the same direction. Check this invariant.
    if type(prototype) == "table" and not prototype.object_name then
      local first = assert(prototype[1], "empty merged fluid port")
      for _, part in ipairs(prototype) do
        assert(part.production_type == first.production_type, "mixed merged fluid directions")
      end
      return first
    end
    return assert(prototype, "executor fluid storage has no prototype")
  end
else
  assert(string.match(script.active_mods.base, "^2%.0%."), "unsupported Factorio version")
  function api.count(entity) return #entity.fluidbox end
  function api.get(entity, index) return entity.fluidbox[index] end
  function api.set(entity, index, fluid) entity.fluidbox[index] = fluid end
  function api.capacity(entity, index) return entity.fluidbox.get_capacity(index) end
  function api.filter(entity, index) return entity.fluidbox.get_filter(index) end
  function api.prototype(entity, index) return entity.fluidbox.get_prototype(index) end
end
return api

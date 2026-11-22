-- Copies a machine into an operating mode. The base item places the mode, and
-- the shared fast-replace group lets the mode switch replace one with the other.
-- The base prototype declares that group where it is defined.
return function(base, suffix)
  local variant = table.deepcopy(base)
  variant.name = base.name .. suffix
  variant.placeable_by = {item = assert(base.minable, "Mode base is not minable: " .. base.name).result, count = 1}
  variant.fast_replaceable_group = assert(base.fast_replaceable_group,
    "Mode base has no fast-replace group: " .. base.name)
  -- Upgrade targets are linked after every variant exists.
  variant.next_upgrade = nil
  return variant
end

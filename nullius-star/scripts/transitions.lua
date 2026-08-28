local transitions = {}

local transition = {}

function transition.register(from, to, opts)
  if not transitions[from] then transitions[from] = {} end
  table.insert(transitions[from], {
    target = to,
    condition = opts and opts.condition,
    gate = opts and opts.gate,
    on_leave = opts and opts.on_leave,
    on_enter = opts and opts.on_enter,
    replace_fn = opts and opts.replace_fn,
  })
end

function transition.execute(entity, name, force)
  local chain = transitions[name]
  if not chain then return false end

  for _, edge in ipairs(chain) do
    if not edge.condition or edge.condition(entity, force) then
      if edge.gate and not edge.gate(entity) then return true end
      if edge.on_leave then edge.on_leave(entity) end
      local replacement
      if edge.replace_fn then
        replacement = edge.replace_fn(entity, edge.target, force)
      else
        replacement = replace_fluid_entity(entity, edge.target, force, nil)
      end
      if edge.on_enter and replacement and replacement.valid then
        edge.on_enter(replacement)
      end
      return true
    end
  end
  return false
end

if script.active_mods["factorio-test-support"] then
  remote.add_interface("nullius-test-transitions", {
    execute = function(entity)
      if not entity or not entity.valid then return false end
      local name = entity.type == "entity-ghost" and entity.ghost_name or entity.name
      return transition.execute(entity, name, entity.force)
    end,
  })
end

return transition

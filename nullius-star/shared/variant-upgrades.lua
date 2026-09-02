local variant_upgrades = {}

local ENTITY_TYPES = {
  "assembling-machine",
  "furnace",
  "pump",
  "inserter",
  "mining-drill",
  "lab",
}

local function ends_with(value, suffix)
  return string.sub(value, -#suffix) == suffix
end

function variant_upgrades.apply(suffix)
  for _, prototype_type in ipairs(ENTITY_TYPES) do
    local prototypes = data.raw[prototype_type]
    local edges = {}
    for name, variant in pairs(prototypes) do
      if ends_with(name, suffix) then
        local base_name = string.sub(name, 1, #name - #suffix)
        local base = prototypes[base_name]
        if not base then
          error("Missing base entity for upgrade chain: " .. name)
        end

        local target = base.next_upgrade
        local variant_target = target and prototypes[target .. suffix]
        if variant_target then
          edges[name] = variant_target.name
        end
        variant.next_upgrade = nil
      end
    end

    -- Configurable valves rewrite pump replacement groups after the pneumatic
    -- prototypes are copied. Pump transitions use destroy/create, so their
    -- variant-only upgrade components can safely use a dedicated group.
    if prototype_type == "pump" then
      local adjacency = {}
      for source, target in pairs(edges) do
        adjacency[source] = adjacency[source] or {}
        adjacency[target] = adjacency[target] or {}
        adjacency[source][#adjacency[source] + 1] = target
        adjacency[target][#adjacency[target] + 1] = source
      end
      local names = {}
      for name in pairs(adjacency) do names[#names + 1] = name end
      table.sort(names)
      local visited = {}
      for _, start in ipairs(names) do
        if not visited[start] then
          local members = {}
          local stack = {start}
          visited[start] = true
          while #stack > 0 do
            local current = table.remove(stack)
            members[#members + 1] = current
            for _, neighbor in ipairs(adjacency[current]) do
              if not visited[neighbor] then
                visited[neighbor] = true
                stack[#stack + 1] = neighbor
              end
            end
          end
          table.sort(members)
          local group = "nullius-" .. string.sub(suffix, 2) ..
            "-upgrade-" .. members[1]
          for _, name in ipairs(members) do
            prototypes[name].fast_replaceable_group = group
          end
        end
      end
    end

    for source, target in pairs(edges) do
      if prototypes[source].fast_replaceable_group ~=
          prototypes[target].fast_replaceable_group then
        error("Variant upgrade fast-replace group mismatch: " .. source ..
          " -> " .. target)
      end
      prototypes[source].next_upgrade = target
    end
  end
end

return variant_upgrades

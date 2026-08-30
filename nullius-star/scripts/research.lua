local research = {}

local function complete(technology, visited)
  if visited[technology.name] then return 0 end
  visited[technology.name] = true

  local count = 0
  for _, prerequisite in pairs(technology.prerequisites) do
    count = count + complete(prerequisite, visited)
  end

  if not technology.researched then
    technology.researched = true
    count = count + 1
  end
  return count
end

function research.complete_with_prerequisites(technology)
  return complete(technology, {})
end

function research.complete_prerequisites(technology)
  local visited = {[technology.name] = true}
  local count = 0
  for _, prerequisite in pairs(technology.prerequisites) do
    count = count + complete(prerequisite, visited)
  end
  return count
end

return research

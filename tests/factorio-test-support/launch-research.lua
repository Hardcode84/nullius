return function()
  local before = {}
  for name, technology in pairs(data.raw.technology) do
    before[name] = table.deepcopy(technology.prerequisites or {})
  end
  local moved = {
    ["nullius-rocket-science-1"]=true,
    ["nullius-checkpoint-rocket-fuel"]=true,
    ["nullius-rocket-science-2"]=true,
  }
  local function closure(graph, name, result)
    if result[name] then return end
    result[name] = true
    for _, parent in ipairs(assert(graph[name], "unknown technology "..name)) do closure(graph,parent,result) end
  end
  return function()
    local after = {}
    for name, technology in pairs(data.raw.technology) do after[name] = technology.prerequisites or {} end
    for name in pairs(before) do
      if not moved[name] then
        local expected, actual = {}, {}
        closure(before,name,expected)
        closure(after,name,actual)
        for ancestor in pairs(expected) do
          assert(actual[ancestor], name.." lost prerequisite "..ancestor)
        end
        for ancestor in pairs(actual) do
          assert(expected[ancestor], name.." gained prerequisite "..ancestor)
        end
      end
    end
    local fuel, rocket = after["nullius-rocket-science-1"], after["nullius-rocket-science-2"]
    assert(#fuel==1 and fuel[1]=="nullius-physics", "early rocket fuel")
    assert(#rocket==2 and rocket[1]=="nullius-checkpoint-rocket-fuel" and rocket[2]=="nullius-composites-2", "early rocket")
  end
end

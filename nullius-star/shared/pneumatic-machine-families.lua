local pneumatic_machine_families = {}

local function matching_names(prototypes_by_name, predicate)
  local result = {}
  for name in pairs(prototypes_by_name) do
    if predicate(name) then result[#result + 1] = name end
  end
  table.sort(result)
  return result
end

function pneumatic_machine_families.is_normal_assembler(name)
  return string.match(name, "^nullius%-small%-assembler%-%d+$") ~= nil or
    string.match(name, "^nullius%-medium%-assembler%-%d+$") ~= nil or
    string.match(name, "^nullius%-large%-assembler%-%d+$") ~= nil
end

function pneumatic_machine_families.normal_assemblers(prototypes_by_name)
  return matching_names(prototypes_by_name,
    pneumatic_machine_families.is_normal_assembler)
end

function pneumatic_machine_families.is_barrel_pump(name)
  return string.match(name, "^nullius%-barrel%-pump%-%d+$") ~= nil
end

function pneumatic_machine_families.barrel_pumps(prototypes_by_name)
  return matching_names(prototypes_by_name,
    pneumatic_machine_families.is_barrel_pump)
end

return pneumatic_machine_families

return function(prototypes, name)
  for kind in pairs(defines.prototypes.item) do
    local item = prototypes[kind] and prototypes[kind][name]
    if item then return item end
  end
end

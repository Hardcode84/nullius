local cases = {
  {name="nullius-large-chest-1",size=100,upgrade="nullius-large-chest-2"},
  {name="nullius-large-chest-2",size=150},
}
for family,mode in pairs({storage="storage",supply="passive-provider",demand="requester",
    buffer="buffer",dispatch="active-provider"}) do
  for _, variant in ipairs({{"small",1,20},{"large",1,100},{"large",2,150}}) do
    table.insert(cases,{name="nullius-" .. variant[1] .. "-" .. family .. "-chest-" .. variant[2],
      size=variant[3],mode=mode,frames=variant[2]==1 and 16 or 7,
      trash=(family=="demand" or family=="buffer") and (variant[1]=="small" and 5 or variant[3]/5) or 0,
      upgrade=variant[2]==1 and (variant[1]=="small" and mode .. "-chest" or
        "nullius-large-" .. family .. "-chest-2") or nil})
  end
end
return cases

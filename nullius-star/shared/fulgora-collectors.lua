local config = {profiles={}, by_pole={}, by_name={}, names={}}
local base = "nullius-pole-lightning-collector"
local families = {
  {name="pole", range=0, poles={"small-electric-pole", "medium-electric-pole", "nullius-power-pole-3", "nullius-power-pole-4"}},
  {name="pylon", range=20, poles={"big-electric-pole", "nullius-pylon-2", "nullius-pylon-3"}},
  {name="substation", range=10, poles={"substation", "nullius-substation-2", "nullius-substation-3"}},
}
for _, family in ipairs(families) do
  for tier, pole in ipairs(family.poles) do
    local name = pole == "small-electric-pole" and base or base.."-"..family.name.."-"..tier
    local profile = {name=name, efficiency=tier*0.2, buffer_MJ=tier*200,
      output_MW=tier*100, range_elongation=family.range}
    config.profiles[#config.profiles+1] = profile
    config.by_pole[pole] = profile
    config.by_name[name] = profile
    config.names[#config.names+1] = name
  end
end
-- Other mods' poles retain basic lightning collection.
config.default = config.by_pole["small-electric-pole"]
return config

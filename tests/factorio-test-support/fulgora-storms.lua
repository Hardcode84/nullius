-- Test-only observation; preserve production strike effects and damage.
local bolt = data.raw.lightning["nullius-fulgora-lightning"]
local properties = data.raw.planet["nullius-fulgora"].lightning_properties
assert(properties.lightning_types[1] == bolt.name)
assert(properties.lightning_multiplier_at_day == 0.25)
assert(properties.lightning_multiplier_at_night == 1)
assert(properties.lightnings_per_chunk_per_tick == 1/600)
assert((type(bolt.damage)=="table" and bolt.damage.amount or bolt.damage)==0)
for _,field in ipairs({"created_effect", "strike_effect"}) do
  bolt[field] = {bolt[field], {
    type="direct", action_delivery={type="instant", target_effects={
      type="script", effect_id="fulgora-storm-"..field,
    }},
  }}
end

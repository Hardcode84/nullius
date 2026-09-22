-- Test access to crafting input inventories in Factorio 2.0 and 2.1.
local api = {}
if require("__nullius-star__/factorio-version").is_2_1 then
  api.crafting_input = defines.inventory.crafter_input
else
  assert(string.match(script.active_mods.base, "^2%.0%."), "unsupported Factorio version")
  api.crafting_input = defines.inventory.assembling_machine_input
end
assert(api.crafting_input, "missing native crafting input inventory index")
return api

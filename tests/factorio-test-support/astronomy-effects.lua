local category = "factorio-test-astronomy-effects"
for _, variant in ipairs{"electric", "pneumatic", "default-floor"} do
  local source = variant == "pneumatic" and "nullius-chemical-plant-1-pneumatic" or "nullius-chemical-plant-1"
  local machine = table.deepcopy(data.raw["assembling-machine"][source])
  machine.name = "factorio-test-astronomy-effects-"..variant.."-recorder"
  machine.minable = nil
  machine.next_upgrade = nil
  machine.crafting_categories = {category}
  machine.crafting_speed = 1
  machine.module_slots = 0
  machine.allowed_effects = {"speed", "consumption"}
  machine.effect_receiver = {
    uses_module_effects=false, uses_beacon_effects=false,
    uses_surface_effects=false, uses_local_effects=true,
    consumption_limits={low=-0.9999,high=1000},
  }
  if variant ~= "default-floor" then
    machine.effect_receiver.speed_limits = {low=-0.9999,high=1000}
  end
  machine.hidden_in_factoriopedia = true
  data:extend({machine})
end
data:extend({
  {type="recipe-category",name=category},
  {type="recipe",name=category,enabled=true,hidden=true,categories={category},energy_required=1,
    ingredients={{type="item",name="iron-plate",amount=1},{type="fluid",name="nullius-hydrogen",amount=1}},
    results={{type="item",name="copper-plate",amount=1}}},
})

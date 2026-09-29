-- Cold prototype path. The pole supplies the graphics and build item.
local collector = table.deepcopy(data.raw["lightning-attractor"]["lightning-rod"])
collector.name = "nullius-pole-lightning-collector"
collector.localised_name = {"entity-name.lightning"}
collector.hidden = true
collector.hidden_in_factoriopedia = true
collector.flags = {"placeable-off-grid", "not-on-map", "not-blueprintable",
  "not-deconstructable", "not-upgradable"}
collector.selectable_in_game = false
collector.minable = nil
collector.collision_box = {{0,0},{0,0}}
collector.selection_box = {{0,0},{0,0}}
collector.collision_mask = {layers={}}
collector.chargable_graphics = nil
collector.water_reflection = nil
collector.working_sound = nil
collector.corpse = nil
collector.dying_explosion = nil
collector.factoriopedia_simulation = nil
collector.efficiency = 0.2
collector.range_elongation = 0
collector.energy_source = {type="electric", buffer_capacity="200MJ",
  usage_priority="primary-output", input_flow_limit="0W",
  output_flow_limit="500kW", drain="0W"}
data:extend({collector})

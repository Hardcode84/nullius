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
for _, profile in ipairs(require("shared.fulgora-collectors").profiles) do
  local variant = table.deepcopy(collector)
  variant.name = profile.name
  variant.efficiency = profile.efficiency
  variant.range_elongation = profile.range_elongation
  variant.energy_source = {type="electric", buffer_capacity=profile.buffer_MJ.."MJ",
    usage_priority="primary-output", input_flow_limit="0W",
    output_flow_limit=profile.output_MW.."MW", drain="0W"}
  data:extend({variant})
end

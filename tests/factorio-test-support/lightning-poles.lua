-- Bounded test fixtures: fixed 1 MJ strikes, no ambient lightning or generation.
local pole = table.deepcopy(data.raw["electric-pole"]["small-electric-pole"])
pole.name = "factorio-test-lightning-pole"
pole.localised_name = "Lightning pole experiment"
pole.minable = nil
pole.next_upgrade = nil
pole.fast_replaceable_group = nil
pole.maximum_wire_distance = 10
pole.supply_area_distance = 3
pole.flags = {"placeable-off-grid", "player-creation"}

local collector = table.deepcopy(data.raw["lightning-attractor"]["lightning-rod"])
collector.name = "factorio-test-pole-collector"
collector.localised_name = "Hidden pole collector experiment"
collector.flags = {"placeable-off-grid", "not-on-map", "not-blueprintable", "not-deconstructable"}
collector.hidden = true
collector.hidden_in_factoriopedia = true
collector.selectable_in_game = false
collector.minable = nil
collector.collision_box = {{0,0},{0,0}}
collector.collision_mask = {layers={}}
collector.selection_box = {{0,0},{0,0}}
collector.chargable_graphics = nil
collector.water_reflection = nil
collector.working_sound = nil
collector.corpse = nil
collector.dying_explosion = nil
collector.efficiency = 0.5
collector.range_elongation = 0
collector.energy_source = {type="electric",buffer_capacity="2MJ",
  usage_priority="primary-output",input_flow_limit="0W",output_flow_limit="60MW",drain="0W"}

local receiver = table.deepcopy(data.raw["electric-energy-interface"]["electric-energy-interface"])
receiver.name = "factorio-test-lightning-receiver"
receiver.localised_name = "Lightning energy receiver experiment"
receiver.minable = nil
receiver.energy_source = {type="electric",buffer_capacity="10MJ",
  usage_priority="secondary-input",input_flow_limit="60MW",output_flow_limit="0W",drain="0W"}
receiver.energy_production = "0W"
receiver.energy_usage = "0W"
receiver.collision_mask = {layers={}}

local bolt = table.deepcopy(data.raw.lightning.lightning)
bolt.name = "factorio-test-lightning"
bolt.localised_name = "Lightning experiment strike"
bolt.energy = "1MJ"
bolt.damage = 0
bolt.time_to_damage = 1
bolt.created_effect = nil
local function event(id)
  return {type="direct",action_delivery={type="instant",target_effects={type="script",effect_id=id}}}
end
bolt.strike_effect = event("experiment-pole-strike")
bolt.attractor_hit_effect = event("experiment-attractor-strike")

local planet = table.deepcopy(data.raw.planet.nauvis)
planet.name = "factorio-test-lightning-planet"
planet.localised_name = "Lightning experiment planet"
planet.map_gen_settings = {autoplace_controls={}, autoplace_settings={
  entity={treat_missing_as_default=false,settings={}},
  decorative={treat_missing_as_default=false,settings={}},
}}
planet.distance = 100
planet.orientation = 0.4
planet.lightning_properties = {
  lightnings_per_chunk_per_tick=0,search_radius=8,lightning_types={bolt.name},
  priority_rules={
    {type="prototype",string="lightning-attractor",priority_bonus=1000},
    {type="prototype",string="electric-pole",priority_bonus=100},
  },
  exemption_rules={{type="prototype",string="electric-energy-interface"}},
}
data:extend({pole,collector,receiver,bolt,planet})

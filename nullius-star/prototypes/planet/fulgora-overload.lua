local sink={
  type="electric-energy-interface",
  name=require("shared.fulgora-overload").sink,
  localised_name={"entity-name.nullius-fulgora-overload-sink"},
  icon="__base__/graphics/icons/signal/signal-alert.png",icon_size=64,
  hidden=true,hidden_in_factoriopedia=true,
  flags={"placeable-off-grid","not-on-map","not-blueprintable","not-deconstructable","not-upgradable"},
  selectable_in_game=false,
  collision_box={{0,0},{0,0}},collision_mask={layers={}},selection_box={{0,0},{0,0}},
  picture={filename="__core__/graphics/empty.png",width=1,height=1},
  energy_source={type="electric",buffer_capacity="1TJ",usage_priority="primary-input",
    input_flow_limit="1TW",output_flow_limit="0W",drain="0W",
    render_no_power_icon=false,render_no_network_icon=false},
  energy_usage="1TW",energy_production="0W",
  allow_copy_paste=false,gui_mode="none",
}
data:extend({sink})

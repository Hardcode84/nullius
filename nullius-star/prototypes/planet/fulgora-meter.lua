local output=table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
output.name="nullius-grid-meter-output"
output.localised_name={"entity-name.nullius-grid-meter-output"}
output.flags={"placeable-off-grid","not-on-map","not-blueprintable","not-deconstructable","not-upgradable","hide-alt-info"}
output.hidden=true
output.hidden_in_factoriopedia=true
output.minable=nil
output.fast_replaceable_group=nil
output.selectable_in_game=false
output.collision_box={{0,0},{0,0}}
output.selection_box={{0,0},{0,0}}
output.collision_mask={layers={}}
output.sprites=nil
output.activity_led_sprites=nil
output.water_reflection=nil
output.draw_circuit_wires=false
data:extend({output})

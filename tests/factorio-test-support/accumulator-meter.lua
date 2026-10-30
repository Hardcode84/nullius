-- Hidden circuit output for the accumulator grid-meter experiment.
local output=table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
output.name="factorio-test-meter-output"
output.localised_name="Grid meter output"
output.flags={"placeable-off-grid","not-on-map","not-blueprintable","not-deconstructable","not-upgradable"}
output.hidden=true
output.hidden_in_factoriopedia=true
output.minable=nil
output.selectable_in_game=false
output.collision_box={{0,0},{0,0}}
output.selection_box={{0,0},{0,0}}
output.collision_mask={layers={}}
output.sprites=nil
output.activity_led_sprites=nil
output.draw_circuit_wires=false
data:extend({output})

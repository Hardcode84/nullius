-- Cold data path: extractor modes share the original item and pipe geometry.
data:extend({{type="recipe-category", name="nullius-reinjection"}})
for tier=1,2 do
  local name="nullius-extractor-"..tier
  local base=data.raw["mining-drill"][name]
  local variant={type="assembling-machine",name=name.."-reinjection",
    localised_name={"entity-name.nullius-reinjection",base.localised_name or {"entity-name."..name}},
    localised_description={"entity-description.nullius-reinjection"},
    hidden_in_factoriopedia=true,placeable_by={item=name,count=1},
    crafting_categories={"nullius-reinjection"},crafting_speed=1,
    energy_usage="390kW",energy_source={type="electric",usage_priority="secondary-input",drain="10kW"},
    module_slots=0,allowed_effects={},allowed_module_categories={},
    effect_receiver={uses_module_effects=false,uses_beacon_effects=false,uses_surface_effects=false},
    fluid_boxes_off_when_no_fluid_recipe=false,
    surface_conditions={{property="magnetic-field",min=99}},
  }
  for _,field in ipairs({"icons","flags","minable","max_health","corpse","dying_explosion",
      "collision_box","selection_box","collision_mask","fast_replaceable_group",
      "drawing_box_vertical_extension","resistances","graphics_set","working_sound",
      "open_sound","close_sound","damaged_trigger_effect","impact_category",
      "circuit_connector","circuit_wire_max_distance"}) do
    variant[field]=table.deepcopy(base[field])
  end
  variant.next_upgrade=tier==1 and "nullius-extractor-2-reinjection" or nil
  local box=table.deepcopy(base.output_fluid_box)
  box.production_type="input"
  for _,connection in ipairs(box.pipe_connections) do connection.flow_direction="input" end
  variant.fluid_boxes={box}
  data:extend({variant})
end

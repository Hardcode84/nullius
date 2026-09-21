data:extend({{type="item",name="factorio-test-reactor-fuel",stack_size=10,
  icon="__base__/graphics/icons/uranium-fuel-cell.png",
  fuel_category="nullius-nuclear",fuel_value="10GJ"}})
-- Keep native reactor geometry, power, and neighbour bonus for mixed pairs.
local base=table.deepcopy(data.raw.reactor["nuclear-reactor"])
base.name="factorio-test-base-reactor"
base.minable=nil
base.energy_source.fuel_categories={"nullius-nuclear"}
data:extend({base})

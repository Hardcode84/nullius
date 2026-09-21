-- The engine generates barrel items and recipes from these declared fluids.
data:extend({
  {type="recipe-category",name="nullius-barrel"},
  {type="recipe-category",name="nullius-unbarrel"},
  {type="item-subgroup",name="fill-probe",group="other"},
  {type="item-subgroup",name="empty-probe",group="other"},
  {type="item-subgroup",name="probe",group="other"},
  {type="item-subgroup",name="hidden",group="other"},
})
for _,case in ipairs(require("scenarios/barrel-recipes/fixture")) do
  local fluid=table.deepcopy(data.raw.fluid.water)
  fluid.name=case.name
  fluid.subgroup="probe"
  fluid.auto_barrel=true
  fluid.default_temperature=case.temperature
  fluid.max_temperature=case.temperature+100
  fluid.fuel_value=case.fuel
  fluid.gas_temperature=case.gas
  data:extend({fluid})
end
require("executor")

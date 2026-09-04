local contract = require("shared.vulcanus-tips")

data:extend({
  {
    type = "tips-and-tricks-item-category",
    name = contract.category.name,
    order = contract.category.order,
  },
})

for _, tip in ipairs(contract.tips) do
  local prototype = table.deepcopy(tip)
  prototype.type = "tips-and-tricks-item"
  prototype.category = contract.category.name
  data:extend({prototype})
end

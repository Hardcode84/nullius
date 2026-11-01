for _, planet in ipairs({"vulcanus", "fulgora"}) do
  local contract = require("shared." .. planet .. "-tips")
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
end

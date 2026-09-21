local pictures
if require("factorio-version").is_2_1 then
  pictures = require("__base__/prototypes/entity/assembler-pictures").assembler2pipepictures
else
  pictures = assembler2pipepictures()
end

return function()
  return table.deepcopy(pictures)
end

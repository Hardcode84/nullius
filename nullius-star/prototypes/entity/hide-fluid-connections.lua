local modern = require("factorio-version").is_2_1

-- Apply before variants copy the fluid box.
return function(box)
  if modern then
    for _, connection in ipairs(box.pipe_connections) do
      connection.hide_connection_info = true
    end
  else
    box.hide_connection_info = true
  end
  return box
end

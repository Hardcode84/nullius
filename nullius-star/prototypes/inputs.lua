local ICONPATH = "__nullius-star__/graphics/icons/"
local ENTITYPATH = "__nullius-star__/graphics/entity/"

-- Configurable Valves 0.3.3 uses the old keypad names. Keep the same keys on 2.1.
if require("factorio-version").is_2_1 then
  for _, binding in ipairs({
    {"configurable-valves-minus", "PAD -", "KP_MINUS"},
    {"configurable-valves-plus", "PAD +", "KP_PLUS"},
  }) do
    local input = data.raw["custom-input"][binding[1]]
    if input.key_sequence == binding[2] then input.key_sequence = binding[3] end
  end
end

data:extend({
  {
    type = "shortcut",
    name = "nullius-autocraft",
    action = "lua",
    toggleable = true,
    icon = "__base__/graphics/icons/assembling-machine-1.png",
    small_icon = "__base__/graphics/icons/assembling-machine-1.png",
    order = "nullius-icg",
  },
  {
    type = "custom-input",
    name = "nullius-prioritize",
    order = "nullius-ibb",
    key_sequence = "CONTROL + R",
	  include_selected_prototype = true
  },
  {
    type = "custom-input",
    name = "nullius-upload-mind",
    order = "nullius-icb",
    key_sequence = "U",
    include_selected_prototype = true
  },
  {
    type = "custom-input",
    name = "nullius-previous-body",
    order = "nullius-icc",
    key_sequence = "SHIFT + U"
  },
  {
    type = "custom-input",
    name = "nullius-next-body",
    order = "nullius-icd",
    key_sequence = "CONTROL + U"
  },
  {
    type = "shortcut",
    name = "nullius-remote-gui",
    icon = "__nullius-star__/graphics/icons/scout-remote.png",
    small_icon = "__nullius-star__/graphics/icons/scout-remote.png",
    technology_to_unlock = "nullius-exploration-1",
    unavailable_until_unlocked = true,
    order = "nulius-icf",
    action = "lua"
  }
})

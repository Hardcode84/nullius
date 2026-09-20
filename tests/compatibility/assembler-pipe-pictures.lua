local pictures = require("__nullius-star__/prototypes/entity/assembler-pipe-pictures")
local modern = string.match(mods.base, "^2%.1%.") ~= nil
local reference
if modern then
  reference = require("__base__/prototypes/entity/assembler-pictures").assembler2pipepictures
else
  reference = assembler2pipepictures()
end
local function equal(actual, expected)
  if type(expected) ~= "table" then assert(actual == expected, "pipe sprite mismatch") return end
  assert(type(actual) == "table", "pipe sprite table missing")
  for key, value in pairs(expected) do equal(actual[key], value) end
  for key in pairs(actual) do assert(expected[key] ~= nil, "unexpected pipe sprite field") end
end
local first, second = pictures(), pictures()
for _, direction in ipairs({"north", "east", "south", "west"}) do
  assert(first[direction] and first[direction] ~= second[direction], "independent direction tables")
  equal(first[direction], reference[direction])
end
first.north.filename = "changed"
equal(second, reference)
equal(pictures(), reference)

-- Declared medium/large tier-1 port geometry. Register the returned sprites so
-- the engine validates filenames, dimensions, and the fluid-box definitions.
for _, spec in ipairs({
  {name="compat-medium-assembler", half=1.2, positions={{0,-1},{0,1}}},
  {name="compat-large-assembler", half=1.7, positions={{0.5,-1.5},{-0.5,1.5}}},
}) do
  local machine = table.deepcopy(data.raw["assembling-machine"]["assembling-machine-2"])
  machine.name = spec.name
  machine.next_upgrade = nil
  machine.fast_replaceable_group = nil
  machine.collision_box = {{-spec.half,-spec.half},{spec.half,spec.half}}
  machine.selection_box = {{-spec.half-0.3,-spec.half-0.3},{spec.half+0.3,spec.half+0.3}}
  machine.fluid_boxes = {}
  for index, position in ipairs(spec.positions) do
    machine.fluid_boxes[index] = {production_type="input", volume=500,
      pipe_picture=pictures(), pipe_covers=pipecoverspictures(),
      pipe_connections={{flow_direction="input", position=position,
        direction=index == 1 and defines.direction.north or defines.direction.south}},
      secondary_draw_orders={north=-1}}
  end
  data:extend({machine})
end

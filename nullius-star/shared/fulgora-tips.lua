local chain = {
  {"nullius-fulgora-lightning-power", "[item=small-electric-pole]"},
  {"nullius-fulgora-grid-overload", "[item=nullius-grounding-coil]"},
  {"nullius-fulgora-sediment", "[tile=nullius-fulgora-sediment]"},
  {"nullius-fulgora-hydrocarbon-slurry", "[fluid=nullius-hydrocarbon-slurry]"},
  {"nullius-fulgora-overcharged-assembly", "[item=nullius-small-assembler-1]"},
}

local tips = {
  {
    name = "nullius-fulgora-briefing",
    tag = "[planet=nullius-fulgora]",
    order = "a",
    is_title = true,
    trigger = {
      type = "research",
      technology = "nullius-primitive-filtration",
    },
  },
}
-- Each tip activates once the preceding tip has been read.
for index, row in ipairs(chain) do
  tips[#tips + 1] = {
    name = row[1],
    tag = row[2],
    order = string.char(string.byte("a") + index),
    indent = 1,
    trigger = {type = "dependencies-met"},
    dependencies = {tips[index].name},
  }
end

return {
  category = {
    name = "nullius-fulgora",
    order = "l[nullius]-b[fulgora]",
  },
  tips = tips,
}

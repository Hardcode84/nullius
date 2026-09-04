return {
  category = {
    name = "nullius-vulcanus",
    order = "l[nullius]-a[vulcanus]",
  },
  tips = {
    {
      name = "nullius-vulcanus-briefing",
      tag = "[planet=nullius-vulcanus]",
      order = "a",
      is_title = true,
      trigger = {
        type = "research",
        technology = "nullius-pneumatic-technology",
      },
    },
    {
      name = "nullius-vulcanus-pneumatic-machinery",
      tag = "[fluid=nullius-compressed-volcanic-gas]",
      order = "b",
      indent = 1,
      trigger = {type = "dependencies-met"},
      dependencies = {"nullius-vulcanus-briefing"},
    },
    {
      name = "nullius-vulcanus-process-heat",
      tag = "[item=nullius-heat-pipe-1]",
      order = "c",
      indent = 1,
      trigger = {type = "dependencies-met"},
      dependencies = {"nullius-vulcanus-pneumatic-machinery"},
    },
    {
      name = "nullius-vulcanus-gas-bootstrap",
      tag = "[item=nullius-seawater-intake-1]",
      order = "d",
      indent = 1,
      trigger = {type = "dependencies-met"},
      dependencies = {"nullius-vulcanus-process-heat"},
    },
    {
      name = "nullius-vulcanus-thermal-industry",
      tag = "[item=nullius-small-furnace-1]",
      order = "e",
      indent = 1,
      trigger = {type = "dependencies-met"},
      dependencies = {"nullius-vulcanus-gas-bootstrap"},
    },
  },
}

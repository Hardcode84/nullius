local function first_vulcanus_arrival()
  return {
    type = "change-surface",
    surface = "nullius-vulcanus",
    count = 1,
  }
end

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
        technology = "nullius-probe-vulcanus",
      },
      skip_trigger = first_vulcanus_arrival(),
    },
    {
      name = "nullius-vulcanus-pneumatic-machinery",
      tag = "[fluid=nullius-compressed-volcanic-gas]",
      order = "b",
      indent = 1,
      trigger = first_vulcanus_arrival(),
    },
    {
      name = "nullius-vulcanus-process-heat",
      tag = "[item=nullius-heat-pipe-1]",
      order = "c",
      indent = 1,
      trigger = first_vulcanus_arrival(),
      dependencies = {"nullius-vulcanus-pneumatic-machinery"},
    },
    {
      name = "nullius-vulcanus-gas-bootstrap",
      tag = "[item=nullius-seawater-intake-1]",
      order = "d",
      indent = 1,
      trigger = first_vulcanus_arrival(),
      dependencies = {"nullius-vulcanus-process-heat"},
    },
    {
      name = "nullius-vulcanus-thermal-industry",
      tag = "[item=nullius-small-furnace-1]",
      order = "e",
      indent = 1,
      trigger = first_vulcanus_arrival(),
      dependencies = {"nullius-vulcanus-gas-bootstrap"},
    },
  },
}

data:extend({
  {
    type = "tips-and-tricks-item-category",
    name = "nullius-autocraft",
    order = "l[nullius]-b[autocraft]",
  },
  {
    type = "tips-and-tricks-item",
    name = "nullius-autocraft",
    category = "nullius-autocraft",
    order = "a",
    is_title = true,
    tag = "[item=nullius-iron-gear]",
    trigger = {
      type = "or",
      triggers = {
        {type = "research", technology = "nullius-primitive-robotics"},
        {type = "research", technology = "nullius-logistic-robot-1"},
      },
    },
  },
})

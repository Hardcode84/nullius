local probability = string.match(mods.base, "^2%.1%.") and "independent_probability" or "probability"

return {
  [1] = {
    {type = "item", name="nullius-guide-drone-iron-1", amount=1, [probability]=0.3},
    {type = "item", name="nullius-guide-drone-sandstone-1", amount=1, [probability]=0.2},
    {type = "item", name="nullius-guide-drone-bauxite-1", amount=1, [probability]=0.2},
    {type = "item", name="nullius-guide-drone-limestone-1", amount=1, [probability]=0.1},
    {type = "item", name="nullius-guide-drone-copper-1", amount=1, [probability]=0.1},
    {type = "item", name="nullius-guide-drone-uranium-1", amount=1, [probability]=0.1}
  },
  [2] = {
    {type = "item", name="nullius-guide-drone-iron-1", amount=1, [probability]=0.9},
    {type = "item", name="nullius-guide-drone-sandstone-1", amount=1, [probability]=0.8},
    {type = "item", name="nullius-guide-drone-bauxite-1", amount=1, [probability]=0.7},
    {type = "item", name="nullius-guide-drone-limestone-1", amount=1, [probability]=0.5},
    {type = "item", name="nullius-guide-drone-copper-1", amount=1, [probability]=0.4},
    {type = "item", name="nullius-guide-drone-uranium-1", amount=1, [probability]=0.3}
  }
}

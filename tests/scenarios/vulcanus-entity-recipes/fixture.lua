-- Frozen recipe contracts from the 2.0 Vulcanus entity definitions.
return {
  {name="nullius-lava-pumping",category="nullius-lava-pumping",seconds=1,ingredients={},products={{type="fluid",name="lava",amount=125}}},
  {name="nullius-vulcanus-deacon",category="nullius-low-temp-radiator",seconds=2,ingredients={{type="fluid",name="nullius-hydrogen-chloride",amount=60},{type="fluid",name="nullius-oxygen",amount=15}},products={{type="fluid",name="nullius-chlorine",amount=30},{type="fluid",name="nullius-water",amount=30}}},
  {name="nullius-vulcanus-cracking",category="nullius-high-temp-radiator",seconds=2,ingredients={{type="fluid",name="nullius-hydrogen-chloride",amount=60}},products={{type="fluid",name="nullius-hydrogen",amount=30},{type="fluid",name="nullius-chlorine",amount=30}}},
  {name="nullius-vulcanus-radiator-1",category="medium-crafting",seconds=10,ingredients={{type="item",name="nullius-iron-plate",amount=8},{type="item",name="nullius-silica",amount=4},{type="item",name="pipe",amount=4}},products={{type="item",name="nullius-vulcanus-radiator-1",amount=1}}},
  {name="nullius-vulcanus-radiator-2",category="medium-crafting",seconds=15,ingredients={{type="item",name="nullius-vulcanus-radiator-1",amount=1},{type="item",name="nullius-aluminum-sheet",amount=8},{type="item",name="nullius-silica",amount=8},{type="item",name="nullius-heat-pipe-1",amount=1},{type="item",name="nullius-pipe-2",amount=4}},products={{type="item",name="nullius-vulcanus-radiator-2",amount=1}}},
}

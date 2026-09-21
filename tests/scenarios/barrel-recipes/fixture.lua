-- Ordinary liquid, fuel, steam exception, and cold gas.
return {
  {name="nullius-water", amount=50, seconds=0.25, enabled=true, temperature=15},
  {name="nullius-compressed-air", amount=25, seconds=0.5, enabled=false, temperature=50, fuel="14kJ"},
  {name="nullius-steam", amount=50, seconds=0.25, enabled=false, temperature=165, fuel="6kJ", gas=100},
  {name="nullius-oxygen", amount=50, seconds=0.25, enabled=false, temperature=25, gas=0},
}

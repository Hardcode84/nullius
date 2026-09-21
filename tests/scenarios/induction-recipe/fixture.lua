-- Frozen Nullius integration contracts.
return {
  {count=20,seconds=6,order="nullius-cm",packs={1,1,1},prerequisites={"nullius-electronics-1"}},
  {count=80,seconds=15,order="nullius-dd",packs={2,1,1,1},prerequisites={"nullius-energy-distribution-2","induction-technology1"}},
  {count=250,seconds=30,order="nullius-dl",packs={2,1,1,1},prerequisites={"nullius-energy-distribution-3","nullius-projection-1","induction-technology2"}},
  {count=800,seconds=30,order="nullius-ek",packs={1,1,1,1,1},prerequisites={"nullius-broadcasting-2","induction-technology3"}},
  {count=2000,seconds=45,order="nullius-fm",packs={1,1,1,1,1,1},prerequisites={"nullius-battery-storage-4","induction-technology4"}},
}

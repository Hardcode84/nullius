-- Explicit generator boundaries; ratios and box capacities are frozen expectations.
return {
  {name="probe-10",size=10,ratio=5,boxes=5},
  {name="probe-20",size=20,ratio=5,boxes=10},
  {name="probe-50",size=50,ratio=5,boxes=20},
  {name="probe-100",size=100,ratio=5,boxes=50},
  {name="probe-200",size=200,ratio=5,boxes=100},
  {name="probe-300",size=300,ratio=5,boxes=120},
  {name="probe-301",size=301,ratio=10,boxes=60},
  {name="probe-500",size=500,ratio=10,boxes=100},
  {name="probe-75",size=75,ratio=5,boxes=30},
  {name="probe-science",size=100,ratio=5,boxes=100,type="tool",science=true},
  {name="probe-science-75",size=75,ratio=5,boxes=30,type="tool",science=true},
  {name="probe-module",size=50,ratio=5,boxes=20,type="module"},
  {name="probe-ammo",size=100,ratio=5,boxes=50,type="ammo"},
  {name="probe-capsule",size=100,ratio=5,boxes=50,type="capsule"},
  {name="probe-repair",size=100,ratio=5,boxes=50,type="repair-tool"},
  {name="probe-override",size=100,override=500,ratio=10,boxes=100},
}

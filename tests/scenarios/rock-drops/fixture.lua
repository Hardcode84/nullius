-- Independent expected contracts: item, minimum, maximum, probability.
local function drop(name, lo, hi, p) return {name, lo, hi, p or 1} end
local cases = {
  ["big-fulgora-rock"] = {mining={drop("stone",19,25)},loot={}},
  ["huge-rock"] = {mining={drop("stone",24,50),drop("coal",24,50)},loot={}},
  ["big-rock"] = {mining={drop("stone",20,20)},loot={}},
  ["big-sand-rock"] = {mining={drop("stone",19,25)},loot={}},
  ["nullius-crystal-rock"] = {
    mining={drop("nullius-silica",16,16),drop("nullius-alumina",8,8)},
    loot={drop("nullius-silica",4,12),drop("nullius-alumina",2,6)},
  },
  ["huge-volcanic-rock"] = {
    mining={drop("stone",10,25),drop("nullius-graphite",3,8),drop("nullius-rutile",1,3)}, loot={},
  },
  ["big-volcanic-rock"] = {
    mining={drop("stone",5,15),drop("nullius-graphite",2,5),drop("nullius-rutile",0,2,0.5)}, loot={},
  },
}
if require("__nullius-star__/factorio-version").is_2_1 then
  cases["huge-volcanic-rock-hot"] = cases["huge-volcanic-rock"]
  cases["big-volcanic-rock-hot"] = cases["big-volcanic-rock"]
end
local regular = {
  tan={"nullius-gypsum","nullius-limestone","nullius-mineral-dust"},
  dustyrose={"nullius-bauxite","stone","nullius-sand"},
  cream={"nullius-limestone","nullius-gypsum","nullius-mineral-dust"},
  brown={"nullius-bauxite","stone","nullius-sand"},
  beige={"nullius-limestone","nullius-gypsum","nullius-mineral-dust"},
  red={"nullius-bauxite","stone","nullius-sand"},
  violet={"iron-ore","stone","nullius-gravel"},
  purple={"iron-ore","stone","nullius-gravel"},
  aubergine={"iron-ore","stone","nullius-gravel"},
  volcanic={"iron-ore","stone","nullius-gravel"},
  black={"iron-ore","stone","nullius-gravel"},
  grey={"stone","nullius-sandstone","nullius-gravel"},
  white={"nullius-limestone","stone","nullius-mineral-dust"},
}
for color, items in pairs(regular) do
  cases["huge-rock-" .. color] = {
    mining={drop(items[1],5,10),drop(items[2],0,5)},
    loot={drop(items[1],2,8),drop(items[2],0,4),drop(items[3],0,4)},
  }
  cases["big-rock-" .. color] = {
    mining={drop(items[1],5,5)}, loot={drop(items[1],3,4),drop(items[3],0,2)},
  }
end
for color, secondary in pairs({tan="nullius-bauxite",red="nullius-bauxite",
    purple="iron-ore",black="iron-ore",white="nullius-limestone"}) do
  local case = {
    mining={drop("nullius-sandstone",2,5),drop(secondary,1,1)},
    loot={drop("nullius-sandstone",1,4),drop(secondary,0,1),drop("nullius-sand",0,1)},
  }
  if color == "white" then table.insert(case.mining,drop("nullius-soda-ash",1,2,0.1)) end
  cases["sand-big-rock-" .. color] = case
end
return cases

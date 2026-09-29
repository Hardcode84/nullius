-- given: fixed native sources; zero, 100 kW, or 1.2 MW demand; no storage.
-- place/connect: eight isolated networks on the test surface, no ambient storms.
-- act/run: measure native flow and sample overloads at tick 60.
-- expect: both the 2x ratio and 1 MW excess floor must be strictly exceeded.
local overload={
  offline=function(pole) return remote.call("nullius-test-overload","offline",pole) end}
local P="factorio-test-trip-"
local cases={
  {supply=0,demand=0,trip=false},
  {supply=900000,demand=0,trip=false},
  {supply=1000000,demand=0,trip=false},
  {supply=1000060,demand=0,trip=true},
  {supply=1100000,demand=100000,trip=false},
  {supply=1100060,demand=100000,trip=true},
  {supply=2400000,demand=1200000,trip=false},
  {supply=2400060,demand=1200000,trip=true},
}
local function check(ok,message) storage.assertions=storage.assertions+1;assert(ok,message) end
script.on_nth_tick(1,function()
  if game.tick==0 then return end
  script.on_nth_tick(1,nil);storage.assertions=0;storage.rows={}
  local surface=game.planets["nullius-fulgora"].create_surface()
  surface.request_to_generate_chunks({180,0},8);surface.force_generate_chunk_requests()
  for _,entity in pairs(surface.find_entities()) do entity.destroy() end
  local tiles={};for x=-10,380 do for y=-10,10 do tiles[#tiles+1]={name="grass-1",position={x,y}} end end
  surface.set_tiles(tiles,true)
  for i,case in ipairs(cases) do
    local x=(i-1)*50
    local pole=assert(surface.create_entity{name=P.."pole",position={x,0},force="player",raise_built=true})
    assert(surface.create_entity{name=P.."source-"..case.supply,position={x+1,0},force="player",raise_built=true})
    if case.demand>0 then
      local name=P.."load"..(case.demand==100000 and "" or "-"..case.demand)
      assert(surface.create_entity{name=name,position={x+1,1},force="player",raise_built=true})
    end
    storage.rows[i]=pole
  end
end)
script.on_nth_tick(29,function()
  if game.tick==0 then return end
  script.on_nth_tick(29,nil)
  for i,case in ipairs(cases) do
    local flow=storage.rows[i].electric_network.parent_network.flow_last_tick
    local supply=(flow.primary_output+flow.secondary_output+flow.solar_output)*60
    local demand=(flow.primary_demand+flow.secondary_demand+flow.tertiary_demand)*60
    check(math.abs(supply-case.supply)<0.001,"native supply case "..i)
    check(math.abs(demand-case.demand)<0.001,"native demand case "..i)
  end
end)
script.on_nth_tick(61,function()
  if game.tick==0 then return end
  script.on_nth_tick(61,nil)
  for i,case in ipairs(cases) do
    check(overload.offline(storage.rows[i])==case.trip,"threshold case "..i)
  end
  helpers.write_file("factorio-tests/fulgora-grid-threshold.json",helpers.table_to_json{
    schema=1,case="fulgora-grid-threshold",status="pass",failure_count=0,
    assertions=storage.assertions,tick=game.tick,factorio_version=script.active_mods.base},false)
end)

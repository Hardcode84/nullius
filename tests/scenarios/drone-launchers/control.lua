-- given: both launcher tiers, five drone types, one full load per launcher.
-- place: each launcher on a separate surface.
-- act: place the matching targeting flare beyond the minimum range.
-- run: 1200 ticks.
-- expect: one ammunition slot, full capacity, and exactly one drone fired.
local cases = {
  {"nullius-scout-drone-1", "nullius-scout-flare"},
  {"nullius-scout-drone-2", "nullius-scout-flare"},
  {"nullius-demolition-drone", "nullius-demolition-flare"},
  {"nullius-excavation-drone", "nullius-excavation-flare"},
  {"nullius-shallow-excavation-drone", "nullius-shallow-excavation-flare"}
}
local assertions = 0
local function check(condition, message)
  assertions = assertions + 1
  assert(condition, message)
end
script.on_nth_tick(1, function()
  script.on_nth_tick(1, nil)
  storage.rows = {}
  for tier = 1, 2 do
    for index, case in ipairs(cases) do
      local surface = game.create_surface("launcher-"..tier.."-"..index,
        {width=384, height=64, autoplace_settings={entity={treat_missing_as_default=false}}})
      surface.request_to_generate_chunks({0,0}, 1)
      surface.request_to_generate_chunks({128,0}, 1)
      surface.force_generate_chunk_requests()
      for _, entity in pairs(surface.find_entities()) do entity.destroy() end
      local tiles = {}
      for x=-4,4 do for y=-4,4 do
        tiles[#tiles+1] = {name="grass-1", position={x,y}}
      end end
      surface.set_tiles(tiles)
      local launcher = assert(surface.create_entity{
        name="nullius-drone-launcher-"..tier, position={0,0}, force="player"})
      local inventory = launcher.get_inventory(defines.inventory.artillery_turret_ammo)
      local capacity = tier == 1 and 30 or 50
      check(#inventory == 1, "one ammunition slot")
      check(launcher.insert{name=case[1], count=capacity+1} == capacity, "full capacity")
      check(launcher.insert{name=cases[index == 1 and 2 or 1][1], count=1} == 0,
        "reject mixed ammunition")
      check(launcher.prototype.automated_ammo_count == 10, "automatic ammunition limit")
      assert(surface.create_entity{name=case[2], position={128,0}, force="player",
        movement={0,0}, height=0, vertical_speed=0, frame_speed=1})
      storage.rows[#storage.rows+1] = {launcher=launcher, name=case[1], capacity=capacity}
    end
  end
  storage.assertions = assertions
end)
script.on_nth_tick(1200, function(event)
  if event.tick == 0 then return end
  script.on_nth_tick(1200, nil)
  assertions = storage.assertions
  for _, row in ipairs(storage.rows) do
    check(row.launcher.get_item_count(row.name) == row.capacity-1,
      row.launcher.name.." fired exactly one "..row.name)
  end
  helpers.write_file("factorio-tests/drone-launchers.json", helpers.table_to_json{
    schema=1, case="drone-launchers", status="pass", assertions=assertions,
    tick=game.tick, failure_count=0, failures={}
  }, false)
end)

require("__nullius-star__/scripts/drone")
local assertions = 0
local function check(ok, message)
  assertions = assertions + 1
  assert(ok, message)
end
local function output(row)
  return row.chest.get_inventory(defines.inventory.chest).get_item_count("iron-ore")
end
script.on_nth_tick(30, function()
  if game.tick == 0 then
    local surface = game.surfaces.nauvis
    surface.request_to_generate_chunks({0,0}, 2)
    surface.force_generate_chunk_requests()
    for _, entity in pairs(surface.find_entities_filtered{area={{-24,-24},{24,24}}}) do entity.destroy() end
    local tiles = {}
    for x=-24,24 do for y=-24,24 do tiles[#tiles+1] = {name="grass-1", position={x,y}} end end
    surface.set_tiles(tiles)
    storage.rows = {}
    for index, x in ipairs({-8.5, 8.5}) do
      local drill = surface.create_entity{name="factorio-test-drone-miner", position={x,0.5},
        direction=defines.direction.north, force="player"}
      check(drill ~= nil, "drill placed before ore deposition")
      local chest = surface.create_entity{name="steel-chest", position=drill.drop_position, force="player"}
      check(chest ~= nil, "native drill output chest placed")
      drill.disabled_by_script = index == 2
      storage.rows[index] = {drill=drill, chest=chest}
    end
  elseif game.tick == 120 then
    for index, row in ipairs(storage.rows) do
      check(output(row) == 0, "empty drill has no output")
      check(row.drill.mining_target == nil, "drill has no resource before deposition")
      miner_effect({surface_index=row.drill.surface.index, target_position=row.drill.position},
        "iron-ore", 2, 1)
      check(row.drill.surface.count_entities_filtered{type="resource", name="iron-ore",
        position=row.drill.position, radius=2.5} > 0, "drone deposited ore")
      check(row.drill.disabled_by_script == (index == 2), "drone must preserve script disable flag")
    end
  elseif game.tick == 720 then
    check(output(storage.rows[1]) > 0, "enabled drill resumes native mining")
    check(storage.rows[1].drill.mining_target ~= nil, "enabled drill acquired deposited ore")
    check(output(storage.rows[2]) == 0, "disabled drill produced no ore")
    check(storage.rows[2].drill.disabled_by_script, "disabled drill remains disabled")
    storage.rows[2].drill.disabled_by_script = false
  elseif game.tick == 1320 then
    check(output(storage.rows[2]) > 0, "disabled drill mines after explicit re-enable")
    check(storage.rows[2].drill.mining_target ~= nil, "re-enabled drill acquired deposited ore")
    script.on_nth_tick(30, nil)
    local result = {schema=1, case="drone-mining", status="pass",
      factorio_version=script.active_mods.base, tick=game.tick, assertions=assertions,
      failure_count=0, failures={}, observations={enabled_output=output(storage.rows[1]),
        reenabled_output=output(storage.rows[2])}}
    helpers.write_file("factorio-tests/drone-mining.json", helpers.table_to_json(result), false)
  end
end)

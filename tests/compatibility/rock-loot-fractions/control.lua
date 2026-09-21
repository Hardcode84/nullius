script.on_nth_tick(1, function()
  script.on_nth_tick(1, nil)
  local surface = game.surfaces[1]
  local results = {}
  for case=1,4 do
    local counts = {}
    for sample=1,10000 do
      local entity = surface.create_entity{name="loot-fraction-" .. case, position={0,0}}
      assert(entity.die())
      local count = 0
      for _, item in pairs(surface.find_entities_filtered{type="item-entity"}) do
        count = count + item.stack.count
        item.destroy()
      end
      counts[tostring(count)] = (counts[tostring(count)] or 0) + 1
    end
    results[case] = counts
  end
  helpers.write_file("loot-fractions.json", helpers.table_to_json(results), false)
end)

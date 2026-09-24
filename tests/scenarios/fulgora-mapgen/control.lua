-- given: production planet settings; seeds 0, 1, and 8675309.
-- place: native terrain at the origin and two distant locations per seed.
-- connect: no factory or injected resources.
-- act: request and finish chunk generation.
-- run: one check at tick 1.
-- expect: dry natural terrain only; no ruins, scrap, fluid tiles, or enemies.
local allowed_tiles = {['fulgoran-dust'] = true, ['fulgoran-dunes'] = true,
  ['fulgoran-sand'] = true, ['fulgoran-rock'] = true, ['nullius-fulgora-sediment'] = true}
local allowed_decoratives = {['medium-fulgora-rock'] = true,
  ['small-fulgora-rock'] = true, ['tiny-fulgora-rock'] = true}
local landmarks = {['big-fulgora-rock'] = {19,25}, fulgurite = {8,12},
  ['fulgurite-small'] = {8,16}}
local assertions = 0
local function check(value, message)
  assertions = assertions + 1
  assert(value, message)
end
script.on_nth_tick(1, function()
  if game.tick == 0 then return end
  script.on_nth_tick(1, nil)
  local planet = game.planets['nullius-fulgora']
  check(planet and not planet.prototype.hidden, 'Fulgora is missing or hidden')
  local surface = planet.create_surface()
  local settings = surface.map_gen_settings
  check(settings.no_enemies_mode, 'natural enemies enabled')
  check(not settings.default_enable_all_autoplace_controls, 'unspecified controls enabled')
  check(settings.autoplace_controls.scrap == nil, 'scrap control remains')
  for _, kind in ipairs({'tile', 'entity', 'decorative'}) do
    check(settings.autoplace_settings[kind].treat_missing_as_default == false,
      'unspecified ' .. kind .. ' autoplace enabled')
  end
  check(surface.get_property('pressure') == 800, 'wrong pressure')
  local tile_counts, decorative_counts, cliff_count = {}, {}, 0
  local entity_counts, basin_counts = {}, {}
  for _, seed in ipairs({0, 1, 8675309}) do
    local seeded = surface.map_gen_settings
    seeded.seed = seed
    local sample = game.create_surface('fulgora-seed-' .. seed, seeded)
    for _, pos in ipairs({{x=0,y=0}, {x=2048,y=1024}, {x=-4096,y=-2048}}) do
      sample.request_to_generate_chunks(pos, 4)
      sample.force_generate_chunk_requests()
      local area = {{pos.x-96,pos.y-96}, {pos.x+96,pos.y+96}}
      for _, tile in pairs(sample.find_tiles_filtered{area=area}) do
        tile_counts[tile.name] = (tile_counts[tile.name] or 0) + 1
      end
      local positions, names = {}, {}
      for _, decorative in pairs(sample.find_decoratives_filtered{area=area}) do
        local name = decorative.decorative.name
        decorative_counts[name] = (decorative_counts[name] or 0) + decorative.amount
        positions[#positions+1], names[#names+1] = decorative.position, name
      end
      for _, entity in pairs(sample.find_entities_filtered{area=area}) do
        check(entity.name == 'cliff-fulgora' or landmarks[entity.name],
          'unexpected generated entity: ' .. entity.name)
        if entity.name == 'cliff-fulgora' then
          cliff_count = cliff_count + 1
        else
          entity_counts[entity.name] = (entity_counts[entity.name] or 0) + 1
          positions[#positions+1], names[#names+1] = entity.position, entity.name
        end
      end
      local values = sample.calculate_tile_properties({'fulgora_oil_mask'}, positions)
      check(values.fulgora_oil_mask ~= nil, 'missing basin noise property')
      local region_basins = {}
      for i, mask in ipairs(values.fulgora_oil_mask) do
        if mask > 0 then
          local name = names[i]
          basin_counts[name] = (basin_counts[name] or 0) + 1
          region_basins[name] = true
        end
      end
      for name in pairs(allowed_decoratives) do
        check(region_basins[name], 'no basin ' .. name .. ' at seed ' .. seed ..
          ' position ' .. pos.x .. ',' .. pos.y)
      end
    end
  end
  for name, bounds in pairs(landmarks) do
    check((entity_counts[name] or 0) > 0, 'no generated ' .. name)
    check((basin_counts[name] or 0) > 0, 'no basin landmarks: ' .. name)
    local prototype = prototypes.entity[name]
    local products = prototype.mineable_properties.products
    check(#products == 1 and products[1].name == 'stone', name .. ' must yield only stone')
    check(products[1].amount_min == bounds[1] and products[1].amount_max == bounds[2],
      name .. ' stone bounds')
    check(#(prototype.loot or {}) == 0, name .. ' unexpected destruction loot')
    local inventory = game.create_inventory(10)
    local entity = surface.create_entity{name=name, position={0,0}, force='neutral'}
    check(entity and entity.mine{inventory=inventory}, name .. ' mining failed')
    local contents = inventory.get_contents()
    check(#contents == 1 and contents[1].name == 'stone', name .. ' actual mining product')
    check(contents[1].count >= bounds[1] and contents[1].count <= bounds[2],
      name .. ' actual mining amount')
    inventory.destroy()
  end
  for name in pairs(allowed_decoratives) do
    check((basin_counts[name] or 0) > 0, 'no basin decoratives: ' .. name)
  end
  local distinct = 0
  for name in pairs(tile_counts) do
    check(allowed_tiles[name], 'forbidden terrain: ' .. name)
    check(prototypes.tile[name].fluid == nil, 'fluid source on Fulgora: ' .. name)
    distinct = distinct + 1
  end
  check(distinct == 5, 'terrain fixture did not exercise all five natural tiles')
  check(cliff_count > 0, 'no cliffs generated')
  for name in pairs(decorative_counts) do check(allowed_decoratives[name], 'forbidden decorative: ' .. name) end
  check(next(decorative_counts) ~= nil, 'no natural rock decoratives generated')
  helpers.write_file('factorio-tests/fulgora-mapgen.json', helpers.table_to_json{
    schema=1, case='fulgora-mapgen', status='pass', failure_count=0,
    assertions=assertions, tick=game.tick, factorio_version=script.active_mods.base,
    observations={tiles=tile_counts, decoratives=decorative_counts, cliffs=cliff_count,
      landmarks=entity_counts, basin_objects=basin_counts},
  }, false)
end)

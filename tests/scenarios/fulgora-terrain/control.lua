-- given: production Fulgora, three fixed seeds; no factory supplies.
-- place: generated 512x512 regions at the landing and a distant site.
-- compare: native and replacement terrain without random landmark obstructions;
-- also survey the complete production terrain with landmarks enabled.
-- act: query real tile geometry and native building placement.
-- run: once at tick 1; graphical preview is optional after a player joins.
-- expect: native elevation and cliffs; oil footprints contain dry sediment.
util = require('util')
require('__nullius-star__/scripts/landfill')
require('__nullius-star__/scripts/drone')
local surface_config = require('__nullius-star__/scripts/surface_config')
local CASE = 'fulgora-terrain'
local BASIN = 'nullius-fulgora-sediment'
local function is_basin(name) return name:find(BASIN,1,true)==1 end
local basin_names = {}
local assertions = 0
local function check(value, message)
  assertions = assertions + 1
  assert(value, message)
end
local buildings = {'nullius-small-assembler-1', 'transport-belt',
  'pipe', 'wooden-chest', 'small-electric-pole'}
local function survey(surface, center, reference, geometry, baseline)
  local area = {{center.x-256,center.y-256},{center.x+256,center.y+256}}
  surface.request_to_generate_chunks(center, 9)
  surface.force_generate_chunk_requests()
  reference.request_to_generate_chunks(center,9)
  reference.force_generate_chunk_requests()
  geometry.request_to_generate_chunks(center,9)
  geometry.force_generate_chunk_requests()
  baseline.request_to_generate_chunks(center,9)
  baseline.force_generate_chunk_requests()
  local baseline_oil = 0
  for name in pairs(prototypes.tile) do
    if name:find("factorio-test-oil-ocean-",1,true)==1 then
      baseline_oil = baseline_oil + baseline.count_tiles_filtered{area=area,name=name}
    end
  end
  local basin_count = surface.count_tiles_filtered{area=area,name=basin_names}
  check(basin_count < baseline_oil, "larger island setting did not increase land area")
  local positions, firm, colors = {}, {}, {}
  for y=0,127 do
    for x=0,127 do
      local p = {x=center.x-253.5+x*4,y=center.y-253.5+y*4}
      local tile = surface.get_tile(p)
      local i = #positions+1
      positions[i], firm[i] = p, not is_basin(tile.name)
      colors[i] = tile.prototype.map_color
    end
  end
  local props = surface.calculate_tile_properties(
    {'elevation','fulgora_elevation','cliffiness','fulgora_cliffiness'},positions)
  for i in ipairs(positions) do
    check(props.elevation[i]==props.fulgora_elevation[i], 'native elevation changed')
    check(props.cliffiness[i]==props.fulgora_cliffiness[i], 'native cliffiness changed')
    local native_tile = reference.get_tile(positions[i]).name
    local native_oil = native_tile:find('factorio-test-oil-ocean-',1,true) == 1
    check(firm[i] == not native_oil, 'sediment differs from generated native ocean at '..
      positions[i].x..','..positions[i].y..' native '..native_tile)

  end
  local cliffs = surface.count_entities_filtered{area=area,name='cliff-fulgora'}
  check(cliffs>20, 'missing native cliffs: '..cliffs)
  -- Compare the same cliff-generation inputs. Random fulgurite children can
  -- block or turn adjacent cliff segments, so both geometry fixtures omit them.
  local native_cliffs = reference.find_entities_filtered{area=area,name='cliff-fulgora'}
  check(geometry.count_entities_filtered{area=area,name='cliff-fulgora'}==#native_cliffs,
    'native cliff count changed')
  for _,cliff in ipairs(native_cliffs) do
    local other = geometry.find_entity('cliff-fulgora',cliff.position)
    check(other and other.cliff_orientation==cliff.cliff_orientation,
      'native cliff position or orientation changed')
  end
  -- Four-neighbor components expose disconnected factory sites, not just coverage.
  local seen, components = {}, {}
  for i=1,#firm do
    if firm[i] and not seen[i] then
      local queue, head = {i}, 1
      seen[i] = true
      while head <= #queue do
        local n = queue[head]
        head = head+1
        local x = (n-1)%128
        for _, offset in ipairs({-128,128,-1,1}) do
          local v = n+offset
          if v>=1 and v<=#firm and not (offset==-1 and x==0) and
              not (offset==1 and x==127) and firm[v] and not seen[v] then
            seen[v] = true
            queue[#queue+1] = v
          end
        end
      end
      components[#components+1] = #queue*16
    end
  end
  table.sort(components, function(a,b) return a>b end)
  local svg = {'<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">'}
  for i,c in ipairs(colors) do
    svg[#svg+1] = string.format('<rect x="%d" y="%d" width="8" height="8" fill="rgb(%d,%d,%d)"/>',
      ((i-1)%128)*8, math.floor((i-1)/128)*8, math.floor(c.r), math.floor(c.g), math.floor(c.b))
  end
  svg[#svg+1] = '</svg>'
  helpers.write_file('fulgora-preview/'..surface.name..'-'..center.x..'.svg', table.concat(svg), false)
  return {basin_fraction=basin_count/(512*512), baseline_basin_fraction=baseline_oil/(512*512),
    land_area_ratio=(512*512-basin_count)/(512*512-baseline_oil), cliffs=cliffs, unobstructed_cliffs=#native_cliffs,
    firm_components=components}, positions
end
script.on_nth_tick(1, function()
  if game.tick==0 then return end
  script.on_nth_tick(1,nil)
  if storage.terrain_checked then return end
  for name in pairs(prototypes.tile) do if is_basin(name) then basin_names[#basin_names+1]=name end end
  local planet = game.planets['nullius-fulgora'].create_surface()
  local stale = planet.map_gen_settings
  local seed = stale.seed
  stale.property_expression_names.elevation = 'vulcanus_elevation'
  stale.property_expression_names['tile:fulgoran-rock:probability'] = 'fulgora_rock'
  stale.cliff_settings.cliff_elevation_0 = 1000
  stale.autoplace_controls.fulgora_islands.size = 1
  planet.map_gen_settings = stale
  surface_config.configure(planet)
  local refreshed = planet.map_gen_settings
  check(refreshed.seed==seed, 'configuration changed the surface seed')
  check(refreshed.property_expression_names.elevation=='fulgora_elevation', 'stale terrain expression retained')
  check(refreshed.property_expression_names['tile:fulgoran-rock:probability']==nil, 'stale tile expression retained')
  check(refreshed.cliff_settings.cliff_elevation_0==80, 'stale cliff settings retained')
  check(refreshed.autoplace_controls.fulgora_islands.size==2, "stale island size retained")
  local observations = {}
  for _,seed in ipairs({0,1,8675309}) do
    local settings = planet.map_gen_settings
    settings.seed = seed
    local surface = game.create_surface('fulgora-terrain-'..seed,settings)
    surface.always_day = true
    local reference_settings = util.table.deepcopy(prototypes.mod_data['factorio-test-fulgora-reference'].data)
    reference_settings.seed = seed
    local baseline = game.create_surface('fulgora-baseline-'..seed,reference_settings)
    reference_settings.autoplace_controls.fulgora_islands.size = 2
    local reference = game.create_surface('fulgora-reference-'..seed,reference_settings)
    local geometry_settings = surface.map_gen_settings
    geometry_settings.autoplace_settings.entity.settings = {}
    geometry_settings.autoplace_settings.decorative.settings = {}
    local geometry = game.create_surface('fulgora-geometry-'..seed,geometry_settings)
    local origin = survey(surface,{x=0,y=0},reference,geometry,baseline)
    local distant, positions = survey(surface,{x=2048,y=1024},reference,geometry,baseline)
    check(distant.basin_fraction>0 and distant.basin_fraction<1, 'missing land or sediment')
    for _,name in ipairs(buildings) do
      local placement = surface.find_non_colliding_position(name,{0,0},64,1)
      check(placement~=nil, 'no native landing space for '..name)
    end
    local witness
    for _,p in ipairs(positions) do
      if is_basin(surface.get_tile(p).name) and surface.can_place_entity{
          name='character',position=p,force='player'} then
        local blocked = true
        for _,name in ipairs(buildings) do
          if surface.can_place_entity{name=name,position=p,force='player'} then blocked=false end
        end
        if blocked then witness=p; break end
      end
    end
    check(witness~=nil, 'no walkable basin blocking all building types')
    -- Native tile-placement masks: every available landfill/paving item must collide.
    local layers = prototypes.tile[BASIN].collision_mask.layers
    local paving = 0
    for name,item in pairs(prototypes.item) do
      if item.place_as_tile_result then
        local placement = item.place_as_tile_result
        local mask = placement.condition.layers
        local blocked = false
        for layer in pairs(mask) do if layers[layer] then blocked=true end end
        if placement.invert then blocked = not blocked end
        if #placement.tile_condition > 0 then
          local allowed = false
          for _,tile in pairs(placement.tile_condition) do if tile.name==BASIN then allowed=true end end
          blocked = blocked or not allowed
        end
        check(blocked, 'tile item bypasses sediment: '..name)
        paving = paving+1
      end
    end
    check(paving>=5, 'landfill and paving contracts not exercised')
    observations[#observations+1] = {seed=seed,origin=origin,distant=distant,basin_witness=witness}
  end
  -- Exercise production drone handlers on generated terrain, not a tile mock.
  local surface = game.surfaces['fulgora-terrain-1']
  local center = observations[2].basin_witness
  local area = area_bound(center,192)
  local before = surface.find_tiles_filtered{area=area,name=basin_names}
  local event = {surface_index=surface.index,target_position=center}
  paving_effect(event,'refined-concrete','landfill')
  check(surface.count_tiles_filtered{area=area,name='refined-concrete'}>0,
    'paving drone did not exercise firm ground')
  landfill_area(surface,center,'landfill')
  excavate_area(surface,center,false)
  for _,tile in pairs(before) do
    check(is_basin(surface.get_tile(tile.position).name),'drone changed unstable sediment')
  end
  storage.terrain_checked = true
  helpers.write_file('factorio-tests/'..CASE..'.json', helpers.table_to_json{
    schema=1,case=CASE,status='pass',failure_count=0,assertions=assertions,tick=game.tick,
    factorio_version=script.active_mods.base,observations=observations},false)
end)
script.on_event(defines.events.on_player_created,function(event)
  local player = game.get_player(event.player_index)
  storage.preview_player = player.index
end)
script.on_nth_tick(60,function()
  if not storage.preview_player then return end
  local player = game.get_player(storage.preview_player)
  player.set_controller{type=defines.controllers.god}
  player.teleport({0,0},game.surfaces['fulgora-terrain-0'])
  player.zoom = 0.4
  for _,view in ipairs({{name='landing',position={0,0},zoom=0.2},
      {name='distant',position={2048,1024},zoom=0.2},
      {name='detail',position={100,0},zoom=0.8}}) do
    game.take_screenshot{player=player,surface=player.surface,position=view.position,
      resolution={1600,1000},zoom=view.zoom,path='fulgora-preview/'..view.name..'.png',
      show_gui=false,show_entity_info=false,daytime=0}
  end
  script.on_nth_tick(60,nil)
end)

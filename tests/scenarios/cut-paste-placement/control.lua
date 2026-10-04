-- given: empty land, three processing machines, hovering construction robot, blueprint inventory; no production inputs.
-- act: mark each machine for deconstruction, paste, remove it, and paste again.
-- expect: native blueprint placement at the original location on both planets.
script.on_nth_tick(1,function()
  if game.tick==0 then return end
  script.on_nth_tick(1,nil)
  local rows={};local assertions=0
  local function check(ok,message) assertions=assertions+1;assert(ok,message) end
  for _,kind in ipairs({'construction-robot','logistic-robot','combat-robot'}) do
    for name,prototype in pairs(prototypes.get_entity_filtered{{filter='type',type=kind}}) do
      check(not prototype.collision_mask.layers.nullius_fulgora_sand,
        'robot inherits building terrain mask: '..name)
    end
  end
  for _,surface in ipairs({game.surfaces.nauvis,game.planets['nullius-fulgora'].create_surface()}) do
    surface.request_to_generate_chunks({0,0},3);surface.force_generate_chunk_requests()
    for _,e in pairs(surface.find_entities_filtered{area={{-40,-40},{80,40}}}) do e.destroy() end
    local tiles={}
    for x=-40,80 do for y=-40,40 do tiles[#tiles+1]={name='fulgoran-rock',position={x,y}} end end
    surface.set_tiles(tiles,true)
    for i,name in ipairs({'nullius-hydro-plant-1','nullius-small-furnace-1','nullius-distillery-1'}) do
      local pos={i*16,0}
      local entity=assert(surface.create_entity{name=name,position=pos,force='player',raise_built=true})
      local inv=game.create_inventory(1);inv[1].set_stack{name='blueprint'}
      inv[1].set_blueprint_entities{{entity_number=1,name=name,position={0,0}}}
      local row={surface=surface.name,name=name,position=entity.position}
      row.marked=entity.order_deconstruction('player')
      row.ghost_allowed=surface.can_place_entity{name=name,position=entity.position,force='player',build_check_type=defines.build_check_type.manual_ghost}
      local ghosts=inv[1].build_blueprint{surface=surface,force='player',position=entity.position,raise_built=true}
      row.paste_marked_count=#ghosts;row.still_marked=entity.to_be_deconstructed()
      check(row.ghost_allowed,'marked entity blocks ghost: '..name)
      check(#ghosts==1,'paste over marked entity failed: '..name)
      for _,g in pairs(ghosts) do if g.valid and g.type=='entity-ghost' then g.destroy() end end
      entity.destroy{raise_destroy=true}
      local robot=assert(surface.create_entity{name='nullius-construction-bot-1',position=row.position,force='player'})
      check(not robot.prototype.collision_mask.layers.nullius_fulgora_sand,'robot inherits building terrain mask')
      row.place_after=surface.can_place_entity{name=name,position=pos,force='player'}
      ghosts=inv[1].build_blueprint{surface=surface,force='player',position=pos,raise_built=true}
      row.paste_removed_count=#ghosts
      check(row.place_after,'removed entity blocks placement: '..name)
      check(#ghosts==1,'paste after removal failed: '..name)
      row.nearby={}
      for _,e in pairs(surface.find_entities_filtered{position=pos,radius=5}) do
        row.nearby[#row.nearby+1]={name=e.name,type=e.type,position=e.position}
      end
      for _,g in pairs(ghosts) do if g.valid and g.type=='entity-ghost' then g.destroy() end end
      robot.destroy()
      inv.destroy();rows[#rows+1]=row
    end
  end
  helpers.write_file('factorio-tests/cut-paste-placement.json',helpers.table_to_json{
    schema=1,case='cut-paste-placement',status='pass',failure_count=0,assertions=assertions,
    observations=rows,tick=game.tick,factorio_version=script.active_mods.base},false)
end)

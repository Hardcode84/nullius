return function(exercise, ticks)
  local function nearby(surface,pos)
    local rows={}
    for _,e in pairs(surface.find_entities_filtered{position=pos,radius=6}) do
      rows[#rows+1]={name=e.name,position=e.position,type=e.type,unit=e.unit_number,
        collision_mask=e.prototype.collision_mask}
    end
    return rows
  end
  local function check(row)
    return row.surface.can_place_entity{name=row.name,position=row.position,direction=row.direction,
      force=row.force,build_check_type=defines.build_check_type.manual_ghost}
  end
  script.on_nth_tick(1,function()
    if not storage.started then
      storage.started=game.tick;storage.rows={};storage.report={players={},buildings={}}
      for _,p in pairs(game.players) do
        storage.report.players[#storage.report.players+1]={name=p.name,position=p.position,surface=p.surface.name}
      end
      for _,surface in pairs(game.surfaces) do
        for _,e in pairs(surface.find_entities_filtered{type='assembling-machine'}) do
          if e.name:find('nullius-hydro-plant',1,true)==1 then
            local row={entity=e,name=e.name,position=e.position,direction=e.direction,force=e.force,surface=surface}
            local report={name=e.name,position=e.position,surface=surface.name,unit=e.unit_number,
              marked=e.to_be_deconstructed(),nearby=nearby(surface,e.position)}
            row.report=report;storage.rows[#storage.rows+1]=row;storage.report.buildings[#storage.report.buildings+1]=report
            if exercise then
              report.ordered=e.order_deconstruction(e.force)
              report.marked_can_place=check(row)
              local inv=game.create_inventory(1);inv[1].set_stack{name='blueprint'}
              inv[1].set_blueprint_entities{{entity_number=1,name=e.name,position={0,0},direction=e.direction}}
              report.pasted=#inv[1].build_blueprint{surface=surface,force=e.force,position=e.position,raise_built=true}
              inv.destroy()
            end
          end
        end
      end
    end
    if game.tick-storage.started==ticks-1 then
      for _,row in ipairs(storage.rows) do
        row.report.removed=not row.entity.valid
        row.report.rebuilt=row.surface.find_entity(row.name,row.position)~=nil
        row.report.final_can_place=check(row)
        row.report.final_nearby=nearby(row.surface,row.position)
      end
      helpers.write_file('placement-probe.json',helpers.table_to_json(storage.report),false)
      script.on_nth_tick(1,nil)
    end
  end)
end

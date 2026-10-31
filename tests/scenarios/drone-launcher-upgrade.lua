-- given: old 3/5-slot launchers, ten drones in every slot, five drone types.
-- act: save, then load with the one-slot production prototypes.
-- expect: every drone remains in an inventory or is returned to the ground.
local resumed=false
script.on_load(function() resumed=true end)
script.on_init(function() storage.prepared=false end)
script.on_nth_tick(30,function()
  if game.tick==0 then return end
  if not storage.prepared then
    local s=game.surfaces.nauvis
    s.request_to_generate_chunks({0,0},1);s.force_generate_chunk_requests()
    for _,e in pairs(s.find_entities_filtered{area={{-20,-20},{20,20}}}) do e.destroy() end
    local names={'nullius-scout-drone-1','nullius-scout-drone-2','nullius-demolition-drone',
      'nullius-excavation-drone','nullius-shallow-excavation-drone'}
    storage.rows={};storage.expected={}
    for tier=1,2 do
      local e=assert(s.create_entity{name='nullius-drone-launcher-'..tier,position={tier*6,0},force='player'})
      local inv=e.get_inventory(defines.inventory.artillery_turret_ammo)
      assert(#inv==(tier==1 and 3 or 5),'legacy launcher fixture has wrong slot count')
      for i=1,#inv do
        inv[i].set_stack{name=names[i],count=10}
        storage.expected[names[i]]=(storage.expected[names[i]] or 0)+10
      end
      storage.rows[tier]=e
    end
    storage.prepared=true;game.server_save('launcher-slots')
  elseif resumed then
    local actual={}
    for _,e in ipairs(storage.rows) do
      for _,stack in pairs(e.get_inventory(defines.inventory.artillery_turret_ammo).get_contents()) do
        actual[stack.name]=(actual[stack.name] or 0)+stack.count
      end
    end
    for _,e in pairs(game.surfaces.nauvis.find_entities_filtered{type='item-entity'}) do
      local stack=e.stack;actual[stack.name]=(actual[stack.name] or 0)+stack.count
    end
    for name,count in pairs(storage.expected) do
      assert(actual[name]==count,'launcher upgrade lost '..name..': expected '..count..', got '..(actual[name] or 0))
    end
    log('LAUNCHER_UPGRADE_PASS: all 80 drones preserved')
    script.on_nth_tick(30,nil)
  end
end)

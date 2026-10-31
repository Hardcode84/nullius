-- given: old 3/5-slot launchers, ten drones in every slot, five drone types.
-- act: save, then load with the one-slot production prototypes.
-- expect: the first slot survives; drones in removed slots are lost (accepted save break).
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
      local inventory=e.get_inventory(defines.inventory.artillery_turret_ammo)
      assert(#inventory==1,'upgraded launcher must have one slot')
      assert(inventory.get_item_count('nullius-scout-drone-1')==10,'first slot must survive')
      for _,stack in pairs(inventory.get_contents()) do
        actual[stack.name]=(actual[stack.name] or 0)+stack.count
      end
    end
    for _,e in pairs(game.surfaces.nauvis.find_entities_filtered{type='item-entity'}) do
      local stack=e.stack;actual[stack.name]=(actual[stack.name] or 0)+stack.count
    end
    for name in pairs(storage.expected) do
      local expected=name=='nullius-scout-drone-1' and 20 or 0
      assert((actual[name] or 0)==expected,'unexpected upgrade inventory for '..name)
    end
    log('LAUNCHER_UPGRADE_PASS: 20 drones retained; 60 removed-slot drones lost')
    script.on_nth_tick(30,nil)
  end
end)

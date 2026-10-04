-- given: production map settings, three seeds, two 1024-square windows per seed.
-- place: native terrain only; no tiles, resources, or factory supplies are injected.
-- act/run: export tile-resolution land masks and cliff bounds once at tick 1.
-- expect: both land and sediment; masks cover the complete declared windows.
local CASE='fulgora-island-survey'
script.on_nth_tick(1,function()
  if game.tick==0 then return end
  script.on_nth_tick(1,nil)
  local settings=game.planets['nullius-fulgora'].create_surface().map_gen_settings
  local rows={};local assertions=0
  for _,seed in ipairs({0,42,1729}) do
    settings.seed=seed
    local s=game.create_surface(CASE..'-'..seed,settings)
    for _,center in ipairs({{0,0},{4096,0}}) do
      s.request_to_generate_chunks(center,17);s.force_generate_chunk_requests()
      local x0,y0=center[1]-512,center[2]-512
      local area={{x0,y0},{x0+1024,y0+1024}}
      local row={seed=seed,center=center,size=1024,land_rows={},tiles={},cliffs={}}
      local land=0
      for y=0,1023 do
        local spans={};local start=nil
        for x=0,1023 do
          local name=s.get_tile(x0+x,y0+y).name
          row.tiles[name]=(row.tiles[name] or 0)+1
          local firm=not name:find('nullius-fulgora-sediment',1,true)
          if firm then land=land+1;if not start then start=x end
          elseif start then spans[#spans+1]={start,x};start=nil end
        end
        if start then spans[#spans+1]={start,1024} end
        row.land_rows[y+1]=spans
      end
      for _,e in pairs(s.find_entities_filtered{area=area,type='cliff'}) do
        local b=e.bounding_box
        row.cliffs[#row.cliffs+1]={b.left_top.x-x0,b.left_top.y-y0,b.right_bottom.x-x0,b.right_bottom.y-y0}
      end
      row.vents=s.count_entities_filtered{area=area,name='nullius-hydrocarbon-vent'}
      if center[1]==0 then
        local p=assert(s.find_non_colliding_position('nullius-landing-main',{0,0},64,1),'no probe landing')
        row.landing={p.x-x0,p.y-y0}
      end
      assert(land>0 and land<1024*1024,'missing land or sediment');assertions=assertions+1
      rows[#rows+1]=row
    end
    game.delete_surface(s)
  end
  helpers.write_file('factorio-tests/'..CASE..'.json',helpers.table_to_json{
    schema=1,case=CASE,status='pass',failure_count=0,assertions=assertions,tick=game.tick,
    factorio_version=script.active_mods.base,observations=rows},false)
end)

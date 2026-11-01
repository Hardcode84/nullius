-- given: one finite recipe batch per new bulk route, and debug electric power.
-- place/connect: three flotation cells and a foundry on cleared Nauvis ground.
-- act: research the ordinary and bulk unlocks, then supply the declared batch.
-- run: feed finite fluid stock every 30 ticks, check at tick 6000.
-- expect: all eight bulk unlocks are exclusive, and new routes preserve material ratios.
local CASE='fulgora-bulk-reclamation'
local processes={'limestone-recovery','stone-recovery','iron-recovery','bauxite-recovery',
  'sand-recovery','gypsum-recovery','borate-leaching','barrel-recycling'}
local tested={'iron-recovery','bauxite-recovery','sand-recovery','barrel-recycling'}
local function check(ok,message)
  storage.assertions=storage.assertions+1; assert(ok,message)
end
local function gcd(a,b) while b~=0 do a,b=b,a%b end return a end
script.on_nth_tick(30,function()
  if game.tick==0 then return end
  if not storage.rows then
    storage.assertions=0;storage.rows={}
    local force=game.create_force(CASE)
    force.technologies['nullius-waste-reclamation'].researched=true
    local tech=force.technologies['nullius-bulk-waste-reclamation']
    for _,prerequisite in ipairs({'nullius-waste-reclamation','nullius-overcharged-assembly-2','nullius-packaging-4'}) do
      check(tech.prerequisites[prerequisite]~=nil,'missing bulk prerequisite '..prerequisite)
    end
    local em=false
    for _,pack in pairs(tech.research_unit_ingredients) do if pack.name=='nullius-electromagnetic-pack' then em=true end end
    check(em,'bulk research must require EM science')
    for _,process in ipairs(processes) do
      local ordinary=process=='stone-recovery' and 'stone' or 'nullius-'..process
      local boxed='nullius-boxed-'..process
      check(force.recipes[ordinary].enabled,'ordinary recipe locked '..ordinary)
      check(not force.recipes[boxed].enabled,'bulk recipe unlocked early '..boxed)
      local owners=0
      for _,technology in pairs(prototypes.technology) do
        for _,effect in pairs(technology.effects or {}) do
          if effect.type=='unlock-recipe' and effect.recipe==boxed then
            owners=owners+1
            check(technology.name==tech.name,'wrong unlock owner '..boxed)
          end
        end
      end
      check(owners==1,'bulk recipe must have exactly one unlock '..boxed)
    end
    local visited={}
    local function research(technology)
      if visited[technology.name] then return end
      visited[technology.name]=true
      for _,prerequisite in pairs(technology.prerequisites) do research(prerequisite) end
      for _,pack in pairs(technology.research_unit_ingredients) do
        check(pack.name~='nullius-physics-pack','bulk reclamation requires physics science')
      end
      technology.researched=true
    end
    research(tech)
    for _,process in ipairs(processes) do check(force.recipes['nullius-boxed-'..process].enabled,'missing bulk unlock') end
    for _,product in ipairs({'crushed-limestone','crushed-bauxite','crushed-iron-ore',
        'sand','stone','gypsum','acid-boric','iron-ingot','plastic','barrel','cement','soda-ash'}) do
      check(force.recipes['nullius-box-'..product].enabled,'missing packaging prerequisite '..product)
      check(force.recipes['nullius-unbox-'..product].enabled,'missing unpacking prerequisite '..product)
    end
    local surface=game.surfaces.nauvis
    surface.request_to_generate_chunks({0,0},3);surface.force_generate_chunk_requests()
    for _,entity in pairs(surface.find_entities_filtered{area={{-12,-12},{90,12}}}) do entity.destroy() end
    local tiles={};for x=-12,90 do for y=-12,12 do tiles[#tiles+1]={name='landfill',position={x,y}} end end
    surface.set_tiles(tiles,true)
    for i,process in ipairs(tested) do
      local name='nullius-boxed-'..process
      local base=prototypes.recipe['nullius-'..process]
      local recipe=prototypes.recipe[name]
      local scale=recipe.energy/base.energy
      local divisor=0
      for _,field in ipairs({'ingredients','products'}) do
        check(#recipe[field]==#base[field],'part count '..name)
        for _,part in pairs(base[field]) do
          local target=part.type=='fluid' and part.name or 'nullius-box-'..part.name:gsub('^nullius%-','')
          local found
          for _,candidate in pairs(recipe[field]) do if candidate.name==target then found=candidate end end
          check(found~=nil,'missing bulk material '..target)
          check(found.amount*(part.type=='fluid' and 1 or 5)==part.amount*scale,'bulk material/time parity '..target)
          divisor=gcd(divisor,found.amount)
        end
      end
      check(divisor==1,'bulk recipe not reduced '..name)
      check(recipe.allowed_effects.productivity==base.allowed_effects.productivity,'productivity parity '..name)
      check(not recipe.surface_conditions or #recipe.surface_conditions==0,'planet restricted '..name)
      local x=(i-1)*24
      local machine=assert(surface.create_entity{name=process=='barrel-recycling' and 'nullius-foundry-1' or 'nullius-flotation-cell-1',position={x,0},force=force})
      machine.set_recipe(name);check(machine.get_recipe().name==name,'machine rejects '..name)
      local grid=assert(surface.create_entity{name='factorio-test-planner-grid',position={x+7,0},force=force})
      grid.power_production=10000000;grid.electric_buffer_size=10000000
      surface.create_entity{name='substation',position={x+5,4},force=force}
      local row={machine=machine,recipe=name,feeds={}}
      for _,part in pairs(recipe.ingredients) do
        if part.type=='item' then check(machine.insert{name=part.name,count=part.amount}==part.amount,'finite item stock')
        else row.feeds[#row.feeds+1]={name=part.name,left=part.amount} end
      end
      storage.rows[#storage.rows+1]=row
    end
  end
  for _,row in ipairs(storage.rows) do
    for _,feed in ipairs(row.feeds) do
      if feed.left>0 then feed.left=feed.left-row.machine.insert_fluid{name=feed.name,amount=feed.left} end
    end
  end
  if game.tick==6000 then
    for _,row in ipairs(storage.rows) do
      check(row.machine.products_finished==1,'finite batch '..row.recipe)
      for _,part in pairs(prototypes.recipe[row.recipe].products) do
        local actual=part.type=='fluid' and row.machine.get_fluid_count(part.name) or row.machine.get_item_count(part.name)
        check(math.abs(actual-part.amount)<0.001,'output '..part.name)
      end
      for _,feed in ipairs(row.feeds) do check(feed.left==0,'unfed reagent '..feed.name) end
    end
    helpers.write_file('factorio-tests/'..CASE..'.json',helpers.table_to_json{
      schema=1,case=CASE,status='pass',failure_count=0,assertions=storage.assertions,
      tick=game.tick,factorio_version=script.active_mods.base},false)
    script.on_nth_tick(30,nil)
  end
end)

-- given: one finite recipe batch per cell and declared debug electricity.
-- place: independent production machines on Fulgora and Nauvis.
-- act: unlock organic recipes through their technologies and run one batch.
-- expect: ordinary and boxed quantities agree, and every recipe produces its item.
local specs=require('__nullius-star__/shared/fulgora-organics')
local assertions=0
local function check(value,message) assertions=assertions+1; assert(value,message) end
local rows={}
script.on_nth_tick(1,function()
  if game.tick==0 then return end
  script.on_nth_tick(1,nil)
  for _,planet_name in ipairs({'nullius-fulgora','nauvis'}) do
    local force=game.create_force('organic-recipes-'..planet_name)
    local planet=game.planets[planet_name]
    local surface=planet.surface or planet.create_surface()
    surface.request_to_generate_chunks({80,0},5);surface.force_generate_chunk_requests()
    for _,e in pairs(surface.find_entities_filtered{area={{-10,-10},{170,40}}}) do e.destroy() end
    local tiles={}
    for x=-10,170 do for y=-10,40 do tiles[#tiles+1]={name='fulgoran-rock',position={x,y}} end end
    surface.set_tiles(tiles)
    local unbox={}
    for name,recipe in pairs(prototypes.recipe) do
      if name:match('^nullius%-unbox%-') and #recipe.ingredients==1 and #recipe.products==1 then
        unbox[recipe.ingredients[1].name]={name=recipe.products[1].name,
          ratio=recipe.products[1].amount/recipe.ingredients[1].amount}
      end
      local recycling=false
      for _,category in pairs(recipe.categories) do
        recycling=recycling or category=='recycling' or category=='recycling-or-hand-crafting'
      end
      if recycling then
        for _,product in pairs(recipe.products) do
          check(product.probability==0 or product.name=='nullius-gas-void','recycling output '..name)
        end
      end
    end
    local function amounts(entries)
      local result={}
      for _,entry in pairs(entries) do
        local box=unbox[entry.name]
        local name=box and box.name or entry.name
        result[name]=(result[name] or 0)+entry.amount*(box and box.ratio or 1)
      end
      return result
    end
    local bulk_tech=prototypes.technology['nullius-bulk-polymer-processing']
    check(bulk_tech.prerequisites['nullius-mass-production-4']~=nil,'bulk requires mass production')
    check(bulk_tech.prerequisites['nullius-improved-polymer-doping']~=nil,'bulk requires doping')
    check(bulk_tech.prerequisites['nullius-fiber-reinforced-polymers']~=nil,'bulk requires reinforced polymers')
    local fiber=force.technologies['nullius-fiber-reinforced-polymers']
    check(fiber.prerequisites['nullius-weaving-2']~=nil,'fiber research requires weaving')
    check(fiber.prerequisites['nullius-primitive-filtration']~=nil,'fiber research requires Fulgora access')
    local em=false
    for _,pack in pairs(fiber.research_unit_ingredients) do
      if pack.name=='nullius-electromagnetic-pack' then em=true end
    end
    check(em,'fiber research requires EM science')
    force.technologies['nullius-weaving-2'].researched=true
    for _,name in ipairs({'nullius-reinforced-polymer-gear','nullius-fiber-cable'}) do
      check(not force.recipes[name].enabled,'weaving unlocked Fulgora substitute '..name)
    end
    fiber.researched=true
    for _,name in ipairs({'nullius-reinforced-polymer-gear','nullius-fiber-cable'}) do
      check(force.recipes[name].enabled,'fiber research missing unlock '..name)
      check(not force.recipes[name:gsub('^nullius%-','nullius-boxed-')].enabled,'fiber research unlocked bulk '..name)
    end
    force.technologies['nullius-mass-production-4'].researched=true
    for i,spec in ipairs(specs) do
      check(not force.recipes[spec.name:gsub('^nullius%-','nullius-boxed-')].enabled,'mass production bypass '..spec.name)
    end
    for i,spec in ipairs(specs) do
      local ordinary=prototypes.recipe[spec.name]
      local bulk=prototypes.recipe[spec.name:gsub('^nullius%-','nullius-boxed-')]
      for _,field in ipairs({'ingredients','products'}) do
        local normal,boxed=amounts(ordinary[field]),amounts(bulk[field])
        for name,n in pairs(normal) do check(math.abs(boxed[name]/bulk.energy-n/ordinary.energy)<0.000001,'boxed parity '..spec.name..' '..name) end
        for name in pairs(boxed) do check(normal[name]~=nil,'extra boxed material '..name) end
      end
      for _,boxed in ipairs({false,true}) do
        local name=boxed and spec.name:gsub('^nullius%-','nullius-boxed-') or spec.name
        local tech=boxed and 'nullius-bulk-polymer-processing' or spec.technology
        force.technologies[tech].researched=false
        check(not force.recipes[name].enabled,'early unlock '..name)
        force.technologies[tech].researched=true
        check(force.recipes[name].enabled,'missing unlock '..name)
        local recipe=prototypes.recipe[name]
        if not boxed then check(recipe.energy==spec.seconds,'craft time '..name) end
        if boxed then
          check(recipe.subgroup.name:match('^boxed%-')~=nil,'bulk subgroup '..name)
          local divisor=0
          for _,entries in ipairs({recipe.ingredients,recipe.products}) do
            for _,entry in pairs(entries) do
              check(entry.amount%1==0,'integer batch '..name)
              local b=entry.amount
              while b~=0 do divisor,b=b,divisor%b end
            end
          end
          check(divisor==1,'batch not reduced '..name)
        end
        check(recipe.surface_conditions==nil,'unexpected planet gate '..name)
        local machine_name=spec.category=='machine-casting' and 'nullius-foundry-1' or
          spec.category=='basic-chemistry' and 'nullius-chemical-plant-2' or
          spec.category=='small-crafting' and (boxed and 'nullius-large-assembler-1' or 'nullius-small-assembler-1') or 'nullius-large-assembler-1'
        local x,y=i*20,boxed and 22 or 0
        local machine=assert(surface.create_entity{name=machine_name,position={x,y},force=force})
        machine.set_recipe(name)
        check(machine.get_recipe() and machine.get_recipe().name==name,'machine recipe '..name)
        for _,input in pairs(recipe.ingredients) do
          if input.type=='fluid' then
            check(machine.insert_fluid{name=input.name,amount=input.amount}==input.amount,'fluid stock '..name)
          else
            check(machine.insert{name=input.name,count=input.amount}==input.amount,'item stock '..name)
          end
        end
        local power=assert(surface.create_entity{name='factorio-test-planner-grid',position={x+6,y+5},force=force})
        power.power_production=1000000000;power.electric_buffer_size=1000000000
        surface.create_entity{name='substation',position={x+6,y},force=force}
        rows[#rows+1]={machine=machine,recipe=recipe}
      end
    end
    local substitute={}
    for _,spec in ipairs(specs) do
      substitute[spec.name]=true
      substitute[spec.name:gsub('^nullius%-','nullius-boxed-')]=true
    end
    for _,name in ipairs({'crushing','smelting','casting','hydrocarbon','polymerization','fiber'}) do
      for _,effect in pairs(prototypes.technology['nullius-'..name..'-productivity-1'].effects) do
        check(not substitute[effect.recipe],'substitute received research productivity')
      end
    end
    for _,name in ipairs({'hydrocarbon','polymerization','fiber'}) do
      local tech=prototypes.technology['nullius-'..name..'-productivity-1']
      check(#tech.effects>0,'empty productivity family '..name)
      local seen={}
      for _,effect in pairs(tech.effects) do
        check(effect.type=='change-recipe-productivity' and effect.change==0.01,'productivity effect')
        check(not seen[effect.recipe],'duplicate productivity effect');seen[effect.recipe]=true
        local recipe=prototypes.recipe[effect.recipe]
        check(recipe.maximum_productivity~=0,'forbidden productivity '..effect.recipe)
        check(not effect.recipe:match('^nullius%-unbox%-') and not effect.recipe:match('recycling$'),'recovery productivity')
      end
      force.technologies[tech.name].researched=true
    end
  end
end)
script.on_nth_tick(18000,function()
  if game.tick==0 then return end
  for _,row in ipairs(rows) do
    check(row.machine.products_finished==1,'craft count '..row.recipe.name..' crafts='..row.machine.products_finished..' status='..row.machine.status)
    for _,product in pairs(row.recipe.products) do
      check(row.machine.get_output_inventory().get_item_count(product.name)>=product.amount,'output '..row.recipe.name)
    end
  end
  helpers.write_file('factorio-tests/fulgora-organic-recipes.json',helpers.table_to_json{
    schema=1,case='fulgora-organic-recipes',status='pass',failure_count=0,
    assertions=assertions,tick=game.tick,factorio_version=script.active_mods.base},false)
  script.on_nth_tick(18000,nil)
end)

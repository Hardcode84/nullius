-- given: a fresh force with no research or supplied items.
-- act: research the prerequisite closure, then Waste Reclamation.
-- expect: only early science; all six recipes, including stone, unlock together.
local count=0
local function check(v,m) count=count+1; assert(v,m) end
script.on_nth_tick(1,function()
  if game.tick==0 then return end
  script.on_nth_tick(1,nil)
  local force=game.create_force('reclamation-test')
  local tech=force.technologies['nullius-waste-reclamation']
  local packs={['nullius-geology-pack']=true,['nullius-climatology-pack']=true,
    ['nullius-mechanical-pack']=true,['nullius-electrical-pack']=true,
    ['nullius-checkpoint']=true,['nullius-requirement-build']=true,
    ['nullius-requirement-consume']=true} -- Scripted production checkpoints use this hidden token.
  local seen={}
  local function research(t)
    if seen[t.name] then return end
    seen[t.name]=true
    for _,p in pairs(t.prerequisites) do research(p) end
    for _,i in pairs(t.research_unit_ingredients) do
      check(packs[i.name], 'late science required by '..t.name..': '..i.name)
    end
    t.researched=true
  end
  for _,p in pairs(tech.prerequisites) do research(p) end
  for _,name in ipairs({'nullius-flotation-1','nullius-concrete-1',
      'nullius-nitrogen-chemistry-1','nullius-sulfur-processing-1','nullius-inorganic-chemistry-2'}) do
    check(seen[name], 'missing ingredient or machine technology '..name)
  end
  local recipes={'nullius-limestone-recovery','nullius-iron-recovery',
    'nullius-bauxite-recovery','nullius-sand-recovery','stone','nullius-barrel-recycling'}
  for _,name in ipairs(recipes) do check(not force.recipes[name].enabled,'premature unlock '..name) end
  research(tech)
  check(#tech.prototype.effects==6,'recovery effects changed')
  for _,name in ipairs(recipes) do check(force.recipes[name].enabled,'missing unlock '..name) end
  helpers.write_file('factorio-tests/waste-reclamation-access.json',helpers.table_to_json{
    schema=1,case='waste-reclamation-access',status='pass',failure_count=0,
    assertions=count,tick=game.tick,factorio_version=script.active_mods.base},false)
end)

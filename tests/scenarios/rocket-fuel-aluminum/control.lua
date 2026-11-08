-- given: burnt alumina, with non-aluminum reagents and energy supplied.
-- act: recover ingots by basic smelting, carbide recovery, and electrolysis;
-- then make rods, wire, and powder, without productivity.
-- expect: each tested recovery route returns less powder than either fuel consumes.
local CASE='rocket-fuel-aluminum'
local assertions=0
local function check(ok,message)
  assertions=assertions+1
  assert(ok,message)
end
local function amount(parts,name)
  for _,part in pairs(parts) do
    if part.name==name then
      check(part.amount and (part.probability==nil or part.probability==1),'exact amount '..name)
      return part.amount
    end
  end
  error('Missing material '..name)
end
local function input(recipe,name) return amount(prototypes.recipe[recipe].ingredients,name) end
local function output(recipe,name) return amount(prototypes.recipe[recipe].products,name) end
script.on_init(function()
  local finishing=output('nullius-aluminum-rod-2','nullius-aluminum-rod')/input('nullius-aluminum-rod-2','nullius-aluminum-ingot')
    *output('nullius-aluminum-wire-2','nullius-aluminum-wire')/input('nullius-aluminum-wire-2','nullius-aluminum-rod')
    *output('nullius-aluminum-powder','nullius-aluminum-powder')/input('nullius-aluminum-powder','nullius-aluminum-wire')
  local carbide_batches=output('nullius-aluminum-ingot-3','nullius-aluminum-carbide')/input('nullius-aluminum-ingot-2','nullius-aluminum-carbide')
  local basic_carbide_batches=output('nullius-aluminum-ingot','nullius-aluminum-carbide')/input('nullius-aluminum-ingot-2','nullius-aluminum-carbide')
  local recovery={
    basic=finishing*output('nullius-aluminum-ingot','nullius-aluminum-ingot')/input('nullius-aluminum-ingot','nullius-alumina'),
    basic_with_carbide=finishing*(output('nullius-aluminum-ingot','nullius-aluminum-ingot')+basic_carbide_batches*output('nullius-aluminum-ingot-2','nullius-aluminum-ingot'))
      /(input('nullius-aluminum-ingot','nullius-alumina')+basic_carbide_batches*input('nullius-aluminum-ingot-2','nullius-alumina')),
    carbide=finishing*(output('nullius-aluminum-ingot-3','nullius-aluminum-ingot')+carbide_batches*output('nullius-aluminum-ingot-2','nullius-aluminum-ingot'))
      /(input('nullius-aluminum-ingot-3','nullius-alumina')+carbide_batches*input('nullius-aluminum-ingot-2','nullius-alumina')),
    electrolytic=finishing*output('nullius-aluminum-ingot-electrolytic','nullius-box-aluminum-ingot')/input('nullius-aluminum-ingot-electrolytic','nullius-box-alumina'),
  }
  check(prototypes.item['rocket-fuel'].burnt_result.name=='nullius-alumina','fuel returns alumina')
  for family,expected in pairs{rp1=5,["aluminum-co2"]=60} do
    for _,boxed in ipairs{false,true} do
      local recipe='nullius-'..(boxed and 'boxed-' or '')..family..'-rocket-fuel'
      local powder=boxed and 'nullius-box-aluminum-powder' or 'nullius-aluminum-powder'
      local fuel=boxed and 'nullius-box-rocket-fuel' or 'rocket-fuel'
      local consumed=input(recipe,powder)/output(recipe,fuel)
      check(consumed==expected,'powder per fuel '..recipe)
      check(prototypes.recipe[recipe].maximum_productivity==0,'fuel rejects all productivity '..recipe)
      for route,returned in pairs(recovery) do check(returned<consumed,'aluminum balance '..route..' '..recipe) end
    end
  end
  helpers.write_file('factorio-tests/'..CASE..'.json',helpers.table_to_json{
    schema=1,case=CASE,status='pass',failure_count=0,assertions=assertions,
    tick=game.tick,factorio_version=script.active_mods.base,
    observations={powder_per_alumina_without_productivity=recovery}},false)
end)

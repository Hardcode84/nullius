-- Cold data-stage path: native surface checks exclude atmosphere and ground users.
local buildable=require("prototypes.visible-build-items")()
local intakes={["air-filtration"]=true,["water-pumping"]=true,["seawater-pumping"]=true}
for kind in pairs(defines.prototypes.entity) do
  for name,entity in pairs(data.raw[kind] or {}) do
    if name:sub(1,8)=="nullius-" and buildable[name]~=nil then
      local ground=kind=="mining-drill" or kind=="offshore-pump" or
        (entity.energy_source and entity.energy_source.type=="fluid") or
        name:find("nullius-wind-",1,true)==1 or name:find("nullius-stirling-engine-",1,true)==1 or
        name:find("nullius-landing-",1,true)==1
      for _,category in pairs(entity.crafting_categories or {}) do ground=ground or intakes[category] end
      if ground then
        entity.surface_conditions=entity.surface_conditions or {}
        table.insert(entity.surface_conditions,{property="pressure",min=1})
      end
    end
  end
end

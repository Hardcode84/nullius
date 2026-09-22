-- Declared external dependencies for execution of the complete integration file.
local native = data
local fixture = {raw={recipe={},technology={},roboport={},pump={},item={},inserter={}},registered={}}
for _, name in ipairs({"miniloader","fast-miniloader","express-miniloader","ultimate-miniloader","nullius-traffic-control"}) do
  fixture.raw.technology[name]={icons={{icon="__base__/graphics/technology/automation.png",icon_size=256}},effects={}}
end
for _, name in ipairs({"aai-signal-sender","aai-signal-receiver"}) do
  fixture.raw.roboport[name]=table.deepcopy(native.raw.roboport.roboport)
end
for _, name in ipairs({"nullius-pump-1","nullius-pump-2"}) do
  fixture.raw.pump[name]=table.deepcopy(native.raw.pump.pump)
end
fixture.raw.item["stack-inserter"]=table.deepcopy(native.raw.item["stack-inserter"])
fixture.raw.inserter["stack-inserter"]=table.deepcopy(native.raw.inserter["stack-inserter"])
function fixture:extend(prototypes)
  for _, prototype in ipairs(prototypes) do
    assert(prototype.type=="item" or prototype.type=="recipe" or prototype.type=="technology" or prototype.type=="item-subgroup",prototype.type)
    self.raw[prototype.type]=self.raw[prototype.type] or {}
    assert(not self.registered[prototype.type..":"..prototype.name],"Duplicate integration prototype: "..prototype.name)
    self.raw[prototype.type][prototype.name]=prototype
    self.registered[prototype.type..":"..prototype.name]=prototype
  end
end
return fixture

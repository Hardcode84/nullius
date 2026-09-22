local function item(name, entity, hidden, kind)
  data:extend({{type=kind or "item", name=name, hidden=hidden,
    icon="__base__/graphics/icons/iron-chest.png", icon_size=64,
    stack_size=50, place_result=entity}})
end
local function chest(name)
  local entity = table.deepcopy(data.raw.container["iron-chest"])
  entity.name = name
  entity.next_upgrade = nil
  entity.minable = {mining_time=1, result="iron-plate"}
  data:extend({entity})
  return entity
end
local cases = {
  {"plain", true}, {"entity-data", true}, {"alternate", false},
  {"mining-return", false}, {"explicit-visible", false},
  {"explicit-hidden", true}, {"explicit-list", true}, {"explicit-list-visible-first", false},
  {"not-minable", true}, {"results-list", true},
}
for _, case in ipairs(cases) do
  local name = "upgrade-test-" .. case[1]
  local source, target = chest(name), chest(name .. "-target")
  item(name, name, false)
  source.next_upgrade = target.name
  if case[1] == "explicit-visible" then
    item(name .. "-builder", nil, false, "item-with-entity-data")
    target.placeable_by = {item=name .. "-builder", count=1}
  elseif case[1] == "explicit-hidden" then
    item(name .. "-direct", target.name, false)
    item(name .. "-builder", nil, true)
    target.placeable_by = {item=name .. "-builder", count=1}
  elseif case[1] == "explicit-list" or case[1] == "explicit-list-visible-first" then
    item(name .. "-hidden", target.name, true)
    item(name .. "-visible", target.name, false, "item-with-entity-data")
    target.placeable_by = {{item=name .. "-hidden", count=1}, {item=name .. "-visible", count=1}}
    if case[1] == "explicit-list-visible-first" then
      target.placeable_by[1], target.placeable_by[2] = target.placeable_by[2], target.placeable_by[1]
    end
  else
    item(name .. "-builder", target.name, case[2],
      case[1] == "entity-data" and "item-with-entity-data" or "item")
    if case[1] == "alternate" then
      item(name .. "-hidden", target.name, true, "item-with-entity-data")
      target.minable.result = name .. "-hidden"
      data.raw["item-with-entity-data"][name .. "-hidden"].order = "a"
      data.raw.item[name .. "-builder"].order = "z"
    elseif case[1] == "mining-return" then
      item(name .. "-scrap", nil, true)
      target.minable.result = name .. "-scrap"
    elseif case[1] == "not-minable" then
      target.minable = nil
    elseif case[1] == "results-list" then
      target.minable = {mining_time=1, results={{type="item", name="iron-plate", amount=1}}}
    end
  end
end
chest("upgrade-test-no-builder")

-- Execute the actual hidden.lua cleanup after the fixture establishes item visibility.
building_types_list = {"container"}
require("upgrade-cleanup")
for _, case in ipairs(cases) do
  local name = "upgrade-test-" .. case[1]
  local source, target = data.raw.container[name], data.raw.container[name .. "-target"]
  assert((source.next_upgrade == nil) == case[2], name .. " upgrade")
  assert((target.hidden == true) == (case[1] == "mining-return"), name .. " visibility")
  assert(not source.hidden, name .. " source visibility")
end
assert(not data.raw.container["upgrade-test-no-builder"].hidden)

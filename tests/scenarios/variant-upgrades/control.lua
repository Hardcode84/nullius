-- given: all four mode families and an empty upgrade planner.
-- place: each source variant alone on landfill, without build-event side effects.
-- act: apply the native default planner.
-- expect: every link selects the next tier in the same mode; terminal tiers stop.
local CASE = "variant-upgrades"
local RESULT = "factorio-tests/" .. CASE .. ".json"
local SUFFIXES = {"-pneumatic", "-thermal", "-overcharged", "-supercapacitor"}

local assertions = 0
local failures = {}
local observations = {chains = {}}

local function check(condition, message)
  assertions = assertions + 1
  if not condition then failures[#failures + 1] = message end
end

local function ends_with(value, suffix)
  return string.sub(value, -#suffix) == suffix
end

local function finish()
  local result = {
    schema = 1,
    case = CASE,
    status = (#failures == 0) and "pass" or "fail",
    factorio_version = script.active_mods.base,
    tick = game.tick,
    assertions = assertions,
    failure_count = #failures,
    failures = failures,
    observations = observations,
  }
  helpers.write_file(RESULT, helpers.table_to_json(result), false)
  if #failures > 0 then error(helpers.table_to_json(result)) end
end

local function setup()
  script.on_nth_tick(1, nil)

  local surface = game.surfaces.nauvis
  surface.request_to_generate_chunks({0, 0}, 1)
  surface.force_generate_chunk_requests()
  for _, entity in pairs(surface.find_entities_filtered{area={{-10,-10},{10,10}}}) do entity.destroy() end
  local tiles = {}
  for x=-10,10 do for y=-10,10 do tiles[#tiles+1]={name="landfill",position={x,y}} end end
  surface.set_tiles(tiles, true)
  local inventory = game.create_inventory(1)
  inventory[1].set_stack{name="upgrade-planner"}

  for _, suffix in ipairs(SUFFIXES) do
    local variants = 0
    local upgrades = 0
    for name, variant in pairs(prototypes.entity) do
      if ends_with(name, suffix) then
        variants = variants + 1
        local base_name = string.sub(name, 1, #name - #suffix)
        local base = prototypes.entity[base_name]
        check(base ~= nil, name .. " has no base entity")
        if base then
          local base_target = base.next_upgrade
          local expected = base_target and
            prototypes.entity[base_target.name .. suffix] or nil
          if base_target then
            check(expected ~= nil, name .. " has no corresponding variant for " ..
              base_target.name)
          end
          if base_target and expected then
            upgrades = upgrades + 1
            local entity = assert(surface.create_entity{name=name, position={0,0}, force="player"})
            surface.upgrade_area{area={{-8,-8},{8,8}}, force="player", item=inventory[1]}
            local target = entity.get_upgrade_target()
            check(target and target.name == expected.name, name .. " skipped by default upgrade planner")
            entity.destroy()
            check(variant.next_upgrade ~= nil, name .. " has no next upgrade")
            if variant.next_upgrade then
              check(variant.next_upgrade.name == expected.name,
                name .. " upgrades to " .. variant.next_upgrade.name ..
                " instead of " .. expected.name)
              check(variant.fast_replaceable_group ==
                  variant.next_upgrade.fast_replaceable_group,
                name .. " and its upgrade target have different fast-replace groups")
            end
          else
            check(variant.next_upgrade == nil,
              name .. " has an upgrade despite a terminal base entity")
          end
        end
      end
    end
    check(variants > 0, "no variants found for " .. suffix)
    check(upgrades > 0, "no upgrade chains found for " .. suffix)
    observations.chains[suffix] = {
      variants = variants,
      upgrades = upgrades,
    }
  end

  inventory.destroy()
  finish()
end

script.on_nth_tick(1, setup)

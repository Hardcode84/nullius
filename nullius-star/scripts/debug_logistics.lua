local logistics = require("scripts.personal_logistics")
local debug_logistics = {}
local COMMAND = "nullius-debug-logistics"

function debug_logistics.check(player)
  local enabled = storage.nullius_debug_logistics
  if not enabled or not enabled[player.index] then return end
  if not player.admin then enabled[player.index] = nil return end
  local point = logistics.requester(player)
  if not point then return end
  local character = player.character
  character.get_inventory(defines.inventory.character_trash).clear()
  local inventory = character.get_main_inventory()
  for _, filter in ipairs(point.filters or {}) do
    if (filter.type == nil or filter.type == "item") and filter.count > 0 then
      local count = 0
      for _, item in pairs(inventory.get_contents()) do
        if item.name == filter.name and logistics.matches_quality(filter, item.quality) then
          count = count + item.count
        end
      end
      if count < filter.count then
        local quality
        for name, prototype in pairs(prototypes.quality) do
          if logistics.matches_quality(filter, name) and
              (not quality or prototype.level < prototypes.quality[quality].level or
               (prototype.level == prototypes.quality[quality].level and name < quality)) then
            quality = name
          end
        end
        if quality then
          inventory.insert{name=filter.name, quality=quality, count=filter.count-count}
        end
      end
    end
  end
end

function debug_logistics.command(command)
  local player = command.player_index and game.get_player(command.player_index)
  if not player then game.print({"nullius-debug-logistics.player-required"}) return end
  if not player.admin then player.print({"nullius-debug-logistics.admin-required"}) return end
  local parameter = command.parameter
  if parameter and parameter ~= "on" and parameter ~= "off" then
    player.print({"nullius-debug-logistics.usage"}) return
  end
  storage.nullius_debug_logistics = storage.nullius_debug_logistics or {}
  local states = storage.nullius_debug_logistics
  local enabled = parameter == "on" or (parameter == nil and not states[player.index])
  if enabled then
    if not game.console_command_used then
      player.print({"nullius-debug-logistics.achievements"}) return
    end
    if not player.character then player.print({"nullius-debug-logistics.character-required"}) return end
    player.force.character_logistic_requests = true
    local trash = player.character.get_inventory(defines.inventory.character_trash)
    if #trash == 0 then
      player.character_trash_slot_count_bonus = player.character_trash_slot_count_bonus + 1
    end
    player.character.get_requester_point().enabled = true
  end
  states[player.index] = enabled or nil
  debug_logistics.check(player)
  player.print({enabled and "nullius-debug-logistics.enabled" or "nullius-debug-logistics.disabled"})
end

function debug_logistics.remove_player(index)
  if storage.nullius_debug_logistics then storage.nullius_debug_logistics[index] = nil end
end

commands.add_command(COMMAND, {"nullius-debug-logistics.help"}, debug_logistics.command)
return debug_logistics

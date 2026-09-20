local autocraft = {}
local NAME = "nullius-autocraft"
local recipes_by_item

local function state(player)
  storage.nullius_autocraft = storage.nullius_autocraft or {}
  local states = storage.nullius_autocraft
  states[player.index] = states[player.index] or {enabled = false}
  return states[player.index]
end

local function requester(player)
  if not player.connected or not player.character or
      not player.force.character_logistic_requests then return nil end
  local point = player.character.get_requester_point()
  if point and point.enabled then return point end
end

local function refresh_gui(player)
  local available = requester(player) ~= nil
  local settings = state(player)
  local frame = player.gui.top[NAME]
  if not available then
    settings.enabled = false
    if frame then frame.visible = false end
    player.set_shortcut_available(NAME, false)
    player.set_shortcut_toggled(NAME, false)
    return
  end
  if not frame then
    frame = player.gui.top.add{type = "frame", name = NAME, direction = "horizontal"}
    frame.add{type = "checkbox", name = NAME, state = false,
      caption = {"gui.nullius-autocraft"}, tooltip = {"gui.nullius-autocraft-description"}}
  end
  frame.visible = true
  frame[NAME].enabled = available
  frame[NAME].state = settings.enabled
  player.set_shortcut_available(NAME, available)
  player.set_shortcut_toggled(NAME, settings.enabled)
end

local function matches_quality(filter, quality)
  if not filter.quality then return true end
  local actual = prototypes.quality[quality].level
  local wanted = prototypes.quality[filter.quality].level
  local comparison = filter.comparator or "="
  if comparison == "=" then return actual == wanted end
  if comparison == ">" then return actual > wanted end
  if comparison == "<" then return actual < wanted end
  if comparison == "≥" or comparison == ">=" then return actual >= wanted end
  if comparison == "≤" or comparison == "<=" then return actual <= wanted end
  if comparison == "≠" or comparison == "!=" then return actual ~= wanted end
  error("Unexpected logistic quality comparator: " .. comparison)
end

-- Cold path: index final products only. Factorio resolves all intermediates.
local function recipe_index()
  if recipes_by_item then return recipes_by_item end
  recipes_by_item = {}
  for name, recipe in pairs(prototypes.recipe) do
    for _, product in pairs(recipe.products) do
      if product.type == "item" then
        local list = recipes_by_item[product.name] or {}
        list[#list + 1] = name
        recipes_by_item[product.name] = list
      end
    end
  end
  for _, list in pairs(recipes_by_item) do table.sort(list) end
  return recipes_by_item
end

function autocraft.check(player)
  refresh_gui(player)
  local settings = state(player)
  if not settings.enabled then return end
  -- Use one physical body for requests, inventory, and native crafting,
  -- including while the player's active controller is remote view.
  local character = player.character
  if character.crafting_queue_size ~= 0 then return end
  local point = requester(player)
  local contents = character.get_main_inventory().get_contents()
  for _, filter in ipairs(point.filters or {}) do
    if (filter.type == nil or filter.type == "item") and
        filter.count > 0 and matches_quality(filter, "normal") then
      local count = 0
      for _, item in pairs(contents) do
        if item.name == filter.name and matches_quality(filter, item.quality) then
          count = count + item.count
        end
      end
      if count < filter.count then
        for _, name in ipairs(recipe_index()[filter.name] or {}) do
          local recipe = player.force.recipes[name]
          if recipe.enabled and not recipe.hidden and
              not player.force.get_hand_crafting_disabled_for_recipe(name) and
              character.get_craftable_count(name) > 0 then
            if character.begin_crafting{recipe = name, count = 1, silent = true} > 0 then
              return
            end
          end
        end
      end
    end
  end
end

function autocraft.toggle(player, enabled)
  if not requester(player) then return end
  state(player).enabled = requester(player) ~= nil and enabled
  refresh_gui(player)
end

function autocraft.on_shortcut(event)
  if event.prototype_name ~= NAME then return end
  local player = game.get_player(event.player_index)
  if not requester(player) then return end
  autocraft.toggle(player, not state(player).enabled)
end

function autocraft.on_checkbox(event)
  if event.element.valid and event.element.name == NAME then
    autocraft.toggle(game.get_player(event.player_index), event.element.state)
  end
end

function autocraft.on_crafted(event)
  -- Completion fires before the output enters inventory. Check next tick.
  local player = game.get_player(event.player_index)
  if state(player).enabled then
    storage.nullius_autocraft_pending = true
  end
end

local function check_all()
  for _, player in pairs(game.connected_players) do autocraft.check(player) end
end

function autocraft.update_tick()
  if not storage.nullius_autocraft_pending then return end
  storage.nullius_autocraft_pending = nil
  check_all()
end

script.on_nth_tick(30, check_all)
script.on_event(defines.events.on_gui_checked_state_changed, autocraft.on_checkbox)
script.on_event(defines.events.on_player_cancelled_crafting, function(event)
  autocraft.toggle(game.get_player(event.player_index), false)
end)
function autocraft.remove_player(index)
  if storage.nullius_autocraft then storage.nullius_autocraft[index] = nil end
end

if script.active_mods["factorio-test-support"] then
  remote.add_interface("nullius-test-autocraft", {
    shortcut = autocraft.on_shortcut,
    checkbox = autocraft.on_checkbox,
  })
end

return autocraft

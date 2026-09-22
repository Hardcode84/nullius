-- given: loaded production prototypes; no recipes, resources, or power inputs
-- place: each Nullius building in four cardinal directions, including helpers
-- connect: separate display cells; no production networks
-- act: inspect idle graphics in permanent daylight; select a row to teleport
-- expect: every requested entity exists and keeps its initial native direction
local CASE = "building-gallery"
local directions = {defines.direction.north, defines.direction.east,
  defines.direction.south, defines.direction.west}
local labels = {"N", "E", "S", "W"}

local function label(surface, text, position, scale)
  rendering.draw_text{surface=surface, text=text, target=position,
    color={1, 1, 1}, scale=scale or 1, alignment="center",
    font="default-bold", scale_with_zoom=true}
end

local function names()
  local selected = {}
  for name, prototype in pairs(prototypes.entity) do
    if prototype.is_building and name:match("^nullius%-") then selected[name] = true end
  end
  -- Some Nullius items place base-game entities with unchanged internal names.
  for name, item in pairs(prototypes.item) do
    local entity = item.place_result
    if name:match("^nullius%-") and entity and entity.is_building then
      selected[entity.name] = true
    end
  end
  for name, recipe in pairs(prototypes.recipe) do
    if name:match("^nullius%-") then
      for _, product in pairs(recipe.products) do
        if product.type=="item" then
          local entity=prototypes.item[product.name].place_result
          if entity and entity.is_building then selected[entity.name]=true end
        end
      end
    end
  end
  local result = {}
  for name in pairs(selected) do result[#result+1] = name end
  table.sort(result)
  return result
end

script.on_init(function()
  storage.rows = {}
  storage.samples = {}
  local x, y, line_height = 16, 20, 0
  for _, name in ipairs(names()) do
    local prototype = prototypes.entity[name]
    local box = prototype.selection_box
    local collision = prototype.collision_box
    local size = math.ceil(math.max(box.right_bottom.x-box.left_top.x,
      box.right_bottom.y-box.left_top.y, collision.right_bottom.x-collision.left_top.x,
      collision.right_bottom.y-collision.left_top.y)) + 4
    size = math.max(size, 6)
    local width, height = math.max(size*4, 32), size+12
    if x+width > 512 then x=16; y=y+line_height; line_height=0 end
    storage.rows[#storage.rows+1] = {name=name, x=x, y=y, size=size,
      width=width, height=height, position={x+width/2,y+height/2}}
    x=x+width+8
    line_height=math.max(line_height,height)
  end
  assert(#storage.rows > 0, "No Nullius buildings selected")
  local surface = game.create_surface(CASE, {
    autoplace_controls={}, autoplace_settings={
      entity={treat_missing_as_default=false}, decorative={treat_missing_as_default=false}},
    width=0, height=0,
  })
  surface.freeze_daytime=true
  surface.daytime=0
  storage.surface=surface
  for _, row in ipairs(storage.rows) do
    surface.request_to_generate_chunks(row.position, math.ceil(row.width/64))
  end
  surface.force_generate_chunk_requests()
  for _, row in ipairs(storage.rows) do
    local tiles={}
    for tx=row.x-2,row.x+row.width+2 do
      for ty=row.y-2,row.y+row.height do
        tiles[#tiles+1]={name="refined-concrete",position={tx,ty}}
      end
    end
    surface.set_tiles(tiles, true)
    label(surface, row.name, {row.x+row.width/2,row.y}, 0.8)
    for index, direction in ipairs(directions) do
      local position={row.x+(index-0.5)*row.width/4, row.y+8+row.size/2}
      local entity=assert(surface.create_entity{name=row.name,position=position,
        direction=direction, force=game.forces.player, raise_built=false},
        "Cannot place " .. row.name .. " " .. labels[index])
      entity.destructible=false
      entity.minable_flag=false
      entity.disabled_by_script=true
      local actual=entity.direction
      local caption=labels[index]
      if actual~=direction then caption=caption .. " (" .. (labels[actual/4+1] or tostring(actual)) .. ")" end
      label(surface, caption, {position[1],row.y+4}, 0.8)
      storage.samples[#storage.samples+1]={entity=entity,direction=actual,name=row.name}
    end
  end
  game.forces.player.chart(surface,{{0,0},{560,y+line_height+16}})
end)

local function visit(player, index)
  local row=storage.rows[index]
  assert(player.teleport(row.position, storage.surface), "Gallery teleport failed")
  player.zoom=math.min(0.8, player.display_resolution.width*0.65/((row.width+12)*32),
    player.display_resolution.height*0.65/((row.height+12)*32))
end

local function open_gallery(event)
  local player=game.get_player(event.player_index)
  player.set_controller{type=defines.controllers.god}
  player.cheat_mode=true
  local old=player.gui.top.building_gallery
  if old then old.destroy() end
  local frame=player.gui.top.add{type="frame", name="building_gallery", direction="horizontal"}
  frame.add{type="label",caption="Buildings"}
  frame.add{type="button",name="gallery_previous",caption="<"}.style.width=28
  local items={}
  for _,row in ipairs(storage.rows) do items[#items+1]=row.name end
  local selector=frame.add{type="drop-down",name="gallery_select",items=items,selected_index=1}
  selector.style.width=260
  frame.add{type="button",name="gallery_next",caption=">"}.style.width=28
  visit(player,1)
  player.print(#storage.rows .. " building types, " .. #storage.samples ..
    " displays. N/E/S/W labels show requested rotations; native direction notes show engine normalization.")
end
local function queue_player(event)
  storage.pending_players=storage.pending_players or {}
  storage.pending_players[event.player_index]=true
  script.on_nth_tick(60,function()
    if game.tick==0 then return end
    script.on_nth_tick(60,nil)
    for index in pairs(storage.pending_players) do
      open_gallery{player_index=index}
    end
    storage.pending_players={}
  end)
end
script.on_event(defines.events.on_player_created, queue_player)
script.on_event(defines.events.on_player_joined_game, queue_player)
script.on_event(defines.events.on_gui_selection_state_changed,function(event)
  if event.element.name=="gallery_select" then
    visit(game.get_player(event.player_index),event.element.selected_index)
  end
end)
script.on_event(defines.events.on_gui_click,function(event)
  local name=event.element.name
  if name~="gallery_previous" and name~="gallery_next" then return end
  local player=game.get_player(event.player_index)
  local selector=player.gui.top.building_gallery.gallery_select
  local delta=name=="gallery_next" and 1 or -1
  selector.selected_index=(selector.selected_index-1+delta)%#storage.rows+1
  visit(player,selector.selected_index)
end)

script.on_nth_tick(5,function()
  if game.tick==0 then return end
  script.on_nth_tick(5,nil)
  local normalized=0
  for index,sample in ipairs(storage.samples) do
    assert(sample.entity.valid, "Gallery entity removed: " .. sample.name)
    assert(sample.entity.direction==sample.direction, "Gallery direction changed: " .. sample.name)
    if sample.direction~=directions[(index-1)%4+1] then normalized=normalized+1 end
  end
  helpers.write_file("factorio-tests/" .. CASE .. ".json",helpers.table_to_json{
    schema=1,case=CASE,status="pass",failure_count=0,failures={},tick=game.tick,
    assertions=#storage.samples*2, buildings=#storage.rows, placements=#storage.samples,
    normalized_directions=normalized,factorio_version=script.active_mods.base,
  },false)
end)

for _,prefix in ipairs({"nullius-well-", "nullius-legacy-well-"}) do
  for tier=1,2 do
    local name=prefix .. tier
    data:extend({{type="item",name=name,stack_size=50,place_result=name,
      icons={{icon="__base__/graphics/icons/pumpjack.png",icon_size=64}}}})
  end
end
require("well-prototypes")
local modern = require("factorio-version").is_2_1
for _,prefix in ipairs({"nullius-well-", "nullius-legacy-well-"}) do
  for tier=1,2 do
    local well = data.raw["assembling-machine"][prefix .. tier]
    for i,direction in ipairs({"north","east","south","west"}) do
      local layers = well.graphics_set.animation[direction].layers
      assert(#layers==4,"all animation layers retained")
      local base,shadow,drill,arm = table.unpack(layers)
      assert(base.width==261 and base.height==273 and (base.x or 0)==(i-1)*261,"base frame")
      assert(base.shift[1]==-2.25/32 and base.shift[2]==-4.75/32,"base placement")
      local width,height=modern and 261 or 220,modern and 273 or 220
      assert(shadow.width==width and shadow.height==height,"shadow dimensions")
      assert((shadow.x or 0)==(i-1)*width and (shadow.y or 0)==0,"shadow direction")
      assert(shadow.filename=="__base__/graphics/entity/pumpjack/pumpjack-base-shadow.png","shadow sheet")
      assert(shadow.shift[1]==(modern and -2 or 6)/32 and shadow.shift[2]==(modern and -5 or 0.5)/32,"shadow origin")
      assert(shadow.scale==0.5 and shadow.draw_as_shadow,"shadow rendering")
      assert(shadow.repeat_count==40 and shadow.animation_speed==(tier==1 and 0.4 or 0.6),"shadow timing")
      assert(drill.frame_count==40 and arm.frame_count==40,"moving frames")
      assert(drill.scale==0.5 and arm.scale==0.5,"moving scale")
    end
  end
end

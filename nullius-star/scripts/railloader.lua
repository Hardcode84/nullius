local function parse_version(version)
  if version == nil then return nil end
  local major, minor, patch = string.match(version, "^(%d+)%.(%d+)%.(%d+)$")
  if not major then return nil end
  return (((tonumber(major) * 100) + tonumber(minor)) * 100) + tonumber(patch)
end

local bulk_items = {
  "iron-oxide", "cellulose", "sand", "limestone", "lime", "gypsum",
  "silica", "gravel", "alumina", "sodium-hydroxide", "calcium-chloride",
  "sodium-sulfate", "lithium-chloride", "salt", "crushed-bauxite",
  "crushed-iron-ore", "crushed-limestone", "mineral-dust", "sandstone",
  "bauxite", "rutile", "aluminum-hydroxide", "aluminum-carbide", "graphite",
  "plastic", "rubber", "fertilizer", "land-fill-gravel", "land-fill-sand",
  "land-fill-bauxite", "land-fill-iron", "land-fill-limestone", "acid-boric",
}

function update_railloader_bulk()
  local version = parse_version(script.active_mods.railloader)
  if version == nil or version < 10106 then return end
  if remote.interfaces.railloader == nil then return end

  for _, item in pairs(bulk_items) do
    remote.call("railloader", "add_bulk_item", "nullius-" .. item)
  end
  for _, item in pairs(bulk_items) do
    remote.call("railloader", "add_bulk_item", "nullius-box-" .. item)
  end
  remote.call("railloader", "add_bulk_item", "nullius-box-iron-ore")
  remote.call("railloader", "add_bulk_item", "nullius-box-copper-ore")
end
